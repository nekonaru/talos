import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

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
  });

  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    return HistoryEntry(
      id: json['id'] as String,
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
    );
  }

  final String id;
  final String title;
  final String url;
  final String filePath;
  final HistoryKind kind;
  final int dateMs;
  final String? uploader;
  final int? sizeBytes;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'url': url,
        'filePath': filePath,
        'kind': kind.name,
        'dateMs': dateMs,
        'uploader': uploader,
        'sizeBytes': sizeBytes,
      };
}

/// Append-only style log of finished downloads, newest first.
class HistoryStore extends ChangeNotifier {
  HistoryStore._(this._entries, this._file);

  static const int _maxEntries = 300;

  List<HistoryEntry> _entries;
  final File _file;

  List<HistoryEntry> get entries => List.unmodifiable(_entries);

  static Future<HistoryStore> load() async {
    final support = await getApplicationSupportDirectory();
    final file = File('${support.path}${Platform.pathSeparator}history.json');
    List<HistoryEntry> entries = [];
    try {
      if (await file.exists()) {
        final decoded = jsonDecode(await file.readAsString());
        if (decoded is List) {
          entries = [
            for (final item in decoded)
              if (item is Map<String, dynamic>) HistoryEntry.fromJson(item),
          ];
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
    notifyListeners();
    await _persist();
  }

  Future<void> remove(String id) async {
    _entries.removeWhere((e) => e.id == id);
    notifyListeners();
    await _persist();
  }

  Future<void> clear() async {
    _entries.clear();
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    try {
      await _file.parent.create(recursive: true);
      await _file.writeAsString(
        const JsonEncoder.withIndent('  ').convert([for (final e in _entries) e.toJson()]),
      );
    } catch (_) {
      // Non-fatal: history just will not survive a restart.
    }
  }
}
