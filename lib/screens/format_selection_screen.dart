// Manual format picker for Talos. Lets the user choose a specific video
// and/or audio stream id from the formats reported by yt-dlp.
import 'package:flutter/material.dart';

import '../core/engine/models.dart';
import '../core/format.dart';
import '../gen/app_localizations.dart';

class FormatSelectionScreen extends StatefulWidget {
  const FormatSelectionScreen({super.key, required this.probe, this.initialSelector});

  final MediaProbe probe;
  final String? initialSelector;

  @override
  State<FormatSelectionScreen> createState() => _FormatSelectionScreenState();
}

class _FormatSelectionScreenState extends State<FormatSelectionScreen> {
  String? _videoId;
  String? _audioId;

  List<YtdlpFormat> get _videoFormats =>
      widget.probe.formats.where((f) => f.vcodec != 'none' && f.ext.isNotEmpty).toList()
        ..sort((a, b) => (b.height ?? 0).compareTo(a.height ?? 0));

  List<YtdlpFormat> get _audioFormats =>
      widget.probe.formats.where((f) => f.acodec != 'none' || f.vcodec == 'none').toList()
        ..sort((a, b) {
          final av = a.abr ?? a.vbr ?? 0;
          final bv = b.abr ?? b.vbr ?? 0;
          return bv.compareTo(av);
        });

  bool get _bestMode => _videoId == null && _audioId == null;

  String? get _selector {
    if (_bestMode) return null;
    if (_videoId != null && _audioId != null) return '$_videoId+$_audioId';
    return _videoId ?? _audioId;
  }

  @override
  void initState() {
    super.initState();
    final initial = widget.initialSelector;
    if (initial != null && initial.isNotEmpty) {
      final parts = initial.split('+');
      final vFormats = _videoFormats;
      final aFormats = _audioFormats;
      for (final p in parts) {
        if (vFormats.any((f) => f.id == p)) _videoId ??= p;
        if (aFormats.any((f) => f.id == p)) _audioId ??= p;
      }
      if (parts.length == 1 && _videoId == null && _audioId == null) {
        _videoId = parts.first;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final videoFormats = _videoFormats;
    final audioFormats = _audioFormats;

    return Scaffold(
      appBar: AppBar(title: Text(l.formatSelection)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text(widget.probe.title, style: theme.textTheme.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Text(l.formatSelectionHint, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(value: true, label: Text(l.formatAuto, style: const TextStyle(inherit: false)), icon: const Icon(Icons.auto_awesome)),
              ButtonSegment(value: false, label: Text(l.formatSelection, style: const TextStyle(inherit: false)), icon: const Icon(Icons.tune)),
            ],
            selected: {_bestMode},
            onSelectionChanged: (selection) {
              setState(() {
                if (selection.first) {
                  _videoId = null;
                  _audioId = null;
                } else {
                  _videoId ??= videoFormats.isNotEmpty ? videoFormats.first.id : null;
                  _audioId ??= audioFormats.isNotEmpty ? audioFormats.first.id : null;
                }
              });
            },
          ),
          const SizedBox(height: 20),
          Text('VIDEO', style: theme.textTheme.bodySmall?.copyWith(letterSpacing: 3)),
          const SizedBox(height: 8),
          for (final format in videoFormats)
            ListTile(
              onTap: () => setState(() => _videoId = format.id),
              leading: Icon(_videoId == format.id ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: theme.colorScheme.primary, size: 20),
              title: Text('${format.resolution ?? format.note}  (${format.ext.toUpperCase()})'),
              subtitle: Text([
                format.filesize != null ? formatBytes(format.filesize!) : '? B',
                if (format.vcodec != null) format.vcodec!,
                if (format.fps != null) '${format.fps} fps',
              ].join('  ·  '), style: theme.textTheme.bodySmall),
              dense: true,
            ),
          if (videoFormats.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(l.noVideoFormats, style: theme.textTheme.bodyMedium),
            ),
          const SizedBox(height: 12),
          Text('AUDIO', style: theme.textTheme.bodySmall?.copyWith(letterSpacing: 3)),
          const SizedBox(height: 8),
          for (final format in audioFormats)
            ListTile(
              onTap: () => setState(() => _audioId = format.id),
              leading: Icon(_audioId == format.id ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: theme.colorScheme.primary, size: 20),
              title: Text('${format.resolution ?? format.note}  (${format.ext.toUpperCase()})'),
              subtitle: Text([
                format.filesize != null ? formatBytes(format.filesize!) : '? B',
                if (format.acodec != null) format.acodec!,
                if (format.abr != null) '${format.abr!.toStringAsFixed(0)} kbps',
              ].join('  ·  '), style: theme.textTheme.bodySmall),
              dense: true,
            ),
          if (audioFormats.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(l.noAudioFormats, style: theme.textTheme.bodyMedium),
            ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(_selector),
              icon: const Icon(Icons.check_rounded),
              label: Text(l.download),
            ),
          ),
        ],
      ),
    );
  }
}
