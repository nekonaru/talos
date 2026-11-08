import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_scope.dart';
import '../core/command_template_store.dart';
import '../gen/app_localizations.dart';

class CommandsScreen extends StatefulWidget {
  const CommandsScreen({super.key});

  @override
  State<CommandsScreen> createState() => _CommandsScreenState();
}

class _CommandsScreenState extends State<CommandsScreen> {
  CommandTemplateStore? _store;

  @override
  void initState() {
    super.initState();
    CommandTemplateStore.load().then((store) {
      if (mounted) setState(() => _store = store);
    });
  }

  Future<void> _editTemplate([CommandTemplate? existing]) async {
    final l = AppLocalizations.of(context)!;
    final nameController = TextEditingController(text: existing?.name ?? '');
    final argsController = TextEditingController(text: existing?.args ?? '{url}');
    final result = await showDialog<CommandTemplate>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? l.addCommand : l.edit),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: l.commandName),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: argsController,
              decoration: InputDecoration(labelText: l.commandArgs, hintText: l.commandArgsHint),
              minLines: 2,
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l.cancel)),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              final args = argsController.text.trim();
              if (name.isEmpty || args.isEmpty) return;
              Navigator.of(context).pop(CommandTemplate(
                id: existing?.id ?? DateTime.now().microsecondsSinceEpoch.toRadixString(16),
                name: name,
                args: args,
              ));
            },
            child: Text(l.save),
          ),
        ],
      ),
    );
    if (result == null || _store == null) return;
    if (existing == null) {
      await _store!.add(result);
    } else {
      await _store!.update(result);
    }
    if (mounted) setState(() {});
  }

  Future<void> _runTemplate(CommandTemplate template) async {
    final l = AppLocalizations.of(context)!;
    String initialUrl = '';
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim() ?? '';
      if (text.startsWith('http://') || text.startsWith('https://')) initialUrl = text;
    } catch (_) {
      // Clipboard access is best effort.
    }
    if (!mounted) return;
    final controller = TextEditingController(text: initialUrl);
    final url = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(template.name),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(hintText: l.urlHint),
          onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.of(context).pop(controller.text.trim()), child: Text(l.run)),
        ],
      ),
    );
    if (url == null || url.isEmpty || !mounted) return;
    await _showRunOutput(template, url);
  }

  Future<void> _showRunOutput(CommandTemplate template, String url) async {
    final l = AppLocalizations.of(context)!;
    final manager = TalosScope.of(context);
    final lines = <String>[];
    StreamSubscription<String>? subscription;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          subscription ??= manager.engine.runCustomCommand(template.args, url).listen(
            (line) => setDialogState(() => lines.add(line)),
            onDone: () => setDialogState(() => subscription = null),
          );
          final running = subscription != null;
          return AlertDialog(
            title: Text(template.name),
            content: SizedBox(
              width: double.maxFinite,
              height: 320,
              child: SingleChildScrollView(
                reverse: true,
                child: Text(lines.join('\n'), style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
              ),
            ),
            actions: [
              if (running) const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
              FilledButton(onPressed: running ? null : () => Navigator.of(context).pop(), child: Text(l.close)),
            ],
          );
        },
      ),
    );
    await subscription?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final store = _store;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.commands),
        actions: [
          IconButton(tooltip: l.addCommand, icon: const Icon(Icons.add), onPressed: _editTemplate),
        ],
      ),
      body: store == null
          ? const Center(child: CircularProgressIndicator())
          : store.templates.isEmpty
              ? Center(child: Text(l.commandsHint, style: theme.textTheme.bodyMedium))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  itemCount: store.templates.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final template = store.templates[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.terminal_outlined),
                        title: Text(template.name),
                        subtitle: Text(
                          template.args,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                        ),
                        onTap: () => _editTemplate(template),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: l.run,
                              icon: const Icon(Icons.play_arrow_rounded),
                              onPressed: () => _runTemplate(template),
                            ),
                            IconButton(
                              tooltip: l.delete,
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                await store.remove(template.id);
                                if (mounted) setState(() {});
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
