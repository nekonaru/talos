import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../core/theme.dart';
import '../gen/app_localizations.dart';
import 'about_screen.dart';
import 'commands_screen.dart';

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
    final status = await TalosScope.of(context).engine.status();
    if (!mounted) return;
    setState(() {
      _engineReady = status.ready;
      _engineVersion = status.version;
      _ffmpegDetected = status.ffmpegPath;
    });
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
      );
      await _refreshEngine();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) setState(() => _updating = false);
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
    );
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
          _SectionLabel(l.engine),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(_engineReady ? Icons.check_circle_outline : Icons.error_outline,
                      color: _engineReady ? theme.colorScheme.primary : theme.colorScheme.error),
                  title: Text(l.engineStatus),
                  subtitle: Text(_engineReady ? (_engineVersion ?? '') : l.engineMissing),
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
          _SectionLabel(l.downloadsSection),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.folder_outlined),
                  title: Text(l.downloadFolder),
                  subtitle: Text(settings.downloadFolder?.isNotEmpty == true ? settings.downloadFolder! : l.ffmpegAuto),
                  onTap: () async {
                    final value = await _editDialog(title: l.downloadFolder, initial: settings.downloadFolder ?? '', hint: l.ffmpegAuto);
                    if (value != null) {
                      await manager.settings.mutate((s) => value.isEmpty ? s.copyWith(clearDownloadFolder: true) : s.copyWith(downloadFolder: value));
                    }
                  },
                ),
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
                SwitchListTile(
                  secondary: const Icon(Icons.visibility_off_outlined),
                  title: Text(l.privateMode),
                  subtitle: Text(l.privateModeHint),
                  value: settings.privateMode,
                  onChanged: (value) => manager.settings.mutate((s) => s.copyWith(privateMode: value)),
                ),
              ],
            ),
          ),
          _SectionLabel(l.formatSection),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.high_quality_outlined),
                  title: Text(l.defaultVideoHeight),
                  trailing: DropdownButton<int>(
                    value: settings.defaultMaxHeight,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('Best')),
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
                    items: const [
                      DropdownMenuItem(value: 'mp3', child: Text('MP3')),
                      DropdownMenuItem(value: 'm4a', child: Text('M4A')),
                      DropdownMenuItem(value: 'opus', child: Text('Opus')),
                      DropdownMenuItem(value: 'flac', child: Text('FLAC')),
                      DropdownMenuItem(value: 'best', child: Text('Best')),
                    ],
                    onChanged: (value) => manager.settings.mutate((s) => s.copyWith(defaultAudioFormat: value ?? 'mp3')),
                  ),
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
              ],
            ),
          ),
          _SectionLabel(l.network),
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
                        hint: 'sponsor,selfpromo',
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
          _SectionLabel(l.appearance),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.brightness_6_outlined),
                  title: Text(l.theme),
                  trailing: SegmentedButton<String>(
                    segments: [
                      ButtonSegment(value: 'system', label: Text(l.themeSystem)),
                      ButtonSegment(value: 'light', label: Text(l.themeLight)),
                      ButtonSegment(value: 'dark', label: Text(l.themeDark)),
                    ],
                    selected: {settings.themeMode},
                    onSelectionChanged: (selection) => manager.settings.mutate((s) => s.copyWith(themeMode: selection.first)),
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
          _SectionLabel(l.commands),
          Card(
            child: ListTile(
              leading: const Icon(Icons.terminal_outlined),
              title: Text(l.commands),
              subtitle: Text(l.commandsHint),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CommandsScreen())),
            ),
          ),
          _SectionLabel(l.about),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(l.aboutTalos),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AboutScreen())),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: accent.dark,
          shape: BoxShape.circle,
          border: Border.all(color: selected ? Theme.of(context).colorScheme.primary : Colors.transparent, width: 3),
        ),
        child: selected ? const Icon(Icons.check, size: 16, color: Colors.black87) : null,
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
      child: Text(
        text.toUpperCase(),
        style: theme.textTheme.bodySmall?.copyWith(letterSpacing: 2.4),
      ),
    );
  }
}
