import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'secure_file.dart';

enum HistoryKind { video, audio }

class HistoryEntry {
  HistoryEntry({
    required this.id,
    required this.title,
    required this.url,
    required this.filePath,
    required this.kind,
    required this.dateMs,
    this.uploader,
    this.sizeBytes,
    this.thumbnailUrl,
    this.favorite = false,
  });

  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! String) throw const FormatException('History entry is missing an id');
    return HistoryEntry(
      id: id,
      title: json['title'] as String? ?? 'Unknown title',
      url: json['url'] as String? ?? '',
      filePath: json['filePath'] as String? ?? '',
      kind: HistoryKind.values.firstWhere(
        (k) => k.name == json['kind'],
        orElse: () => HistoryKind.video,
      ),
      dateMs: (json['dateMs'] as num?)?.toInt() ?? 0,
      uploader: json['uploader'] as String?,
      sizeBytes: (json['sizeBytes'] as num?)?.toInt(),
      thumbnailUrl: json['thumbnailUrl'] as String?,
      favorite: (json['favorite'] as bool?) ?? false,
    );
  }

  final String id;
  final String title;
  final String url;
  String filePath;
  final HistoryKind kind;
  final int dateMs;
  final String? uploader;
  final int? sizeBytes;
  final String? thumbnailUrl;
  bool favorite;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'url': url,
        'filePath': filePath,
        'kind': kind.name,
        'dateMs': dateMs,
        'uploader': uploader,
        'sizeBytes': sizeBytes,
        'thumbnailUrl': thumbnailUrl,
        'favorite': favorite,
      };

  /// Decodes one entry, returning null for a malformed record. Used when
  /// loading so a single bad row cannot discard the rest of the history.
  static HistoryEntry? tryFromJson(Map<String, dynamic> json) {
    try {
      return HistoryEntry.fromJson(json);
    } catch (_) {
      return null;
    }
  }
}

/// Groups finished downloads by their parent folder and sums size and count.
/// Sorted by total size descending.
List<({String folder, int count, int bytes})> folderBreakdown(
  Iterable<HistoryEntry> entries,
) {
  final groups = <String, ({int count, int bytes})>{};
  for (final entry in entries) {
    final separator = math.max(
      entry.filePath.lastIndexOf(Platform.pathSeparator),
      entry.filePath.lastIndexOf('/'),
    );
    final folder = separator > 0
        ? entry.filePath.substring(0, separator)
        : entry.filePath;
    final current = groups[folder] ?? (count: 0, bytes: 0);
    groups[folder] = (
      count: current.count + 1,
      bytes: current.bytes + (entry.sizeBytes ?? 0),
    );
  }
  final result = [
    for (final MapEntry(key: folder, value: stats) in groups.entries)
      (folder: folder, count: stats.count, bytes: stats.bytes),
  ];
  result.sort((a, b) => b.bytes.compareTo(a.bytes));
  return result;
}

/// Returns older rows that share a URL, or a title when no URL is stored.
/// The newest row of each group is kept.
List<HistoryEntry> duplicateHistoryEntries(Iterable<HistoryEntry> entries) {
  final sorted = entries.toList()
    ..sort((a, b) => b.dateMs.compareTo(a.dateMs));
  final seen = <String>{};
  final duplicates = <HistoryEntry>[];
  for (final entry in sorted) {
    final key = entry.url.isNotEmpty
        ? 'url:${entry.url}'
        : 'title:${entry.title.toLowerCase()}';
    if (!seen.add(key)) duplicates.add(entry);
  }
  return duplicates;
}

/// Returns a new list of [entries] ordered by [sort].
///
/// Supported values: newest, oldest, largest, smallest, title. Unknown values
/// fall back to newest first. Entries without a size are treated as zero.
List<HistoryEntry> sortedHistory(Iterable<HistoryEntry> entries, String sort) {
  final list = entries.toList();
  switch (sort) {
    case 'oldest':
      list.sort((a, b) => a.dateMs.compareTo(b.dateMs));
    case 'largest':
      list.sort((a, b) => (b.sizeBytes ?? 0).compareTo(a.sizeBytes ?? 0));
    case 'smallest':
      list.sort((a, b) => (a.sizeBytes ?? 0).compareTo(b.sizeBytes ?? 0));
    case 'title':
      list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    case 'newest':
    default:
      list.sort((a, b) => b.dateMs.compareTo(a.dateMs));
  }
  return list;
}

/// Append-only style log of finished downloads, newest first.
class HistoryStore extends ChangeNotifier {
  HistoryStore._(this._entries, this._file);

