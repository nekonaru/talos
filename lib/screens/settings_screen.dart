import 'dart:async';
import 'dart:io';

import '../widgets/section_label.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_scope.dart';
import '../core/app_info.dart';
import '../core/backup.dart';
import '../core/command_template_store.dart';
import '../core/settings_store.dart';
import '../core/storage_cleanup.dart';
import '../core/storage_bridge.dart';
import '../core/update_checker.dart';
import '../core/theme.dart';
import '../gen/app_localizations.dart';
import 'about_screen.dart';
import 'commands_screen.dart';
import 'cookie_generator_screen.dart';
import 'error_message.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _engineVersion;
  String? _ffmpegDetected;
  bool _engineReady = false;
  bool _updating = false;
  double _updateFraction = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshEngine());
  }

  Future<void> _refreshEngine() async {
    try {
      final status = await TalosScope.of(context).engine.status();
      if (!mounted) return;
      setState(() {
        _engineReady = status.ready;
        _engineVersion = status.version;
        _ffmpegDetected = status.ffmpegPath;
      });
    } catch (_) {
      // A channel failure is shown as an unavailable engine, not a crash.
      if (mounted) setState(() => _engineReady = false);
    }
  }

  /// Shows the whole backup as text so it can be copied or shared. No file
  /// permission is required, and the payload stays readable and portable.
  Future<void> _exportBackup() async {
    final l = AppLocalizations.of(context)!;
    final manager = TalosScope.of(context);
    try {
      final json = await TalosBackup.exportJson(manager);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l.backupExport),
          content: SizedBox(
            width: double.maxFinite,
            child: TextField(
              controller: TextEditingController(text: json),
              maxLines: 8,
              readOnly: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l.close),
            ),
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: json));
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l.backupExported)),
                  );
                }
              },
              child: Text(l.copy),
            ),
            FilledButton(
              onPressed: () {
                unawaited(SharePlus.instance.share(
                  ShareParams(text: json, subject: 'Talos backup'),
                ));
                Navigator.of(dialogContext).pop();
              },
              child: Text(l.share),
            ),
          ],
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.backupFailed)),
        );
      }
    }
  }

  Future<void> _showPermissions() async {
    final l = AppLocalizations.of(context)!;
    final status = await TalosStorageBridge.permissionStatus();
    if (!mounted) return;
    final notifications = status['notifications'] ?? false;
    final storage = status['storage'] ?? false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.permissions),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.permissionsIntro, style: Theme.of(dialogContext).textTheme.bodySmall),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(notifications ? Icons.check_circle_outline : Icons.cancel_outlined,
                    color: notifications ? Colors.green : Colors.red),
                const SizedBox(width: 8),
                Expanded(child: Text(l.permissionNotifications)),
                Text(notifications ? l.permissionGranted : l.permissionDenied),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(storage ? Icons.check_circle_outline : Icons.cancel_outlined,
                    color: storage ? Colors.green : Colors.red),
                const SizedBox(width: 8),
                Expanded(child: Text(l.permissionStorage)),
                Text(storage ? l.permissionGranted : l.permissionDenied),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l.close),
          ),
          FilledButton(
            onPressed: () async {
              await TalosStorageBridge.openAppSettings();
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
            },
            child: Text(l.openSettings),
          ),
        ],
      ),
    );
  }

  Future<void> _cleanTemporaryFiles() async {
    final l = AppLocalizations.of(context)!;
    final manager = TalosScope.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.cleanTemp),
        content: Text(l.cleanTempBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l.cleanTemp),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final support = await getApplicationSupportDirectory();
    final fromSupport = await cleanTemporaryFiles(support);
    final fromOutput = await cleanTemporaryFiles(Directory(manager.outputDirectory));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.cleanTempDone(fromSupport + fromOutput))),
    );
  }

  Future<void> _exportHistoryCsv() async {
    final l = AppLocalizations.of(context)!;
    final manager = TalosScope.of(context);
    final csv = manager.history.exportCsv();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.exportHistory),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: TextEditingController(text: csv),
            maxLines: 8,
            readOnly: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l.close),
          ),
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: csv));
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l.historyCsvCopied)),
                );
              }
            },
            child: Text(l.copy),
          ),
          FilledButton(
            onPressed: () {
              unawaited(SharePlus.instance.share(
                ShareParams(text: csv, subject: 'Talos history'),
              ));
              Navigator.of(dialogContext).pop();
            },
            child: Text(l.share),
          ),
        ],
      ),
    );
  }

  Future<void> _importBackup() async {
    final l = AppLocalizations.of(context)!;
    final manager = TalosScope.of(context);
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.backupImport),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.backupImportConfirmBody),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 6,
              decoration: InputDecoration(hintText: l.backupPasteHint),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l.backupImport),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await TalosBackup.restoreJson(manager, controller.text.trim());
      await manager.refreshOutputDirectory();
      // Restored settings may have removed a gate that was holding the queue.
      manager.kickQueue();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.backupImported)),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.backupInvalid)),
        );
      }
    }
  }

  Future<void> _updateEngine() async {
    final desktop = Theme.of(context).platform != TargetPlatform.android &&
        Theme.of(context).platform != TargetPlatform.iOS;
    setState(() {
      _updating = true;
      _updateFraction = 0;
    });
    final manager = TalosScope.of(context);
    try {
      await manager.engine.ensureReady(
        onPhase: (phase, fraction) {
          if (mounted) setState(() => _updateFraction = fraction);
        },
        force: desktop,
        channel: manager.settings.value.engineChannel,
      );
      await _refreshEngine();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyError(context, error))),
        );
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<void> _openLink(BuildContext context, String url) async {
    final l = AppLocalizations.of(context)!;
    try {
      final opened = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (!opened && context.mounted) {
        await Clipboard.setData(ClipboardData(text: url));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.linkUnavailable)));
        }
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.unknownError)));
    }
  }

  Future<String?> _editDialog({
    required String title,
    required String initial,
    String? hint,
    String? label,
  }) {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: hint, labelText: label),
          onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(AppLocalizations.of(context)!.cancel)),
          FilledButton(onPressed: () => Navigator.of(context).pop(controller.text.trim()), child: Text(AppLocalizations.of(context)!.save)),
        ],
      ),
    ).whenComplete(controller.dispose);
  }

  Future<(int?, int?)?> _clipRangeDialog(BuildContext context, int? startSec, int? endSec) {
    final startController = TextEditingController(text: startSec?.toString() ?? '');
    final endController = TextEditingController(text: endSec?.toString() ?? '');
    String? error;
    return showDialog<(int?, int?)?>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final l = AppLocalizations.of(context)!;
          return AlertDialog(
            title: Text(l.clipVideo),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: startController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: l.clipFrom),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: endController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: l.clipTo),
                ),
                if (error != null) ...[
                  const SizedBox(height: 10),
                  Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l.cancel)),
              FilledButton(
                onPressed: () {
                  // Empty fields mean no bound; typed garbage is rejected
                  // instead of silently clearing the range.
                  final startText = startController.text.trim();
                  final endText = endController.text.trim();
                  if (startText.isNotEmpty && int.tryParse(startText) == null ||
                      endText.isNotEmpty && int.tryParse(endText) == null) {
                    setDialogState(() => error = l.clipInvalid);
                    return;
                  }
                  final start = startText.isEmpty ? null : int.parse(startText);
                  final end = endText.isEmpty ? null : int.parse(endText);
                  if ((start != null && start < 0) ||
                      (end != null && end < 0) ||
                      (start != null && end != null && end <= start)) {
                    setDialogState(() => error = l.clipInvalid);
                    return;
                  }
                  Navigator.of(context).pop((start, end));
                },
                child: Text(l.save),
              ),
            ],
          );
        },
      ),
    ).whenComplete(() {
      startController.dispose();
      endController.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final manager = TalosScope.of(context);
    final settings = manager.settings.value;
    final desktop = Theme.of(context).platform != TargetPlatform.android &&
        Theme.of(context).platform != TargetPlatform.iOS;

    return Scaffold(
      appBar: AppBar(title: Text(l.settings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          SectionLabel(l.engine),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(_engineReady ? Icons.check_circle_outline : Icons.error_outline,
                      color: _engineReady ? theme.colorScheme.primary : theme.colorScheme.error),
                  title: Text(l.engineStatus),
                  subtitle: Text(_engineReady ? (_engineVersion ?? l.engineReady) : l.engineMissing),
                  trailing: _updating
                      ? SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(value: _updateFraction > 0 ? _updateFraction : null, strokeWidth: 2),
                        )
                      : desktop
                          ? TextButton(onPressed: _updateEngine, child: Text(l.updateEngine))
                          : null,
                ),
                // On mobile FFmpegKit is bundled; a user path is not a
                // spawnable binary and would only mislead.
                if (desktop)
                ListTile(
                  leading: const Icon(Icons.movie_filter_outlined),
                  title: Text(l.ffmpegPath),
                  subtitle: Text(settings.ffmpegPath.isNotEmpty ? settings.ffmpegPath : (_ffmpegDetected ?? l.ffmpegAuto)),
                  onTap: () async {
                    final value = await _editDialog(title: l.ffmpegPath, initial: settings.ffmpegPath, hint: l.ffmpegAuto);
                    if (value != null) {
                      await manager.settings.mutate((s) => s.copyWith(ffmpegPath: value));
                      await _refreshEngine();
                    }
                  },
                ),
              ],
            ),
          ),
          SectionLabel(l.downloadsSection),
          Card(
            child: Column(
              children: [
                if (desktop)
                  ListTile(
                    leading: const Icon(Icons.folder_outlined),
                    title: Text(l.downloadFolder),
                    subtitle: Text(settings.downloadFolder?.isNotEmpty == true ? settings.downloadFolder! : manager.outputDirectory),
                    onTap: () async {
                      final value = await _editDialog(title: l.downloadFolder, initial: settings.downloadFolder ?? '', hint: manager.outputDirectory);
                      if (value != null) {
                        await manager.settings.mutate((s) => value.isEmpty ? s.copyWith(clearDownloadFolder: true) : s.copyWith(downloadFolder: value));
                      }
                    },
                  )
                else ...[
                  ListTile(
                    leading: const Icon(Icons.folder_outlined),
                    title: Text(settings.downloadFolderSAF.isNotEmpty ? l.downloadsCustomFolder : l.downloadsDefault),
                    subtitle: Text(
                      settings.downloadFolderSAF.isNotEmpty ? l.downloadsCustomFolderHint : l.downloadsDefaultHint,
                    ),
                    trailing: settings.downloadFolderSAF.isNotEmpty
                        ? TextButton(
                            onPressed: () async {
                              await TalosStorageBridge.clearTree();
                              await manager.settings.mutate((s) => s.copyWith(downloadFolderSAF: ''));
                            },
                            child: Text(l.downloadsResetDefault),
                          )
                        : TextButton(
                            onPressed: () async {
                              final uri = await TalosStorageBridge.pickDownloadsTree();
                              if (uri != null && uri.isNotEmpty) {
                                await manager.settings.mutate((s) => s.copyWith(downloadFolderSAF: uri));
                              }
                            },
                            child: Text(l.safStoragePick),
                          ),
                  ),
                ],
                ListTile(
                  leading: const Icon(Icons.drive_file_rename_outline),
                  title: Text(l.filenameTemplate),
                  subtitle: Text(settings.filenameTemplate),
                  onTap: () async {
                    final value = await _editDialog(title: l.filenameTemplate, initial: settings.filenameTemplate, hint: '%(title)s.%(ext)s');
                    if (value != null && value.isNotEmpty) {
                      await manager.settings.mutate((s) => s.copyWith(filenameTemplate: value));
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.folder_outlined),
                  title: Text(l.customCommandDirectory),
                  subtitle: Text(settings.customCommandDirectory?.isNotEmpty == true ? settings.customCommandDirectory! : l.customCommandDirectoryHint),
                  onTap: () async {
                    final value = await _editDialog(title: l.customCommandDirectory, initial: settings.customCommandDirectory ?? '', hint: l.customCommandDirectoryHint);
                    if (value != null) {
                      await manager.settings.mutate((s) => value.isEmpty
                          ? s.copyWith(clearCustomCommandDirectory: true)
                          : s.copyWith(customCommandDirectory: value));
                    }
                  },
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.schedule_outlined),
                  title: Text(l.quietHours),
                  subtitle: Text(l.quietHoursHint),
                  value: settings.quietHoursEnabled,
                  onChanged: (value) async {
                    await manager.settings.mutate(
                      (s) => s.copyWith(quietHoursEnabled: value),
                    );
                    manager.kickQueue();
                  },
                ),
                if (settings.quietHoursEnabled)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 20, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(l.quietStart),
                        ),
                        DropdownButton<int>(
                          value: settings.quietStartHour,
                          underline: const SizedBox(),
                          items: [
                            for (var hour = 0; hour < 24; hour++)
                              DropdownMenuItem(value: hour, child: Text('$hour')),
                          ],
                          onChanged: (value) => manager.settings.mutate(
                            (s) => s.copyWith(quietStartHour: value ?? 22),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(child: Text(l.quietEnd)),
                        DropdownButton<int>(
                          value: settings.quietEndHour,
                          underline: const SizedBox(),
                          items: [
                            for (var hour = 0; hour < 24; hour++)
                              DropdownMenuItem(value: hour, child: Text('$hour')),
                          ],
                          onChanged: (value) => manager.settings.mutate(
                            (s) => s.copyWith(quietEndHour: value ?? 6),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (Theme.of(context).platform == TargetPlatform.android)
                  SwitchListTile(
                    secondary: const Icon(Icons.battery_saver_outlined),
                    title: Text(l.batterySaver),
                    subtitle: Text(l.batterySaverHint),
                    value: settings.batterySaverEnabled,
                    onChanged: (value) async {
                      await manager.settings.mutate(
                        (s) => s.copyWith(batterySaverEnabled: value),
                      );
                      manager.kickQueue();
                    },
                  ),
                if (Theme.of(context).platform == TargetPlatform.android &&
                    settings.batterySaverEnabled)
                  ListTile(
                    leading: const Icon(Icons.battery_full_outlined),
                    title: Text(l.batteryThreshold),
                    trailing: DropdownButton<int>(
                      value: settings.batteryThreshold,
                      underline: const SizedBox(),
                      items: [
                        for (final percent in const [5, 10, 20, 30])
                          DropdownMenuItem(
                            value: percent,
                            child: Text(l.batteryPercent(percent)),
                          ),
                      ],
                      onChanged: (value) => manager.settings.mutate(
                        (s) => s.copyWith(batteryThreshold: value ?? 20),
                      ),
                    ),
                  ),
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_outlined),
                  title: Text(l.downloadNotification),
                  subtitle: Text(l.downloadNotificationHint),
                  value: settings.downloadNotification,
                  onChanged: (value) => manager.settings.mutate((s) => s.copyWith(downloadNotification: value)),
                ),
                ListTile(
                  leading: const Icon(Icons.replay_outlined),
                  title: Text(l.autoRetry),
                  subtitle: Text(l.autoRetryHint),
                  trailing: DropdownButton<int>(
                    value: settings.autoRetryAttempts,
                    underline: const SizedBox(),
                    items: [
                      for (var count = 0; count <= 3; count++)
                        DropdownMenuItem(
                          value: count,
                          child: Text(count == 0 ? l.autoRetryOff : '$count'),
                        ),
                    ],
                    onChanged: (value) => manager.settings.mutate(
                      (s) => s.copyWith(autoRetryAttempts: value ?? 0),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.history_toggle_off_outlined),
                  title: Text(l.historyRetention),
                  subtitle: Text(l.historyRetentionHint),
                  trailing: DropdownButton<int>(
                    value: settings.historyRetentionDays,
                    underline: const SizedBox(),
                    items: [
                      for (final days in const [0, 7, 30, 90])
                        DropdownMenuItem(
                          value: days,
                          child: Text(days == 0
                              ? l.autoRetryOff
                              : l.historyRetentionDays(days)),
                        ),
                    ],
                    onChanged: (value) => manager.settings.mutate(
                      (s) => s.copyWith(historyRetentionDays: value ?? 0),
                    ),
                  ),
                ),
                if (Theme.of(context).platform == TargetPlatform.android)
                  SwitchListTile(
                    secondary: const Icon(Icons.wifi_outlined),
                    title: Text(l.wifiOnly),
                    subtitle: Text(l.wifiOnlyHint),
                    value: settings.wifiOnly,
                    onChanged: (value) async {
                      await manager.settings.mutate((s) => s.copyWith(wifiOnly: value));
                      manager.kickQueue();
                    },
                  ),
                SwitchListTile(
                  secondary: const Icon(Icons.visibility_off_outlined),
                  title: Text(l.privateMode),
                  subtitle: Text(l.privateModeHint),
                  value: settings.privateMode,
                  onChanged: (value) => manager.settings.mutate((s) => s.copyWith(privateMode: value)),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.archive_outlined),
                  title: Text(l.downloadArchive),
                  subtitle: Text(l.downloadArchiveHint),
                  value: settings.downloadArchive,
                  onChanged: (value) => manager.settings.mutate((s) => s.copyWith(downloadArchive: value)),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.text_fields),
                  title: Text(l.restrictFilenames),
                  subtitle: Text(l.restrictFilenamesHint),
                  value: settings.restrictFilenames,
                  onChanged: (value) => manager.settings.mutate((s) => s.copyWith(restrictFilenames: value)),
                ),
                ListTile(
                  leading: const Icon(Icons.folder_outlined),
                  title: Text(l.videoFolder),
                  subtitle: Text(settings.videoFolder?.isNotEmpty == true ? settings.videoFolder! : l.videoFolderHint),
                  onTap: () async {
                    final value = await _editDialog(title: l.videoFolder, initial: settings.videoFolder ?? '', hint: l.videoFolderHint);
                    if (value != null) {
                      await manager.settings.mutate((s) => value.isEmpty
                          ? s.copyWith(clearVideoFolder: true)
                          : s.copyWith(videoFolder: value));
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.music_note_outlined),
                  title: Text(l.audioFolder),
                  subtitle: Text(settings.audioFolder?.isNotEmpty == true ? settings.audioFolder! : l.audioFolderHint),
                  onTap: () async {
                    final value = await _editDialog(title: l.audioFolder, initial: settings.audioFolder ?? '', hint: l.audioFolderHint);
                    if (value != null) {
                      await manager.settings.mutate((s) => value.isEmpty
                          ? s.copyWith(clearAudioFolder: true)
                          : s.copyWith(audioFolder: value));
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.straighten),
                  title: Text(l.maxFilesize),
                  subtitle: Text(settings.maxFilesize.isEmpty ? l.maxFilesizeHint : settings.maxFilesize),
                  onTap: () async {
                    final value = await _editDialog(title: l.maxFilesize, initial: settings.maxFilesize, hint: l.maxFilesizeHint);
                    if (value != null) await manager.settings.mutate((s) => s.copyWith(maxFilesize: value));
                  },
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.auto_awesome),
                  title: Text(l.autoUpdateEngine),
                  subtitle: Text(l.autoUpdateEngineHint),
                  value: settings.autoUpdateEngine,
                  onChanged: (value) => manager.settings.mutate((s) => s.copyWith(autoUpdateEngine: value)),
                ),
              ],
            ),
          ),
          SectionLabel(l.formatSection),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.high_quality_outlined),
                  title: Text(l.defaultVideoHeight),
                  trailing: DropdownButton<int>(
                    value: settings.defaultMaxHeight,
                    underline: const SizedBox(),
                    items: [
                      DropdownMenuItem(value: 0, child: Text(l.qualityBest)),
                      DropdownMenuItem(value: 2160, child: Text('2160p')),
                      DropdownMenuItem(value: 1440, child: Text('1440p')),
                      DropdownMenuItem(value: 1080, child: Text('1080p')),
                      DropdownMenuItem(value: 720, child: Text('720p')),
                      DropdownMenuItem(value: 480, child: Text('480p')),
                      DropdownMenuItem(value: 360, child: Text('360p')),
                    ],
                    onChanged: (value) => manager.settings.mutate((s) => s.copyWith(defaultMaxHeight: value ?? 0)),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.music_note_outlined),
                  title: Text(l.defaultAudioFormat),
                  trailing: DropdownButton<String>(
                    value: settings.defaultAudioFormat,
                    underline: const SizedBox(),
                    items: [
                      DropdownMenuItem(value: 'mp3', child: Text('MP3')),
                      DropdownMenuItem(value: 'm4a', child: Text('M4A')),
                      DropdownMenuItem(value: 'opus', child: Text('Opus')),
                      DropdownMenuItem(value: 'flac', child: Text('FLAC')),
                      DropdownMenuItem(value: 'best', child: Text(l.qualityBest)),
                    ],
                    onChanged: (value) => manager.settings.mutate((s) => s.copyWith(defaultAudioFormat: value ?? 'mp3')),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.sort),
                  title: Text(l.formatSort),
                  subtitle: Text(settings.formatSort.isEmpty ? l.formatSortHint : settings.formatSort),
                  onTap: () async {
                    final value = await _editDialog(title: l.formatSort, initial: settings.formatSort, hint: l.formatSortHint);
                    if (value != null) await manager.settings.mutate((s) => s.copyWith(formatSort: value));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.graphic_eq),
                  title: Text(l.defaultAudioBitrate),
                  trailing: DropdownButton<String>(
                    value: settings.defaultAudioBitrate,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: '128', child: Text('128k')),
                      DropdownMenuItem(value: '192', child: Text('192k')),
                      DropdownMenuItem(value: '256', child: Text('256k')),
                      DropdownMenuItem(value: '320', child: Text('320k')),
                    ],
                    onChanged: (value) => manager.settings.mutate((s) => s.copyWith(defaultAudioBitrate: value ?? '192')),
                  ),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.crop_square_outlined),
                  title: Text(l.cropArtwork),
                  subtitle: Text(l.cropArtworkHint),
                  value: settings.cropArtwork,
                  onChanged: (value) => manager.settings.mutate((s) => s.copyWith(cropArtwork: value)),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.subtitles_outlined),
                  title: Text(l.downloadSubtitles),
                  subtitle: Text(l.downloadSubtitlesHint),
                  value: settings.downloadSubtitles,
                  onChanged: (value) => manager.settings.mutate((s) => s.copyWith(downloadSubtitles: value)),
                ),
                if (settings.downloadSubtitles) ...[
                  SwitchListTile(
                    secondary: const Icon(Icons.closed_caption_outlined),
                    title: Text(l.autoSubtitle),
                    subtitle: Text(l.autoSubtitleHint),
                    value: settings.autoSubtitle,
                    onChanged: (value) => manager.settings.mutate((s) => s.copyWith(autoSubtitle: value)),
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.save_outlined),
                    title: Text(l.keepSubtitles),
                    subtitle: Text(l.keepSubtitlesHint),
                    value: settings.keepSubtitles,
                    onChanged: (value) => manager.settings.mutate((s) => s.copyWith(keepSubtitles: value)),
                  ),
                ],
                ListTile(
                  leading: const Icon(Icons.subtitles_outlined),
                  title: Text(l.subtitleLanguage),
                  subtitle: Text(settings.subtitleLanguage.isEmpty ? l.subtitleLanguageHint : settings.subtitleLanguage),
                  onTap: () async {
                    final value = await _editDialog(
                      title: l.subtitleLanguage,
                      initial: settings.subtitleLanguage,
                      hint: l.subtitleLanguageHint,
                    );
                    if (value != null) await manager.settings.mutate((s) => s.copyWith(subtitleLanguage: value));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.text_fields),
                  title: Text(l.subtitleFormat),
                  subtitle: Text(settings.subtitleFormat.isEmpty ? l.subtitleFormatHint : settings.subtitleFormat),
                  onTap: () async {
                    final value = await _editDialog(
                      title: l.subtitleFormat,
                      initial: settings.subtitleFormat,
                      hint: l.subtitleFormatHint,
                    );
                    if (value != null) await manager.settings.mutate((s) => s.copyWith(subtitleFormat: value));
                  },
                ),
                // Clip sections need an ffmpeg executable, which only exists
                // on desktop. Hiding the control avoids a setting that is
                // silently ignored on Android and iOS.
                if (desktop)
                ListTile(
                  leading: const Icon(Icons.content_cut_outlined),
                  title: Text(l.clipVideo),
                  subtitle: Text(() {
                    final start = settings.clipStartSeconds;
                    final end = settings.clipEndSeconds;
                    if (start == null && end == null) return l.clipVideoHint;
                    final from = start ?? 0;
                    if (end == null) return '${l.clipFrom} $from ${l.secondsUnit}';
                    return '$from - $end ${l.secondsUnit}';
                  }()),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final ctx = context;
                    final result = await _clipRangeDialog(ctx, settings.clipStartSeconds, settings.clipEndSeconds);
                    if (!mounted) return;
                    if (result == null) return;
                    await manager.settings.mutate((s) => result.$1 == null && result.$2 == null
                        ? s.copyWith(clearClipRange: true)
                        : s.copyWith(clipStartSeconds: result.$1, clipEndSeconds: result.$2));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.movie_outlined),
                  title: Text(l.remuxContainer),
                  subtitle: Text(settings.remuxContainer.isEmpty ? l.remuxContainerHint : settings.remuxContainer.toUpperCase()),
                  trailing: DropdownButton<String>(
                    value: settings.remuxContainer,
                    underline: const SizedBox(),
                    items: [
                      DropdownMenuItem(value: '', child: Text(l.qualityNone)),
                      DropdownMenuItem(value: 'mp4', child: Text('MP4')),
                      DropdownMenuItem(value: 'mkv', child: Text('MKV')),
                      DropdownMenuItem(value: 'webm', child: Text('WebM')),
                    ],
                    onChanged: (value) => manager.settings.mutate((s) => s.copyWith(remuxContainer: value ?? '')),
                  ),
                ),
              ],
            ),
          ),
          SectionLabel(l.network),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.public),
                  title: Text(l.proxy),
                  subtitle: Text(settings.proxy.isEmpty ? l.proxyHint : settings.proxy),
                  onTap: () async {
                    final value = await _editDialog(title: l.proxy, initial: settings.proxy, hint: l.proxyHint);
                    if (value != null) await manager.settings.mutate((s) => s.copyWith(proxy: value));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.speed_outlined),
                  title: Text(l.rateLimit),
                  subtitle: Text(settings.rateLimit.isEmpty ? l.rateLimitHint : settings.rateLimit),
                  onTap: () async {
                    final value = await _editDialog(title: l.rateLimit, initial: settings.rateLimit, hint: l.rateLimitHint);
                    if (value != null) await manager.settings.mutate((s) => s.copyWith(rateLimit: value));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(l.userAgent),
                  subtitle: Text(settings.userAgent.isEmpty ? l.userAgentHint : settings.userAgent),
                  onTap: () async {
                    final value = await _editDialog(title: l.userAgent, initial: settings.userAgent, hint: l.userAgentHint);
                    if (value != null) await manager.settings.mutate((s) => s.copyWith(userAgent: value));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.account_tree_outlined),
                  title: Text(l.fragments),
                  trailing: DropdownButton<int>(
                    value: settings.concurrentFragments,
                    underline: const SizedBox(),
                    items: const [1, 2, 4, 8, 16]
                        .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
                        .toList(),
                    onChanged: (value) => manager.settings.mutate((s) => s.copyWith(concurrentFragments: value ?? 4)),
                  ),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.settings_ethernet),
                  title: Text(l.forceIpv4),
                  subtitle: Text(l.forceIpv4Hint),
                  value: settings.forceIpv4,
                  onChanged: (value) => manager.settings.mutate((s) => s.copyWith(forceIpv4: value)),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.block_outlined),
                  title: Text(l.sponsorBlock),
                  value: settings.sponsorBlockEnabled,
                  onChanged: (value) => manager.settings.mutate((s) => s.copyWith(sponsorBlockEnabled: value)),
                ),
                if (settings.sponsorBlockEnabled)
                  ListTile(
                    leading: const SizedBox(width: 24),
                    title: Text(l.sponsorBlock),
                    subtitle: Text(settings.sponsorBlockCategories),
                    onTap: () async {
                      final value = await _editDialog(
                        title: l.sponsorBlock,
                        initial: settings.sponsorBlockCategories,
                        hint: l.sponsorBlockHint,
                      );
                      if (value != null && value.isNotEmpty) {
                        await manager.settings.mutate((s) => s.copyWith(sponsorBlockCategories: value));
                      }
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.cookie_outlined),
                  title: Text(l.cookies),
                  subtitle: Text(settings.cookiesPath.isEmpty ? l.cookiesHint : settings.cookiesPath),
                  onTap: () async {
                    final value = await _editDialog(title: l.cookies, initial: settings.cookiesPath, hint: l.cookiesHint);
                    if (value != null) await manager.settings.mutate((s) => s.copyWith(cookiesPath: value));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.http_outlined),
                  title: Text(l.customHeaders),
                  subtitle: Text(
                    settings.customHeaders.isEmpty
                        ? l.customHeadersHint
                        : settings.customHeaders.split(RegExp(r'\r?\n')).first,
                  ),
                  onTap: () async {
                    final value = await _editDialog(
                      title: l.customHeaders,
                      initial: settings.customHeaders,
                      hint: l.customHeadersHint,
                    );
                    if (value != null) {
                      await manager.settings.mutate((s) => s.copyWith(customHeaders: value));
                    }
                  },
                ),
                if (desktop)
                  ListTile(
                    leading: const Icon(Icons.science_outlined),
                    title: Text(l.engineChannel),
                    subtitle: Text(l.engineChannelHint),
                    trailing: DropdownButton<String>(
                      value: settings.engineChannel,
                      underline: const SizedBox(),
                      items: [
                        DropdownMenuItem(value: 'stable', child: Text(l.engineChannelStable)),
                        DropdownMenuItem(value: 'nightly', child: Text(l.engineChannelNightly)),
                      ],
                      onChanged: (value) => manager.settings.mutate((s) => s.copyWith(engineChannel: value ?? 'stable')),
                    ),
                  ),
                if (desktop)
                  SwitchListTile(
                    secondary: const Icon(Icons.bolt_outlined),
                    title: Text(l.aria2),
                    value: settings.useAria2,
                    onChanged: (value) => manager.settings.mutate((s) => s.copyWith(useAria2: value)),
                  ),
              ],
            ),
          ),
          if (!desktop)
            SectionLabel(l.cookieGenerator),
          if (!desktop)
            Card(
              child: ListTile(
                leading: const Icon(Icons.cookie_outlined),
                title: Text(l.cookieGenerator),
                subtitle: Text(l.cookieGeneratorHint),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CookieGeneratorScreen())),
              ),
            ),
          SectionLabel(l.appearance),
          Card(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.brightness_6_outlined, size: 24),
                          const SizedBox(width: 12),
                          Text(l.theme, style: theme.textTheme.titleMedium),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SegmentedButton<String>(
                        segments: [
                          ButtonSegment(value: 'system', label: Text(l.themeSystem)),
                          ButtonSegment(value: 'light', label: Text(l.themeLight)),
                          ButtonSegment(value: 'dark', label: Text(l.themeDark)),
                        ],
                        selected: {settings.themeMode},
                        onSelectionChanged: (selection) => manager.settings.mutate((s) => s.copyWith(themeMode: selection.first)),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.palette_outlined),
                  title: Text(l.accent),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(
                      spacing: 10,
                      children: [
                        for (final accent in TalosAccent.values)
                          _AccentDot(
                            accent: accent,
                            selected: settings.accent == accent.name,
                            onTap: () => manager.settings.mutate((s) => s.copyWith(accent: accent.name)),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SectionLabel(l.commands),
          Card(
            child: ListTile(
              leading: const Icon(Icons.terminal_outlined),
              title: Text(l.commands),
              subtitle: Text(l.commandsHint),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CommandsScreen())),
            ),
          ),
          SectionLabel(l.about),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(l.aboutTalos),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AboutScreen())),
                ),
                const Divider(height: 1),
                _UpdateTile(
                  checkingForText: l.checking,
                  availableText: l.updateAvailable,
                  upToDateText: l.upToDate,
                  failedText: l.updateCheckFailed,
                  updateAvailableNotesLabel: l.updateReleaseNotes,
                  downloadText: l.downloadUpdate,
                ),
              ],
            ),
          ),
          SectionLabel(l.author),
          Card(
            child: ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Nicolas Dwi Dharma'),
              subtitle: Text(l.authorGithub),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () => _openLink(context, TalosInfo.authorUrl),
            ),
          ),
          SectionLabel(l.support),
          Card(
            child: Column(
              children: [
                for (final sponsor in TalosInfo.sponsors)
                  ListTile(
                    leading: const Icon(Icons.favorite_border_rounded),
                    title: Text(sponsor.$1),
                    trailing: const Icon(Icons.open_in_new, size: 18),
                    onTap: () => _openLink(context, sponsor.$2),
                  ),
              ],
            ),
          ),
          if (Theme.of(context).platform == TargetPlatform.android) ...[
            SectionLabel(l.permissions),
            Card(
              child: ListTile(
                leading: const Icon(Icons.fact_check_outlined),
                title: Text(l.permissions),
                subtitle: Text(l.permissionsHint),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showPermissions,
              ),
            ),
          ],
          SectionLabel(l.backupRestore),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.backup_outlined),
                  title: Text(l.backupExport),
                  subtitle: Text(l.backupExportHint),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _exportBackup,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.restore_outlined),
                  title: Text(l.backupImport),
                  subtitle: Text(l.backupImportHint),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _importBackup,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.table_view_outlined),
                  title: Text(l.exportHistory),
                  subtitle: Text(l.exportHistoryHint),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _exportHistoryCsv,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.cleaning_services_outlined),
                  title: Text(l.cleanTemp),
                  subtitle: Text(l.cleanTempHint),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _cleanTemporaryFiles,
                ),
              ],
            ),
          ),
          SectionLabel(l.dangerZone),
          Card(
            child: ListTile(
              leading: Icon(Icons.delete_forever_outlined, color: theme.colorScheme.error),
              title: Text(l.resetAllData),
              subtitle: Text(l.resetAllDataHint),
              trailing: Icon(Icons.chevron_right, color: theme.colorScheme.error),
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: Text(l.resetAllDataTitle),
                    content: Text(l.resetAllDataBody),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        child: Text(l.cancel),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: theme.colorScheme.error),
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        child: Text(l.resetAllDataConfirm),
                      ),
                    ],
                  ),
                );
                if (confirmed != true || !context.mounted) return;
                final messenger = ScaffoldMessenger.of(context);
                // Cancel and drop in-flight work first so a running download
                // cannot add a fresh history row after the reset.
                await manager.resetAll();
                await manager.settings.mutate((_) => TalosSettings());
                await manager.refreshOutputDirectory();
                await manager.history.clear();
                await manager.savedLinks.clear();
                await manager.presets.clear();
                await CommandTemplateStore.resetAll();
                await TalosStorageBridge.clearTree();
                if (!context.mounted) return;
                messenger.showSnackBar(
                  SnackBar(content: Text(l.resetAllDataDone)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AccentDot extends StatelessWidget {
  const _AccentDot({required this.accent, required this.selected, required this.onTap});

  final TalosAccent accent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dotColor = isDark ? accent.dark : accent.deep;
    final checkColor = ThemeData.estimateBrightnessForColor(dotColor) == Brightness.dark
        ? Colors.white
        : const Color(0xFF161311);
    return Semantics(
      button: true,
      selected: selected,
      label: accent.name,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                border: Border.all(color: selected ? theme.colorScheme.primary : Colors.transparent, width: 3),
              ),
              child: selected ? Icon(Icons.check, size: 16, color: checkColor) : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _UpdateTile extends StatefulWidget {
  const _UpdateTile({
    required this.checkingForText,
    required this.availableText,
    required this.upToDateText,
    required this.failedText,
    required this.updateAvailableNotesLabel,
    required this.downloadText,
  });

  final String checkingForText;
  final String availableText;
  final String upToDateText;
  final String failedText;
  final String updateAvailableNotesLabel;
  final String downloadText;

  @override
  State<_UpdateTile> createState() => _UpdateTileState();
}

class _UpdateTileState extends State<_UpdateTile> {
  final UpdateChecker _checker = const UpdateChecker();
  bool _checking = false;
  UpdateCheckResult? _result;

  Future<void> _runCheck() async {
    setState(() {
      _checking = true;
      _result = null;
    });
    final result = await _checker.check();
    if (!mounted) return;
    setState(() {
      _checking = false;
      _result = result;
    });
  }

  Future<void> _open(String url) async {
    final l = AppLocalizations.of(context)!;
    try {
      final opened = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        await Clipboard.setData(ClipboardData(text: url));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.linkUnavailable)));
        }
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.updateCheckFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = _result?.info;
    return ListTile(
      leading: Icon(_result?.updateAvailable == true ? Icons.system_update_alt : Icons.search),
      title: Text(() {
        if (_checking) return widget.checkingForText;
        if (_result?.updateAvailable == true) return '${widget.availableText}: ${info?.tagName ?? ''}';
        if (_result?.upToDate == true) return widget.upToDateText;
        if (_result != null) return widget.failedText;
        return AppLocalizations.of(context)!.checkForUpdates;
      }()),
      subtitle: _result?.updateAvailable == true
          ? Text(widget.updateAvailableNotesLabel)
          : null,
      isThreeLine: _result?.updateAvailable == true,
      trailing: _checking
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : _result?.updateAvailable == true
              ? TextButton.icon(
                  onPressed: () => _open(info?.htmlUrl ?? 'https://github.com/nekonaru/talos/releases'),
                  icon: const Icon(Icons.download_rounded),
                  label: Text(widget.downloadText),
                )
              : const Icon(Icons.chevron_right),
      enabled: !_checking,
      onTap: _checking ? null : _runCheck,
    );
  }
}

