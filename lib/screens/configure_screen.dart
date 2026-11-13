import 'dart:io';
import '../widgets/section_label.dart';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'format_selection_screen.dart';
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
  String? _formatSelector;
  bool? _engineReady;
  late final TextEditingController _fileNameController;

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
    _fileNameController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkEngine());
  }

  @override
  void dispose() {
    _fileNameController.dispose();
    super.dispose();
  }

  Future<void> _checkEngine() async {
    final status = await TalosScope.of(context).engine.status();
    if (mounted) setState(() => _engineReady = status.ready);
  }

  String _autoLabel() {
    final l = AppLocalizations.of(context)!;
    final rec = widget.probe.formats.where((f) => f.recommended).toList();
    if (rec.isEmpty) return l.formatAuto;
    final video = rec.firstWhere(
      (f) => f.vcodec != 'none' && f.vcodec != 'images',
      orElse: () => rec.first,
    );
    final label = video.resolution ?? video.note;
    final codec = (video.vcodec ?? '').split('.').first.toUpperCase();
    final ext = video.ext.toUpperCase();
    return '${l.formatAuto} ($label $ext $codec)';
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

    final outputDir = _videoMode
        ? (settings.videoFolder?.isNotEmpty == true ? settings.videoFolder! : manager.outputDirectory)
        : (settings.audioFolder?.isNotEmpty == true ? settings.audioFolder! : manager.outputDirectory);

    final requestedName = _fileNameController.text.trim();
    final request = DownloadRequest(
      url: widget.probe.webpageUrl,
      videoMode: _videoMode,
      outputDir: outputDir,
      maxHeight: _videoMode ? (_maxHeight == 0 ? null : _maxHeight) : null,
      audioFormat: _audioFormat,
      audioBitrate: _audioBitrate,
      embedSubtitles: _videoMode && _embedSubtitles,
      embedMetadata: _embedMetadata,
      filenameTemplate: settings.filenameTemplate,
      outputFilename: requestedName.isEmpty ? null : requestedName,
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
      formatSelector: _formatSelector ?? '',
      restrictFilenames: settings.restrictFilenames,
      downloadArchive: settings.downloadArchive ? '${(await getApplicationSupportDirectory()).path}${Platform.pathSeparator}download_archive.txt' : '',
      cropArtwork: settings.cropArtwork,
      subtitleFormat: settings.subtitleFormat,
      clipStartSeconds: settings.clipStartSeconds,
      clipEndSeconds: settings.clipEndSeconds,
      forceIpv4: settings.forceIpv4,
      remuxContainer: settings.remuxContainer,
      maxFilesize: settings.maxFilesize,
      userAgent: settings.userAgent,
      formatSort: settings.formatSort,
      downloadSubtitles: settings.downloadSubtitles,
      autoSubtitle: settings.autoSubtitle,
      keepSubtitles: settings.keepSubtitles,
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
                const SizedBox(height: 16),
                TextField(
                  controller: _fileNameController,
                  decoration: InputDecoration(
                    hintText: l.outputFileNameHint,
                    labelText: l.outputFileName,
                    prefixIcon: const Icon(Icons.edit_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(value: true, icon: const Icon(Icons.movie_outlined), label: Text(l.modeVideo)),
                    ButtonSegment(value: false, icon: const Icon(Icons.music_note_outlined), label: Text(l.modeAudio)),
                  ],
                  selected: {_videoMode},
                  onSelectionChanged: (selection) => setState(() => _videoMode = selection.first),
                ),
                if (probe.formats.isNotEmpty)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.tune),
                    title: Text(l.chooseFormats),
                    subtitle: Text(_formatSelector == null ? _autoLabel() : _formatSelector!),
                    onTap: () async {
                      final selected = await Navigator.of(context).push<String?>(
                        MaterialPageRoute(
                          builder: (_) => FormatSelectionScreen(probe: probe, initialSelector: _formatSelector),
                        ),
                      );
                      if (!mounted) return;
                      setState(() => _formatSelector = selected);
                    },
                  ),
                const SizedBox(height: 12),
                if (_videoMode) ...[
                  SectionLabel(l.videoHeight),
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
                  const SizedBox(height: 12),
                  SwitchListTile(
                    value: _embedSubtitles,
                    onChanged: (value) => setState(() => _embedSubtitles = value),
                    title: Text(l.subtitles),
                    contentPadding: EdgeInsets.zero,
                  ),
                ] else ...[
                  SectionLabel(l.audioFormat),
                  DropdownButtonFormField<String>(
                    initialValue: _audioFormat,
                    decoration: const InputDecoration(),
                    items: [
                      for (final format in _audioFormats)
                        DropdownMenuItem(value: format, child: Text(format.toUpperCase())),
                    ],
                    onChanged: (value) => setState(() => _audioFormat = value ?? 'mp3'),
                  ),
                  const SizedBox(height: 12),
                  SectionLabel(l.audioBitrate),
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
                  const SizedBox(height: 8),
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

