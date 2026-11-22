import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'secure_file.dart';

/// A reusable set of download options. Deliberately limited to the choices
/// exposed on the Configure screen; folder, proxy and archive stay global in
/// Settings so a preset cannot silently override them.
class DownloadPreset {
  const DownloadPreset({
    required this.id,
    required this.name,
    required this.videoMode,
    required this.maxHeight,
    required this.audioFormat,
    required this.audioBitrate,
    required this.embedSubtitles,
    required this.embedMetadata,
    this.formatSelector,
  });

  factory DownloadPreset.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String?;
    if (name == null || name.trim().isEmpty) throw const FormatException('preset name');
    return DownloadPreset(
      id: json['id'] as String? ?? '',
      name: name,
      videoMode: (json['videoMode'] as bool?) ?? true,
      maxHeight: (json['maxHeight'] as num?)?.toInt() ?? 720,
      audioFormat: json['audioFormat'] as String? ?? 'mp3',
      audioBitrate: json['audioBitrate'] as String? ?? '192',
      embedSubtitles: (json['embedSubtitles'] as bool?) ?? true,
      embedMetadata: (json['embedMetadata'] as bool?) ?? true,
      formatSelector: json['formatSelector'] as String?,
    );
  }

  final String id;
  final String name;
  final bool videoMode;
  final int maxHeight;
  final String audioFormat;
  final String audioBitrate;
  final bool embedSubtitles;
  final bool embedMetadata;
  final String? formatSelector;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'videoMode': videoMode,
        'maxHeight': maxHeight,
        'audioFormat': audioFormat,
        'audioBitrate': audioBitrate,
        'embedSubtitles': embedSubtitles,
        'embedMetadata': embedMetadata,
        'formatSelector': formatSelector,
      };
}

/// Persisted list of named Configure presets.
class PresetStore extends ChangeNotifier {
  PresetStore._(this._entries, this._file);

  static const int maxEntries = 30;

  List<DownloadPreset> _entries;
  final File _file;

  List<DownloadPreset> get entries => List.unmodifiable(_entries);

  static Future<PresetStore> load() async {
    final support = await getApplicationSupportDirectory();
    final file = File('${support.path}${Platform.pathSeparator}presets.json');
    List<DownloadPreset> entries = [];
    try {
      if (await file.exists()) {
        final decoded = jsonDecode(await file.readAsString());
        if (decoded is List) {
          entries = decoded
              .whereType<Map<String, dynamic>>()
              .map((item) {
                try {
                  return DownloadPreset.fromJson(item);
                } catch (_) {
                  return null;
                }
              })
              .whereType<DownloadPreset>()
              .where((preset) => preset.id.isNotEmpty)
              .toList();
          entries.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        }
      }
    } catch (_) {
      entries = [];
    }
    return PresetStore._(entries, file);
  }

  Future<void> add(DownloadPreset preset) async {
    _entries
      ..removeWhere((item) => item.name.toLowerCase() == preset.name.toLowerCase())
      ..add(preset);
    _entries.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    if (_entries.length > maxEntries) {
      _entries = _entries.sublist(0, maxEntries);
    }
    notifyListeners();
    await _persist();
  }

  Future<void> remove(String id) async {
    _entries.removeWhere((preset) => preset.id == id);
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
      await writeFileAtomic(_file, jsonEncode([for (final preset in _entries) preset.toJson()]));
      await restrictFileToOwner(_file);
    } catch (_) {
      // Non-fatal: presets just will not survive a restart.
    }
  }
}
