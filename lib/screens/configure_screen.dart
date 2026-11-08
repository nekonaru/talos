import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../core/engine/models.dart';
import '../core/format.dart';
import '../core/history_store.dart';
import '../gen/app_localizations.dart';

const _videoHeights = [0, 2160, 1440, 1080, 720, 480, 360];
const _audioFormats = ['mp3', 'm4a', 'opus', 'flac', 'best'];
const _audioBitrates = ['128', '192', '256', '320'];

class ConfigureScreen extends StatefulWidget {
  const ConfigureScreen({super.key, required this.probe});

  final MediaProbe probe;

  @override
  State<ConfigureScreen> createState() => _ConfigureScreenState();
}

class _ConfigureScreenState extends State<ConfigureScreen> {
  bool _videoMode = true;
  late int _maxHeight;
  late String _audioFormat;
  late String _audioBitrate;
  late bool _embedSubtitles;
  late bool _embedMetadata;
  late Set<int> _selected;
  bool? _engineReady;

  @override
  void initState() {
    super.initState();
    final settings = TalosScope.read(context).settings.value;
    _maxHeight = settings.defaultMaxHeight;
    _audioFormat = settings.defaultAudioFormat;
    _audioBitrate = settings.defaultAudioBitrate;
    _embedSubtitles = settings.embedSubtitles;
    _embedMetadata = settings.embedMetadata;
    _selected = {for (final entry in widget.probe.entries) entry.index};
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkEngine());
  }

  Future<void> _checkEngine() async {
    final status = await TalosScope.of(context).engine.status();
    if (mounted) setState(() => _engineReady = status.ready);
  }

  Future<void> _startDownload() async {
    final l = AppLocalizations.of(context)!;
    final manager = TalosScope.of(context);
    final settings = manager.settings.value;

    String? items;
    if (widget.probe.isPlaylist && widget.probe.entries.isNotEmpty) {
      if (_selected.length < widget.probe.entries.length) {
        items = (_selected.toList()..sort()).join(',');
      }
    }

    final request = DownloadRequest(
      url: widget.probe.webpageUrl,
      videoMode: _videoMode,
      outputDir: manager.outputDirectory,
      maxHeight: _videoMode ? (_maxHeight == 0 ? null : _maxHeight) : null,
      audioFormat: _audioFormat,
      audioBitrate: _audioBitrate,
      embedSubtitles: _videoMode && _embedSubtitles,
      embedMetadata: _embedMetadata,
      filenameTemplate: settings.filenameTemplate,
      proxy: settings.proxy,
      rateLimit: settings.rateLimit,
      useAria2: settings.useAria2,
      concurrentFragments: settings.concurrentFragments,
      playlistItems: items,
      includePlaylist: widget.probe.isPlaylist,
      ffmpegPath: settings.ffmpegPath,
      sponsorBlockCategories: settings.sponsorBlockEnabled ? settings.sponsorBlockCategories : '',
      cookiesPath: settings.cookiesPath,
      subtitleLanguage: settings.subtitleLanguage,
    );

    await manager.enqueue(
      request,
      title: widget.probe.title,
      kind: _videoMode ? HistoryKind.video : HistoryKind.audio,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.queued)));
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final probe = widget.probe;
    final entries = probe.entries;

    final downloadCount = probe.isPlaylist && entries.isNotEmpty ? _selected.length : 1;
    final canDownload = _engineReady == true && downloadCount > 0;

    return Scaffold(
      appBar: AppBar(title: Text(l.configureTitle)),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              children: [
                _MediaCard(probe: probe),
                const SizedBox(height: 18),
                SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(value: true, icon: const Icon(Icons.movie_outlined), label: Text(l.modeVideo)),
                    ButtonSegment(value: false, icon: const Icon(Icons.music_note_outlined), label: Text(l.modeAudio)),
                  ],
                  selected: {_videoMode},
                  onSelectionChanged: (selection) => setState(() => _videoMode = selection.first),
                ),
                const SizedBox(height: 18),
                if (_videoMode) ...[
                  _SectionLabel(l.videoHeight),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int>(
                    initialValue: _maxHeight,
                    decoration: const InputDecoration(),
                    items: [
                      for (final height in _videoHeights)
                        DropdownMenuItem(
                          value: height,
                          child: Text(height == 0 ? l.qualityBest : '${height}p'),
                        ),
                    ],
                    onChanged: (value) => setState(() => _maxHeight = value ?? 0),
                  ),
                  const SizedBox(height: 14),
                  SwitchListTile(
                    value: _embedSubtitles,
                    onChanged: (value) => setState(() => _embedSubtitles = value),
                    title: Text(l.subtitles),
                    contentPadding: EdgeInsets.zero,
                  ),
                ] else ...[
                  _SectionLabel(l.audioFormat),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _audioFormat,
                    decoration: const InputDecoration(),
                    items: [
                      for (final format in _audioFormats)
                        DropdownMenuItem(value: format, child: Text(format.toUpperCase())),
                    ],
                    onChanged: (value) => setState(() => _audioFormat = value ?? 'mp3'),
                  ),
                  const SizedBox(height: 14),
                  _SectionLabel(l.audioBitrate),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _audioBitrate,
                    decoration: const InputDecoration(),
                    items: [
                      for (final bitrate in _audioBitrates)
                        DropdownMenuItem(value: bitrate, child: Text('$bitrate kbps')),
                    ],
                    onChanged: (value) => setState(() => _audioBitrate = value ?? '192'),
                  ),
                ],
                SwitchListTile(
                  value: _embedMetadata,
                  onChanged: (value) => setState(() => _embedMetadata = value),
                  title: Text(l.metadata),
                  contentPadding: EdgeInsets.zero,
                ),
                if (probe.isPlaylist && entries.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '${l.playlistTitle} · ${l.playlistCount(entries.length)}',
                        style: theme.textTheme.titleMedium,
                      ),
                      const Spacer(),
                      TextButton(onPressed: () => setState(() => _selected = {for (final e in entries) e.index}), child: Text(l.selectAll)),
                      TextButton(onPressed: () => setState(() => _selected = {}), child: Text(l.selectNone)),
                    ],
                  ),
                  for (final entry in entries)
                    CheckboxListTile(
                      value: _selected.contains(entry.index),
                      onChanged: (checked) {
                        setState(() {
                          if (checked == true) {
                            _selected.add(entry.index);
                          } else {
                            _selected.remove(entry.index);
                          }
                        });
                      },
                      title: Text(entry.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                      subtitle: Text(formatDuration(entry.duration), style: theme.textTheme.bodySmall),
                      secondary: Text('${entry.index}', style: theme.textTheme.bodySmall),
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                ],
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  onPressed: canDownload ? _startDownload : null,
                  icon: const Icon(Icons.download_rounded),
                  label: Text(probe.isPlaylist && entries.isNotEmpty
                      ? '${l.download} ($downloadCount)'
                      : l.download),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MediaCard extends StatelessWidget {
  const _MediaCard({required this.probe});

  final MediaProbe probe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          SizedBox(
            width: 168,
            height: 104,
            child: probe.thumbnail != null
                ? Image.network(
                    probe.thumbnail!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.movie_outlined, size: 40),
                    ),
                  )
                : Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.movie_outlined, size: 40),
                  ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    probe.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (probe.uploader != null) Text(probe.uploader!, style: theme.textTheme.bodySmall),
                      if (probe.duration != null) Text(formatDuration(probe.duration), style: theme.textTheme.bodySmall),
                      if (probe.isPlaylist)
                        Chip(
                          label: Text(AppLocalizations.of(context)!.playlistTitle),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
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
    return Text(
      text.toUpperCase(),
      style: theme.textTheme.bodySmall?.copyWith(letterSpacing: 2.4),
    );
  }
}
