import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_scope.dart';
import 'core/app_info.dart';
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
  Timer? _whatsNewTimer;
  bool _introDone = false;

  @override
  void initState() {
    super.initState();
    if (!widget.showIntro) {
      _schedulePermissionPrompt();
    } else {
      _whatsNewTimer = Timer(const Duration(seconds: 3), _showWhatsNew);
    }
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
    _whatsNewTimer?.cancel();
    super.dispose();
  }

  Future<void> _showWhatsNew() async {
    if (!mounted) return;
    final manager = widget.manager;
    final previous = manager.settings.value.lastSeenVersion;
    if (previous.isNotEmpty && previous == TalosInfo.appVersion) return;
    final l = AppLocalizations.of(context)!;
    final version = TalosInfo.appVersion;
    await manager.settings.mutate(
      (s) => s.copyWith(lastSeenVersion: version),
    );
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.whatsNew),
        content: Text(l.whatsNewBody(version)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l.close),
          ),
          FilledButton(
            onPressed: () {
              unawaited(launchUrl(Uri.parse(
                'https://github.com/nekonaru/talos/releases/tag/v$version',
              )));
              Navigator.of(dialogContext).pop();
            },
            child: Text(l.releaseNotes),
          ),
        ],
      ),
    );
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
