import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'secure_file.dart';

/// A URL the user wants to keep for later. Stores the whole pasted text so a
/// saved batch keeps all of its links, not just the first one.
class SavedLink {
  const SavedLink({
    required this.id,
    required this.text,
    required this.dateMs,
  });

  factory SavedLink.fromJson(Map<String, dynamic> json) {
    return SavedLink(
      id: json['id'] as String? ?? '',
      text: json['text'] as String? ?? '',
      dateMs: (json['dateMs'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final String text;
  final int dateMs;

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'dateMs': dateMs,
      };
}

/// Persisted list of links saved from the Home screen. Kept separate from
/// history: a saved link has not been downloaded yet.
class SavedLinkStore extends ChangeNotifier {
  SavedLinkStore._(this._entries, this._file);

  static const int maxEntries = 100;

  List<SavedLink> _entries;
  final File _file;

  List<SavedLink> get entries => List.unmodifiable(_entries);

  static Future<SavedLinkStore> load() async {
    final support = await getApplicationSupportDirectory();
    final file = File('${support.path}${Platform.pathSeparator}saved_links.json');
    List<SavedLink> entries = [];
    try {
      if (await file.exists()) {
        final decoded = jsonDecode(await file.readAsString());
        if (decoded is List) {
          entries = decoded
              .whereType<Map<String, dynamic>>()
              .map((item) {
                try {
                  return SavedLink.fromJson(item);
                } catch (_) {
                  return null;
                }
              })
              .whereType<SavedLink>()
              .where((link) => link.id.isNotEmpty && link.text.isNotEmpty)
              .toList();
          entries.sort((a, b) => b.dateMs.compareTo(a.dateMs));
        }
      }
    } catch (_) {
      entries = [];
    }
    return SavedLinkStore._(entries, file);
  }

  bool contains(String text) => _entries.any((link) => link.text.trim() == text.trim());

  Future<void> add(String text) async {
    final value = text.trim();
    if (value.isEmpty || contains(value)) return;
    _entries.insert(0, SavedLink(
      id: DateTime.now().microsecondsSinceEpoch.toRadixString(16),
      text: value,
      dateMs: DateTime.now().millisecondsSinceEpoch,
    ));
    if (_entries.length > maxEntries) {
      _entries = _entries.sublist(0, maxEntries);
    }
    notifyListeners();
    await _persist();
  }

  /// Adds several links at once, skipping invalid and duplicate rows. The
  /// store cap is enforced so a pasted list cannot grow without bound.
  Future<int> addMany(Iterable<String> texts) async {
    var added = 0;
    for (final text in texts) {
      final value = text.trim();
      if (value.isEmpty || contains(value)) continue;
      _entries.insert(
        0,
        SavedLink(
          id: DateTime.now().microsecondsSinceEpoch.toRadixString(16) + added.toString(),
          text: value,
          dateMs: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      added++;
    }
    if (added == 0) return 0;
    if (_entries.length > maxEntries) {
      _entries = _entries.sublist(0, maxEntries);
    }
    notifyListeners();
    await _persist();
    return added;
  }

  Future<void> update(String id, String text) async {
    final value = text.trim();
    if (value.isEmpty) return;
    final index = _entries.indexWhere((link) => link.id == id);
    if (index < 0) return;
    // Keep the id and original date. A duplicate of another saved row is not
    // created here, so editing preserves the user's list order.
    _entries[index] = SavedLink(
      id: id,
      text: value,
      dateMs: _entries[index].dateMs,
    );
    notifyListeners();
    await _persist();
  }

  Future<void> remove(String id) async {
    _entries.removeWhere((link) => link.id == id);
    notifyListeners();
    await _persist();
  }

  Future<void> clear() async {
    _entries.clear();
    notifyListeners();
    await _persist();
  }

  Future<void> replaceAll(Iterable<SavedLink> entries) async {
    _entries = entries
        .where((link) => link.id.isNotEmpty && link.text.isNotEmpty)
        .toList();
    if (_entries.length > maxEntries) {
      _entries = _entries.sublist(0, maxEntries);
    }
    _entries.sort((a, b) => b.dateMs.compareTo(a.dateMs));
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    try {
      await _file.parent.create(recursive: true);
      await writeFileAtomic(_file, jsonEncode([for (final link in _entries) link.toJson()]));
      await restrictFileToOwner(_file);
    } catch (_) {
      // Non-fatal: the list just will not survive a restart.
    }
  }
}