  static const int _maxEntries = 300;

  List<HistoryEntry> _entries;
  final File _file;

  /// Bumped on every mutation so screens can cache derived lists cheaply.
  int revision = 0;

  List<HistoryEntry> get entries => List.unmodifiable(_entries);

  static Future<HistoryStore> load() async {
    final support = await getApplicationSupportDirectory();
    final file = File('${support.path}${Platform.pathSeparator}history.json');
    List<HistoryEntry> entries = [];
    try {
      if (await file.exists()) {
        final decoded = jsonDecode(await file.readAsString());
        if (decoded is List) {
          entries = decoded
              .whereType<Map<String, dynamic>>()
              .map(HistoryEntry.tryFromJson)
              .whereType<HistoryEntry>()
              .toList();
          entries.sort((a, b) => b.dateMs.compareTo(a.dateMs));
        }
      }
    } catch (_) {
      entries = [];
    }
    return HistoryStore._(entries, file);
  }

  Future<void> add(HistoryEntry entry) async {
    _entries.insert(0, entry);
    if (_entries.length > _maxEntries) {
      _entries = _entries.sublist(0, _maxEntries);
    }
    revision++;
    notifyListeners();
    await _persist();
  }

  Future<void> toggleFavorite(String id) async {
    for (final entry in _entries) {
      if (entry.id == id) {
        entry.favorite = !entry.favorite;
        break;
      }
    }
    revision++;
    notifyListeners();
    await _persist();
  }

  Future<void> updateFilePath(String id, String path) async {
    for (final entry in _entries) {
      if (entry.id == id) {
        entry.filePath = path;
        break;
      }
    }
    notifyListeners();
    await _persist();
  }

  Future<void> remove(String id) async {
    _entries.removeWhere((e) => e.id == id);
    revision++;
    notifyListeners();
    await _persist();
  }

  /// Removes every entry whose id is in [ids]. Unknown ids are ignored.
  Future<void> removeMany(Iterable<String> ids) async {
    final set = ids.toSet();
    if (set.isEmpty) return;
    _entries.removeWhere((e) => set.contains(e.id));
    revision++;
    notifyListeners();
    await _persist();
  }

  /// Exports the current history as CSV with a header row. Values containing
  /// commas, quotes or newlines are quoted and escaped.
  String exportCsv() {
    String cell(String value) {
      final needsQuotes = value.contains(',') || value.contains('"') ||
          value.contains('\n') || value.contains('\r');
      return needsQuotes ? '"${value.replaceAll('"', '""')}"' : value;
    }

    final buffer = StringBuffer(
      'title,url,kind,filePath,sizeBytes,dateMs,favorite\n',
    );
    for (final entry in _entries) {
      buffer
        ..write(cell(entry.title))
        ..write(',')
        ..write(cell(entry.url))
        ..write(',')
        ..write(cell(entry.kind.name))
        ..write(',')
        ..write(cell(entry.filePath))
        ..write(',')
        ..write(entry.sizeBytes ?? '')
        ..write(',')
        ..write(entry.dateMs)
        ..write(',')
        ..write(entry.favorite ? '1' : '0')
        ..write('\n');
    }
    return buffer.toString();
  }

  /// Drops history rows older than [cutoffMs]. Files on disk are never
  /// deleted here; the user can remove them from Insights explicitly.
  Future<void> pruneBefore(int cutoffMs) async {
    final before = _entries.length;
    _entries.removeWhere((entry) => entry.dateMs > 0 && entry.dateMs < cutoffMs);
    if (_entries.length == before) return;
    revision++;
    notifyListeners();
    await _persist();
  }

  Future<void> clear() async {
    _entries.clear();
    revision++;
    notifyListeners();
    await _persist();
  }

  /// Replaces the whole history in one write. Used by backup restore so a
  /// large library does not trigger one disk write per entry.
  Future<void> replaceAll(Iterable<HistoryEntry> entries) async {
    _entries = entries.toList();
    if (_entries.length > _maxEntries) {
      _entries = _entries.sublist(0, _maxEntries);
    }
    _entries.sort((a, b) => b.dateMs.compareTo(a.dateMs));
    revision++;
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    try {
      await _file.parent.create(recursive: true);
      await writeFileAtomic(_file, const JsonEncoder.withIndent('  ').convert([for (final e in _entries) e.toJson()]));
      await restrictFileToOwner(_file);
    } catch (_) {
      // Non-fatal: history just will not survive a restart.
    }
  }
}
