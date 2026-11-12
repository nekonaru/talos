import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_scope.dart';
import '../core/download_manager.dart';
import '../core/engine/models.dart';
import '../core/format.dart';
import '../core/history_store.dart';
import '../gen/app_localizations.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openFile(String path) async {
    final l = AppLocalizations.of(context)!;
    try {
      final result = await OpenFile.open(path);
      if (result.type != ResultType.done) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.unknownError)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.unknownError)));
      }
    }
  }

  Future<void> _openFolder(String path) async {
    final l = AppLocalizations.of(context)!;
    final parent = File(path).parent.absolute.path;
    if (Platform.isAndroid || Platform.isIOS) {
      await Clipboard.setData(ClipboardData(text: parent));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.copied)));
      }
      return;
    }
    final uri = Uri.directory(parent);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _copyPath(String path) async {
    final l = AppLocalizations.of(context)!;
    await Clipboard.setData(ClipboardData(text: path));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.copied)));
    }
  }

  Future<void> _share(String path) async {
    await SharePlus.instance.share(ShareParams(files: [XFile(path)]));
  }

  Future<void> _deleteFile(BuildContext context, HistoryEntry entry) async {
    final l = AppLocalizations.of(context)!;
    final manager = TalosScope.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.deleteFile),
        content: Text(entry.filePath),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l.delete)),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final file = File(entry.filePath);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Missing file is fine: we still clean up the history row.
    }
    await manager.history.remove(entry.id);
  }

  Future<void> _confirmClearHistory(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final manager = TalosScope.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.clearFinished),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l.clearFinished)),
        ],
      ),
    );
    if (confirmed == true) await manager.history.clear();
  }

  Future<void> _showLog(BuildContext context, DownloadTask task) async {
    final l = AppLocalizations.of(context)!;
    final log = task.log;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: Text(l.taskLog, maxLines: 1, overflow: TextOverflow.ellipsis)),
            TextButton.icon(
              onPressed: () => Clipboard.setData(ClipboardData(text: log.join('\n'))),
              icon: const Icon(Icons.copy, size: 16),
              label: Text(l.copy),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 320,
          child: SingleChildScrollView(
            child: Text(
              log.isEmpty ? l.logEmpty : log.take(200).join('\n'),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
            ),
          ),
        ),
        actions: [
          FilledButton(onPressed: () => Navigator.of(context).pop(), child: Text(l.close)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final manager = TalosScope.of(context);
    final tasks = manager.tasks.where((t) => t.status != TaskStatus.completed).toList();
    final history = manager.history.entries;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.downloads),
        bottom: TabBar(
          controller: _tabController,
          tabs: [Tab(text: l.active), Tab(text: l.finished)],
        ),
        actions: [
          if (history.isNotEmpty)
            IconButton(
              tooltip: l.clearFinished,
              icon: const Icon(Icons.playlist_remove_outlined),
              onPressed: () => _confirmClearHistory(context),
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          if (tasks.isEmpty)
            _EmptyState(hint: l.nothingHereHint)
          else
            ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              itemCount: tasks.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final task = tasks[index];
                return _TaskCard(
                  task: task,
                  onCancel: () => manager.cancel(task),
                  onRetry: () => manager.retry(task),
                  onRemove: () => manager.removeTask(task),
                  onShowLog: () => _showLog(context, task),
                );
              },
            ),
          if (history.isEmpty)
            _EmptyState(hint: l.nothingHereHint)
          else
            ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              itemCount: history.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final entry = history[index];
                return _HistoryCard(
                  entry: entry,
                  onCopyPath: () => _copyPath(entry.filePath),
                  onOpen: () => _openFile(entry.filePath),
                  onFolder: () => _openFolder(entry.filePath),
                  onShare: Platform.isAndroid || Platform.isIOS ? () => _share(entry.filePath) : null,
                  onDelete: () => _deleteFile(context, entry),
                  onRemove: () => manager.history.remove(entry.id),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hint});

  final String hint;

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
            Icon(Icons.inbox_outlined, size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(l.nothingHere, style: theme.textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(hint, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.onCancel,
    required this.onRetry,
    required this.onRemove,
    required this.onShowLog,
  });

  final DownloadTask task;
  final VoidCallback onCancel;
  final VoidCallback onRetry;
  final VoidCallback onRemove;
  final VoidCallback onShowLog;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final running = task.status == TaskStatus.running;
    final queued = task.status == TaskStatus.queued;
    final failed = task.status == TaskStatus.failed;
    final cancelled = task.status == TaskStatus.cancelled;

    final pct = (task.progress * 100).clamp(0, 100);
    final details = <String>[
      if (task.playlistCount != null && task.playlistIndex != null) '${task.playlistIndex}/${task.playlistCount}',
      if (task.speedBytesPerSecond != null && running) formatSpeed(task.speedBytesPerSecond),
      if (task.etaSeconds != null && running) '${l.eta} ${formatEta(task.etaSeconds)}',
      if (task.totalBytes != null) formatBytes(task.totalBytes),
    ].where((s) => s.isNotEmpty).join('  ·  ');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  task.kind == HistoryKind.audio ? Icons.music_note : Icons.movie_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(task.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium),
                ),
                if (running || queued)
                  IconButton(tooltip: l.cancel, icon: const Icon(Icons.close_rounded), onPressed: onCancel),
                if (failed || cancelled) ...[
                  IconButton(tooltip: l.taskLog, icon: const Icon(Icons.description_outlined), onPressed: onShowLog),
                  IconButton(tooltip: l.retry, icon: const Icon(Icons.refresh_rounded), onPressed: onRetry),
                  IconButton(tooltip: l.remove, icon: const Icon(Icons.delete_outline), onPressed: onRemove),
                ],
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: task.progress.clamp(0.0, 1.0),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  failed ? l.failed : cancelled ? l.cancelled : queued ? l.queued : '${pct.toStringAsFixed(pct < 10 && pct > 0 ? 1 : 0)}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: failed ? theme.colorScheme.error : null,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (details.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  Expanded(child: Text(details, style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis)),
                ],
              ],
            ),
            if (failed && task.error != null) ...[
              const SizedBox(height: 6),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: task.error!));
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.copied)));
                },
                child: Text(
                  task.error!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error, decoration: TextDecoration.underline),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.entry,
    required this.onOpen,
    required this.onFolder,
    required this.onCopyPath,
    required this.onShare,
    required this.onDelete,
    required this.onRemove,
  });

  final HistoryEntry entry;
  final VoidCallback onOpen;
  final VoidCallback onFolder;
  final VoidCallback onCopyPath;
  final VoidCallback? onShare;
  final VoidCallback onDelete;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context)!;
    final isDesktop = !Platform.isAndroid && !Platform.isIOS;
    final path = entry.filePath;
    return Card(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          leading: Icon(
            entry.kind == HistoryKind.audio ? Icons.music_note : Icons.movie_outlined,
            color: theme.colorScheme.primary,
          ),
          title: Text(entry.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Text(
                [formatDate(entry.dateMs), formatBytes(entry.sizeBytes)].where((s) => s.isNotEmpty).join('  ·  '),
                style: theme.textTheme.bodySmall,
              ),
              if (path.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  List<String>.from(path.split(Platform.pathSeparator)).reversed.take(3).toList().reversed.join(Platform.pathSeparator),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace', fontSize: 10, color: theme.hintColor),
                ),
              ],
            ],
          ),
          trailing: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'open':
                  onOpen();
                case 'folder':
                  onFolder();
                case 'copyPath':
                  onCopyPath();
                case 'share':
                  onShare?.call();
                case 'delete':
                  onDelete();
                case 'remove':
                  onRemove();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'open', child: Text(l.open)),
              if (isDesktop)
                PopupMenuItem(value: 'folder', child: Text(l.openFolder))
              else
                PopupMenuItem(value: 'copyPath', child: Text(l.copyPath)),
              if (onShare != null) PopupMenuItem(value: 'share', child: Text(l.share)),
              const PopupMenuDivider(),
              PopupMenuItem(value: 'remove', child: Text(l.remove)),
              PopupMenuItem(value: 'delete', child: Text(l.deleteFile)),
            ],
          ),
        ),
      ),
    );
  }
}
