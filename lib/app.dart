import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_scope.dart';
import 'core/download_manager.dart';
import 'core/theme.dart';
import 'gen/app_localizations.dart';
import 'screens/shell.dart';

class TalosApp extends StatelessWidget {
  const TalosApp({super.key, required this.manager});

  final DownloadManager manager;

  @override
  Widget build(BuildContext context) {
    return TalosScope(
      manager: manager,
      child: ListenableBuilder(
        listenable: manager.settings,
        builder: (context, _) {
          final settings = manager.settings.value;
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
