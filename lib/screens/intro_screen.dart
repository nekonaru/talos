import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_info.dart';
import '../core/theme.dart';
import '../gen/app_localizations.dart';

/// First frame after the native splash. The native splash is static and
/// instant; this screen bridges it into the app with a short, interruptible
/// brand reveal. Only transform and opacity are animated, so it stays smooth
/// while the engine finishes booting on the main isolate.
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> with TickerProviderStateMixin {
  late final AnimationController _entrance;
  late final AnimationController _exit;
  late final Animation<double> _markFade;
  late final Animation<double> _markScale;
  late final Animation<double> _haloScale;
  late final Animation<double> _haloOpacity;
  late final Animation<double> _wordFade;
  late final Animation<Offset> _wordSlide;
  late final Animation<double> _taglineFade;
  late final Animation<double> _progress;

  Timer? _timer;
  late final bool _reducedMotion;
  bool _exiting = false;

  @override
  void initState() {
    super.initState();
    // Read the setting before starting the animation. didChangeDependencies
    // runs after initState, which would be too late to gate the entrance.
    _reducedMotion =
        WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;
    _entrance = AnimationController(vsync: this, duration: TalosMotion.introEntrance);
    _exit = AnimationController(vsync: this, duration: TalosMotion.introExit);

    _markFade = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.0, 0.40, curve: Curves.easeOut),
    );
    _markScale = Tween<double>(begin: 0.92, end: 1).animate(
      CurvedAnimation(parent: _entrance, curve: const Interval(0.0, 0.55, curve: TalosMotion.entering)),
    );
    _haloScale = Tween<double>(begin: 0.85, end: 1.18).animate(
      CurvedAnimation(parent: _entrance, curve: const Interval(0.05, 0.70, curve: Curves.linear)),
    );
    _haloOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 0.16), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 0.16, end: 0), weight: 65),
    ]).animate(
      CurvedAnimation(parent: _entrance, curve: const Interval(0.05, 0.70, curve: Curves.linear)),
    );
    _wordFade = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.18, 0.62, curve: Curves.easeOut),
    );
    _wordSlide = Tween<Offset>(begin: const Offset(0, 12), end: Offset.zero).animate(
      CurvedAnimation(parent: _entrance, curve: const Interval(0.18, 0.62, curve: TalosMotion.entering)),
    );
    _taglineFade = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.32, 0.75, curve: Curves.easeOut),
    );
    _progress = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.05, 1.0, curve: Curves.linear),
    );

    if (_reducedMotion) {
      _entrance.value = 1;
      _timer = Timer(const Duration(milliseconds: 400), _finish);
    } else {
      unawaited(_entrance.forward());
      _timer = Timer(TalosMotion.introEntrance + TalosMotion.introHold, _beginExit);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _entrance.dispose();
    _exit.dispose();
    super.dispose();
  }

  void _finish() {
    if (mounted) widget.onDone();
  }

  void _beginExit() {
    if (_exiting) return;
    _exiting = true;
    _timer?.cancel();
    if (_reducedMotion) {
      _finish();
      return;
    }
    unawaited(_exit.forward().then((_) => _finish()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final accent = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _beginExit,
        child: SafeArea(
          child: AnimatedBuilder(
            animation: Listenable.merge([_entrance, _exit]),
            builder: (context, _) {
              final exit = _exit.value;
              return Opacity(
                opacity: 1 - exit,
                child: Transform.scale(
                  scale: 1 + exit * 0.02,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 180,
                          height: 180,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Opacity(
                                opacity: _reducedMotion ? 0 : _haloOpacity.value,
                                child: Transform.scale(
                                  scale: _reducedMotion ? 1 : _haloScale.value,
                                  child: Container(
                                    width: 176,
                                    height: 176,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: accent.withValues(alpha: 0.35),
                                    ),
                                  ),
                                ),
                              ),
                              Opacity(
                                opacity: _reducedMotion ? 1 : _markFade.value,
                                child: Transform.scale(
                                  scale: _reducedMotion ? 1 : _markScale.value,
                                  child: Image.asset(
                                    'assets/talos-mark.png',
                                    width: 132,
                                    height: 132,
                                    filterQuality: FilterQuality.high,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Opacity(
                          opacity: _reducedMotion ? 1 : _wordFade.value,
                          child: Transform.translate(
                            offset: _reducedMotion ? Offset.zero : _wordSlide.value,
                            child: Text(
                              TalosInfo.appName.toUpperCase(),
                              style: theme.textTheme.displaySmall?.copyWith(letterSpacing: 10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Opacity(
                          opacity: _reducedMotion ? 1 : _taglineFade.value,
                          child: Text(
                            TalosInfo.tagline.toUpperCase(),
                            style: theme.textTheme.bodySmall?.copyWith(letterSpacing: 2),
                          ),
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: 180,
                          child: Transform.scale(
                            scaleX: _reducedMotion ? 1 : _progress.value,
                            alignment: Alignment.centerLeft,
                            child: Container(
                              height: 2,
                              decoration: BoxDecoration(
                                color: accent,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Opacity(
                          opacity: _reducedMotion ? 1 : _taglineFade.value,
                          child: Text(l.tapToSkip, style: theme.textTheme.bodySmall),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
