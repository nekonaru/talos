import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_info.dart';
import '../gen/app_localizations.dart';
import '../widgets/section_label.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _open(BuildContext context, String url) async {
    final l = AppLocalizations.of(context)!;
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.unknownError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final chips = <(String, String)>[
      ('yt-dlp', 'Unlicense'),
      ('FFmpegKit (Android)', 'LGPL-3.0'),
      ('aria2', 'GPL-2.0'),
      ('Flutter', 'BSD-3-Clause'),
      ('Chaquopy (Android)', 'MIT'),
      ('Marcellus, Inter', 'SIL Open Font License'),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l.about)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          Text(
            TalosInfo.appName.toUpperCase(),
            style: theme.textTheme.displaySmall?.copyWith(letterSpacing: 10),
          ),
          const SizedBox(height: 4),
          Text(TalosInfo.tagline.toUpperCase(), style: theme.textTheme.bodySmall?.copyWith(letterSpacing: 3.2)),
          const SizedBox(height: 16),
          Container(height: 2, width: 56, color: theme.colorScheme.primary),
          const SizedBox(height: 24),
          Text('${l.version} ${TalosInfo.appVersion} (${TalosInfo.buildNumber})', style: theme.textTheme.bodyLarge),
          const SizedBox(height: 4),
          Text('${l.licenses}: ${TalosInfo.license}', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 24),
          FilledButton.tonalIcon(
            onPressed: () => _open(context, TalosInfo.sourceUrl),
            icon: const Icon(Icons.code_rounded),
            label: Text(l.sourceCode),
          ),
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            onPressed: () => _open(context, TalosInfo.issuesUrl),
            icon: const Icon(Icons.bug_report_outlined),
            label: Text(l.reportIssue),
          ),
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            onPressed: () => showLicensePage(
              context: context,
              applicationName: TalosInfo.appName,
              applicationVersion: TalosInfo.appVersion,
              applicationLegalese: 'Talos is MIT licensed. Bundled components and tools used at runtime carry their own licenses.',
            ),
            icon: const Icon(Icons.article_outlined),
            label: Text(l.licenses),
          ),
          SectionLabel(l.author),
          Card(
            child: ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(TalosInfo.authorName),
              subtitle: Text('@${TalosInfo.authorHandle} on GitHub'),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () => _open(context, TalosInfo.authorUrl),
            ),
          ),
          SectionLabel(l.support),
          for (final (name, url) in TalosInfo.sponsors)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.favorite_border_rounded),
                title: Text(name),
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: () => _open(context, url),
              ),
            ),
          SectionLabel(l.specialThanks),
          for (final (name, license) in chips)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(name),
              trailing: Text(license, style: theme.textTheme.bodySmall),
            ),
        ],
      ),
    );
  }
}
