import 'package:flutter/material.dart';

import '../gen/app_localizations.dart';

/// Short, offline help for the questions users ask most often.
class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final entries = <(String, String)>[
      (l.faqQ1, l.faqA1),
      (l.faqQ2, l.faqA2),
      (l.faqQ3, l.faqA3),
      (l.faqQ4, l.faqA4),
      (l.faqQ5, l.faqA5),
      (l.faqQ6, l.faqA6),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l.faq)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
        children: [
          for (final (question, answer) in entries)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ExpansionTile(
                title: Text(question),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(answer),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
