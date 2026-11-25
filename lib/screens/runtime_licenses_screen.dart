import 'package:flutter/material.dart';

import '../gen/app_localizations.dart';
import '../widgets/section_label.dart';

/// Explicit inventory of the components that actually run inside Talos.
/// Flutter's license page covers Dart packages; this screen documents the
/// downloaded and natively linked engine pieces as well.
class RuntimeLicensesScreen extends StatelessWidget {
  const RuntimeLicensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final entries = <(String, String)>[
      (l.licenseTalos, l.licenseTalosDetail),
      (l.licenseYtdlp, l.licenseYtdlpDetail),
      (l.licenseChaquopy, l.licenseChaquopyDetail),
      (l.licenseFfmpegKit, l.licenseFfmpegKitDetail),
      (l.licenseDesktopEngine, l.licenseDesktopEngineDetail),
      (l.licenseDesktopFfmpeg, l.licenseDesktopFfmpegDetail),
      (l.licenseDartPackages, l.licenseDartPackagesDetail),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l.runtimeLicenses)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Text(l.runtimeLicensesIntro, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 20),
          SectionLabel(l.runtimeComponents),
          for (final (title, detail) in entries)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(detail, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
