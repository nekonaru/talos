import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_scope.dart';
import 'core/download_manager.dart';
import 'core/storage_bridge.dart';
import 'core/theme.dart';
import 'gen/app_localizations.dart';
import 'screens/intro_screen.dart';
import 'screens/shell.dart';

class TalosApp extends StatefulWidget {
  const TalosApp({super.key, required this.manager, this.showIntro = true});

  final DownloadManager manager;

  /// Widget tests boot straight into the shell; real launches show the intro.
  final bool showIntro;

  @override
  State<TalosApp> createState() => _TalosAppState();
}

class _TalosAppState extends State<TalosApp> {
  Timer? _permissionPromptTimer;
  bool _introDone = false;

  @override
  void initState() {
    super.initState();
    if (!widget.showIntro) _schedulePermissionPrompt();
  }

  void _onIntroDone() {
    setState(() => _introDone = true);
    _schedulePermissionPrompt();
  }

  void _schedulePermissionPrompt() {
    // Ask after the intro settles. Showing the system dialog during cold start
    // makes the watchdog flag the app on slower devices, even when it is
    // working fine in the background.
    _permissionPromptTimer?.cancel();
    _permissionPromptTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      unawaited(_promptPermissions());
    });
  }

  @override
  void dispose() {
    _permissionPromptTimer?.cancel();
    super.dispose();
  }

  Future<void> _promptPermissions() async {
    if (!mounted) return;
    try {
      await TalosStorageBridge.requestFirstLaunchPermissions();
    } catch (_) {
      // Best effort; notifications and downloads work either way.
    }
  }

  @override
  Widget build(BuildContext context) {
    return TalosScope(
      manager: widget.manager,
      child: ListenableBuilder(
        listenable: widget.manager.settings,
        builder: (context, _) {
          final settings = widget.manager.settings.value;
          return MaterialApp(
            title: 'Talos',
            debugShowCheckedModeBanner: false,
            theme: TalosTheme.build(brightness: Brightness.light, accent: settings.accentValue),
            darkTheme: TalosTheme.build(brightness: Brightness.dark, accent: settings.accentValue),
            themeMode: settings.theme,
            supportedLocales: const [Locale('en'), Locale('id')],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) => MediaQuery.withClampedTextScaling(
              minScaleFactor: 0.85,
              maxScaleFactor: 2.0,
              child: child ?? const SizedBox.shrink(),
            ),
            home: !widget.showIntro || _introDone
                ? const TalosShell()
                : IntroScreen(onDone: _onIntroDone),
          );
        },
      ),
    );
  }
}
