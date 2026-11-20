import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:video_player/video_player.dart';

import '../core/history_store.dart';
import '../core/storage_bridge.dart';
import '../gen/app_localizations.dart';

/// In-app player for finished downloads. Works for both video and audio.
///
/// File paths are played directly. Android content URIs are passed to the
/// platform player as well. When the built-in player cannot open the file,
/// the user can still hand off to the system player with one tap.
class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key, required this.entry});

  final HistoryEntry entry;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  VideoPlayerController? _controller;
  Object? _error;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    unawaited(_open());
  }

  Future<void> _open() async {
    final path = widget.entry.filePath;
    if (path.isEmpty) {
      setState(() => _error = Exception('empty'));
      return;
    }
    try {
      VideoPlayerController controller;
      if (path.startsWith('content://')) {
        controller = VideoPlayerController.contentUri(Uri.parse(path));
      } else {
        controller = VideoPlayerController.file(File(path));
      }
      await controller.initialize();
      await controller.play();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _ready = true;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _openExternally() async {
    final path = widget.entry.filePath;
    if (Platform.isAndroid && path.startsWith('content://')) {
      await TalosStorageBridge.openUri(path);
      return;
    }
    if (Platform.isAndroid || Platform.isIOS) {
      final result = await OpenFile.open(path);
      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.unknownError)),
        );
      }
      return;
    }
    // Desktop: open_file works for local paths too.
    final result = await OpenFile.open(path);
    if (result.type != ResultType.done && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.unknownError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget body;
    if (_error != null) {
      body = _PlayerError(onOpenExternally: _openExternally);
    } else if (!_ready) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      final controller = _controller!;
      final isAudio = widget.entry.kind == HistoryKind.audio;
      body = Container(
        color: Colors.black,
        constraints: const BoxConstraints.expand(),
        child: Column(
          children: [
            Expanded(
              child: isAudio
                  ? _AudioView(entry: widget.entry, controller: controller)
                  : Center(
                      child: AspectRatio(
                        aspectRatio: controller.value.aspectRatio == 0 ? 16 / 9 : controller.value.aspectRatio,
                        child: VideoPlayer(controller),
                      ),
                    ),
            ),
            _PlayerControls(controller: controller, title: widget.entry.title),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: _error == null ? Colors.black : theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: _error == null ? Colors.black : null,
        foregroundColor: _error == null ? Colors.white : null,
        title: Text(
          widget.entry.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: body,
    );
  }
}

class _AudioView extends StatelessWidget {
  const _AudioView({required this.entry, required this.controller});

  final HistoryEntry entry;
  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Artwork(
            url: entry.thumbnailUrl,
            icon: Icons.music_note,
            size: 180,
            iconColor: theme.colorScheme.primary,
          ),
          const SizedBox(height: 28),
          Text(
            entry.title,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
          ),
          if (entry.uploader != null && entry.uploader!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              entry.uploader!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }
}

/// Rounded square artwork with network image or a music note fallback.
class _Artwork extends StatelessWidget {
  const _Artwork({
    required this.url,
    required this.icon,
    required this.size,
    this.iconColor,
  });

  final String? url;
  final IconData icon;
  final double size;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(18);
    final fallback = Container(
      padding: EdgeInsets.all(size * 0.2),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: borderRadius,
      ),
      child: Icon(icon, size: size * 0.55, color: iconColor ?? Colors.white70),
    );
    if (url == null || url!.isEmpty) return fallback;
    return ClipRRect(
      borderRadius: borderRadius,
      child: Image.network(
        url!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}

class _PlayerError extends StatelessWidget {
  const _PlayerError({required this.onOpenExternally});

  final VoidCallback onOpenExternally;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image_outlined, size: 56, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(l.playerNotSupported, textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onOpenExternally,
              icon: const Icon(Icons.open_in_new),
              label: Text(l.openWithSystemPlayer),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerControls extends StatefulWidget {
  const _PlayerControls({required this.controller, required this.title});

  final VideoPlayerController controller;
  final String title;

  @override
  State<_PlayerControls> createState() => _PlayerControlsState();
}

class _PlayerControlsState extends State<_PlayerControls> {
  late VideoPlayerController _controller = widget.controller;
  bool _wasPlaying = false;
  bool _dragging = false;
  double _dragValue = 0;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_tick);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void didUpdateWidget(covariant _PlayerControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _controller.removeListener(_tick);
      _controller = widget.controller;
      _controller.addListener(_tick);
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _controller.removeListener(_tick);
    super.dispose();
  }

  void _tick() {
    if (mounted) setState(() {});
  }

  void _toggle() {
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
  }

  void _skip(Duration delta) {
    final value = _controller.value;
    final target = value.position + delta;
    _controller.seekTo(
      target < Duration.zero ? Duration.zero : (target > value.duration ? value.duration : target),
    );
  }

  static String _label(Duration d) {
    final total = d.inSeconds;
    final mm = (total ~/ 60).toString().padLeft(2, '0');
    final ss = (total % 60).toString().padLeft(2, '0');
    final hh = total ~/ 3600;
    return hh > 0 ? '$hh:$mm:$ss' : '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final value = _controller.value;
    final total = value.duration.inMilliseconds;
    final position = value.position.inMilliseconds;
    final fraction = total > 0 ? (position / total).clamp(0.0, 1.0) : 0.0;
    final seeking = _dragging ? _dragValue : fraction;

    return Container(
      color: Colors.black,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: SliderComponentShape.noOverlay,
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white24,
              thumbColor: Colors.white,
            ),
            child: Slider(
              value: seeking,
              onChangeStart: (v) {
                _wasPlaying = value.isPlaying;
                if (value.isPlaying) _controller.pause();
                _dragging = true;
              },
              onChanged: (v) {
                _dragValue = v;
                setState(() {});
              },
              onChangeEnd: (v) {
                if (total > 0) {
                  _controller.seekTo(Duration(milliseconds: (v * total).round()));
                }
                if (_wasPlaying) _controller.play();
                _dragging = false;
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_label(_dragging ? Duration(milliseconds: (_dragValue * total).round()) : value.position),
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
              Text(_label(value.duration), style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: l.skipBack,
                icon: const Icon(Icons.replay_10_rounded, color: Colors.white, size: 32),
                onPressed: () => _skip(const Duration(seconds: -10)),
              ),
              const SizedBox(width: 16),
              FloatingActionButton.small(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                onPressed: _toggle,
                child: Icon(value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 28),
              ),
              const SizedBox(width: 16),
              IconButton(
                tooltip: l.skipForward,
                icon: const Icon(Icons.forward_30_rounded, color: Colors.white, size: 32),
                onPressed: () => _skip(const Duration(seconds: 30)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
