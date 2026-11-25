import 'dart:convert';

import 'command_template_store.dart';
import 'download_manager.dart';
import 'history_store.dart';
import 'preset_store.dart';
import 'queue_store.dart';
import 'saved_link_store.dart';
import 'settings_store.dart';

/// Portable backup of everything Talos stores locally except the downloaded
/// files themselves. The payload is plain JSON so it can be shared, copied or
/// kept by any file manager without a proprietary format.
class TalosBackup {
  static const String format = 'talos-backup';
  static const int version = 1;

  static Future<String> exportJson(DownloadManager manager) async {
    final commands = await CommandTemplateStore.load();
    final queue = await QueueStore.load();
    final data = <String, dynamic>{
      'format': format,
      'version': version,
      'exportedAt': DateTime.now().toIso8601String(),
      'settings': manager.settings.value.toJson(),
      'history': [for (final entry in manager.history.entries) entry.toJson()],
      'savedLinks': [for (final link in manager.savedLinks.entries) link.toJson()],
      'presets': [for (final preset in manager.presets.entries) preset.toJson()],
      'commands': [for (final command in commands.templates) command.toJson()],
      'queue': [for (final item in queue) item.toJson()],
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Restores every section that is present. Unknown or malformed rows are
  /// skipped instead of discarding the whole backup.
  static Future<void> restoreJson(DownloadManager manager, String raw) async {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Not a Talos backup');
    }
    if (decoded['format'] != format) {
      throw const FormatException('Not a Talos backup');
    }
    final incomingVersion = decoded['version'];
    if (incomingVersion is int && incomingVersion > version) {
      throw const FormatException('Backup was made by a newer version of Talos');
    }

    final settings = decoded['settings'];
    if (settings is Map<String, dynamic>) {
      await manager.settings.update(TalosSettings.fromJson(settings));
    }

    final history = decoded['history'];
    if (history is List) {
      final entries = <HistoryEntry>[];
      for (final item in history) {
        if (item is! Map<String, dynamic>) continue;
        final entry = HistoryEntry.tryFromJson(item);
        if (entry != null) entries.add(entry);
      }
      await manager.history.replaceAll(entries);
    }

    final links = decoded['savedLinks'];
    if (links is List) {
      final entries = <SavedLink>[];
      for (final item in links) {
        if (item is! Map<String, dynamic>) continue;
        try {
          entries.add(SavedLink.fromJson(item));
        } catch (_) {
          // Skip one bad row, keep the rest of the backup.
        }
      }
      await manager.savedLinks.replaceAll(entries);
    }

    final presets = decoded['presets'];
    if (presets is List) {
      final entries = <DownloadPreset>[];
      for (final item in presets) {
        if (item is! Map<String, dynamic>) continue;
        try {
          entries.add(DownloadPreset.fromJson(item));
        } catch (_) {
          // Skip one bad row, keep the rest of the backup.
        }
      }
      await manager.presets.replaceAll(entries);
    }

    final commands = decoded['commands'];
    if (commands is List) {
      final entries = <CommandTemplate>[];
      for (final item in commands) {
        if (item is! Map<String, dynamic>) continue;
        try {
          entries.add(CommandTemplate.fromJson(item));
        } catch (_) {
          // Skip one bad row, keep the rest of the backup.
        }
      }
      await CommandTemplateStore.replaceAll(entries);
    }

    final queue = decoded['queue'];
    if (queue is List) {
      final entries = <QueuedDownload>[];
      for (final item in queue) {
        if (item is! Map<String, dynamic>) continue;
        try {
          entries.add(QueuedDownload.fromJson(item));
        } catch (_) {
          // Skip one bad row, keep the rest of the queue.
        }
      }
      await QueueStore.save(entries);
    }
  }
}
