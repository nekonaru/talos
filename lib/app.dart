import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_scope.dart';
import 'core/download_manager.dart';
import 'core/storage_bridge.dart';
import 'core/theme.dart';
import 'gen/app_localizations.dart';
import 'screens/shell.dart';

class TalosApp extends StatefulWidget {
  const TalosApp({super.key, required this.manager});

  final DownloadManager manager;

  @override
  State<TalosApp> createState() => _TalosAppState();
}

class _TalosAppState extends State<TalosApp> {
  Timer? _permissionPromptTimer;

  @override
  void initState() {
    super.initState();
    // Ask for permissions after the first frame settles. Showing the system
    // dialog during cold start makes the watchdog flag the app on slower
    // devices, even when it is working fine in the background.
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
            home: const TalosShell(),
          );
        },
      ),
    );
  }
}
