import 'dart:async';
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
import '../core/storage_bridge.dart';
import '../gen/app_localizations.dart';
import 'configure_screen.dart';
import 'error_message.dart';
import 'player_screen.dart';

/// Resolves stable error codes from the download engine to localized text.
/// Unknown values are returned unchanged (raw engine messages).
String _resolveTaskError(AppLocalizations l, String code) {
  switch (code) {
    case kErrSafNotWritable:
      return l.errSafNotWritable;
    case kErrSaveToDownloads:
      return l.errSaveToDownloads;
    default:
      return code;
  }
}

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key, this.onGoHome});

  /// Switches back to the Home tab. Only wired up on the narrow layout.
  final VoidCallback? onGoHome;

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();
  String _query = '';

  bool _showFavorites = false;
  String _finishedSort = 'newest';
  String? _finishedCacheKey;
  List<HistoryEntry>? _finishedCache;
  String _kindFilter = 'all';
  final Set<String> _selectedIds = <String>{};
  bool _selectionMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _searchController.addListener(_onSearchChanged);
  }

  void _onTabChanged() {
    if (!mounted || _tabController.indexIsChanging) return;
    // Selection only belongs to the Finished tab. Leaving it clears the
    // stale selection so returning later starts fresh. Avoid rebuilding the
    // whole list on duplicate notifications that did not change the tab.
    if (_tabController.index != 1 && _selectionMode) {
      setState(() {
        _selectionMode = false;
        _selectedIds.clear();
      });
    }
  }

  void _onSearchChanged() {
    final value = _searchController.text.trim().toLowerCase();
    if (value != _query && mounted) {
      setState(() {
        _query = value;
        // A filter change can hide selected rows. Clear selection so a later
        // delete can never act on entries the user can no longer see.
        _selectionMode = false;
        _selectedIds.clear();
      });
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openFolder(String path) async {
    final l = AppLocalizations.of(context)!;
    if (Platform.isAndroid || Platform.isIOS) {
      if (path.startsWith('content://')) {
        // The path is a content URI, not a filesystem path; copy the URI
        // itself so the user can paste it into a file manager that
        // understands it. Otherwise copy the parent folder.
        await Clipboard.setData(ClipboardData(text: path));
      } else {
        await Clipboard.setData(ClipboardData(text: File(path).parent.absolute.path));
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.copied)));
      }
      return;
    }
    final uri = Uri.directory(File(path).parent.absolute.path);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Background it silently: the OSes the user runs this on already have
      // intent handlers for file:// URLs.
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
    final l = AppLocalizations.of(context)!;
    if (Platform.isAndroid && path.startsWith('content://')) {
      final ok = await TalosStorageBridge.shareUri(path);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.shareFailed)));
      }
      return;
    }
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
    final deleted = await TalosStorageBridge.deleteDownloadedFile(entry.filePath);
    if (!deleted) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.deleteSelectedFailed)),
        );
      }
      // Keep the history row so the user can retry and the file is not orphaned.
      return;
    }
    await manager.history.remove(entry.id);
  }

  Future<void> _confirmClearQueued(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final manager = TalosScope.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.clearQueued),
        content: Text(l.clearQueuedBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l.clearQueued),
          ),
        ],
      ),
    );
    if (confirmed == true) await manager.clearQueued();
  }

  Future<void> _confirmClearHistory(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final manager = TalosScope.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.clearFinished),
        content: Text(l.clearFinishedBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l.clearFinished)),
        ],
      ),
    );
    if (confirmed == true) await manager.history.clear();
  }

  void _enterSelection(String id) {
    setState(() {
      _selectionMode = true;
      _selectedIds
        ..clear()
        ..add(id);
    });
  }

  void _exitSelection() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
      if (_selectedIds.isEmpty) _selectionMode = false;
    });
  }

  void _toggleSelectAll(List<HistoryEntry> entries) {
    setState(() {
      final allSelected = entries.isNotEmpty && entries.every((e) => _selectedIds.contains(e.id));
      if (allSelected) {
        _selectedIds.clear();
        _selectionMode = false;
      } else {
        _selectedIds
          ..clear()
          ..addAll(entries.map((e) => e.id));
        if (entries.isNotEmpty) _selectionMode = true;
      }
    });
  }

  Future<void> _deleteSelected(BuildContext context, List<HistoryEntry> entries) async {
    final l = AppLocalizations.of(context)!;
    final manager = TalosScope.of(context);
    final selected = entries.where((e) => _selectedIds.contains(e.id)).toList();
    if (selected.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.deleteSelected),
        content: Text(l.deleteSelectedConfirm(selected.length)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l.delete)),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final removed = <String>[];
    for (final entry in selected) {
      if (await TalosStorageBridge.deleteDownloadedFile(entry.filePath)) {
        removed.add(entry.id);
      }
    }
    await manager.history.removeMany(removed);
    if (!mounted || !context.mounted) return;
    _exitSelection();
    if (removed.length != selected.length) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.deleteSelectedFailed)));
    }
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

  List<HistoryEntry> _buildFinished(List<HistoryEntry> history, String cacheKey) {
    final favoritesOnly = _showFavorites
        ? history.where((e) => e.favorite).toList()
        : history.toList();
    final sorted = sortedHistory(favoritesOnly, _finishedSort);
    final typeFiltered = _kindFilter == 'all'
        ? sorted
        : sorted.where((e) => e.kind.name == _kindFilter).toList();
    final result = _query.isEmpty
        ? typeFiltered
        : typeFiltered
            .where((e) =>
                e.title.toLowerCase().contains(_query) ||
                e.url.toLowerCase().contains(_query) ||
                (e.uploader ?? '').toLowerCase().contains(_query))
            .toList();
    _finishedCacheKey = cacheKey;
    _finishedCache = result;
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final manager = TalosScope.of(context);
    final tasks = manager.tasks.where((t) => t.status != TaskStatus.completed).toList();
    final history = manager.history.entries;
    // This screen rebuilds on every throttled progress tick. Sorting up to 300
    // history rows each time is wasted work, so cache by store revision and
    // the active filter values.
    final cacheKey = '${manager.history.revision}|$_query|$_finishedSort|$_kindFilter|$_showFavorites';
    final finished = _finishedCacheKey == cacheKey && _finishedCache != null
        ? _finishedCache!
        : _buildFinished(history, cacheKey);
    final selectedCount = finished.where((e) => _selectedIds.contains(e.id)).length;

    return PopScope(
      canPop: !_selectionMode,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _selectionMode) _exitSelection();
      },
      child: Scaffold(
      appBar: _selectionMode && _tabController.index == 1
          ? AppBar(
              leading: IconButton(
                tooltip: l.cancel,
                icon: const Icon(Icons.close),
                onPressed: _exitSelection,
              ),
              title: Text(l.selectedCount(selectedCount)),
              actions: [
                IconButton(
                  tooltip: l.selectAll,
                  icon: const Icon(Icons.select_all),
                  onPressed: () => _toggleSelectAll(finished),
                ),
                IconButton(
                  tooltip: l.deleteSelected,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: selectedCount == 0 ? null : () => _deleteSelected(context, finished),
                ),
              ],
            )
          : AppBar(
              title: Text(l.downloads),
              bottom: TabBar(
                controller: _tabController,
                tabs: [Tab(text: l.active), Tab(text: l.finished)],
              ),
              actions: [
                IconButton(
                  tooltip: manager.settings.value.queuePaused ? l.resumeQueue : l.pauseQueue,
                  icon: Icon(manager.settings.value.queuePaused
                      ? Icons.play_arrow_rounded
                      : Icons.pause_rounded),
                  onPressed: () => unawaited(
                    manager.setQueuePaused(!manager.settings.value.queuePaused),
                  ),
                ),
                if (tasks.any((t) => t.status == TaskStatus.queued))
                  IconButton(
                    tooltip: l.clearQueued,
                    icon: const Icon(Icons.playlist_remove_outlined),
                    onPressed: () => _confirmClearQueued(context),
                  ),
                if (history.isNotEmpty)
                  IconButton(
                    tooltip: l.clearFinished,
                    icon: const Icon(Icons.delete_sweep_outlined),
                    onPressed: () => _confirmClearHistory(context),
                  ),
              ],
            ),
      body: Column(
        children: [
          if (_tabController.index == 0)
            Builder(builder: (context) {
              final retryable = tasks.where((t) => t.status == TaskStatus.failed || t.status == TaskStatus.cancelled).toList();
              if (retryable.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () {
                      for (final task in retryable) {
                        unawaited(manager.retry(task));
                      }
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(l.retryAll),
                  ),
                ),
              );
            }),
          if (_tabController.index == 0)
            Builder(builder: (context) {
              const waitingStages = {
                'queuePaused', 'waitingForWifi', 'batteryLow', 'quietHours',
              };
              final waiting = tasks
                  .where((t) => waitingStages.contains(t.stage))
                  .map((t) => t.stage)
                  .toList();
              if (waiting.isEmpty) return const SizedBox.shrink();
              final reason = switch (waiting.first) {
                'queuePaused' => l.waitingPaused,
                'waitingForWifi' => l.waitingWifi,
                'batteryLow' => l.waitingBattery,
                'quietHours' => l.waitingQuiet,
                _ => l.queueWaiting,
              };
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 18,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 10),
                      Expanded(child: Text(reason,
                          style: Theme.of(context).textTheme.bodySmall)),
                    ],
                  ),
                ),
              );
            }),
          if (_tabController.index == 1) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: l.searchFinishedHint,
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: Row(
                children: [
                  FilterChip(
                    avatar: Icon(
                      _showFavorites ? Icons.star_rounded : Icons.star_border_rounded,
                      size: 18,
                    ),
                    label: Text(l.favorite),
                    selected: _showFavorites,
                    showCheckmark: false,
                    onSelected: (value) {
                      setState(() {
                        _showFavorites = value;
                        _selectionMode = false;
                        _selectedIds.clear();
                      });
                    },
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    tooltip: l.filterByType,
                    icon: Icon(
                      Icons.filter_list,
                      color: _kindFilter == 'all' ? null : Theme.of(context).colorScheme.primary,
                    ),
                    onSelected: (value) {
                      setState(() {
                        _kindFilter = value;
                        _selectionMode = false;
                        _selectedIds.clear();
                      });
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(value: 'all', child: Text(l.filterAll)),
                      PopupMenuItem(value: 'video', child: Text(l.filterVideo)),
                      PopupMenuItem(value: 'audio', child: Text(l.filterAudio)),
                    ],
                  ),
                  PopupMenuButton<String>(
                    tooltip: l.sortBy,
                    icon: const Icon(Icons.sort),
                    onSelected: (value) {
                      setState(() {
                        _finishedSort = value;
                      });
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(value: 'newest', child: Text(l.sortNewest)),
                      PopupMenuItem(value: 'oldest', child: Text(l.sortOldest)),
                      PopupMenuItem(value: 'largest', child: Text(l.sortLargest)),
                      PopupMenuItem(value: 'smallest', child: Text(l.sortSmallest)),
                      PopupMenuItem(value: 'title', child: Text(l.sortTitleAToZ)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
          ],
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                if (tasks.isEmpty)
                  _EmptyState(hint: l.nothingHereHint, onGoHome: widget.onGoHome)
                else
                  ReorderableListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    itemCount: tasks.length,
                    onReorderItem: (oldIndex, newIndex) {
                      manager.reorder(oldIndex, newIndex);
                    },
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return _TaskCard(
                        key: ValueKey(task.id),
                        dragIndex: index,
                        task: task,
                        onCancel: () => manager.cancel(task),
                        onRetry: () => manager.retry(task),
                        onRemove: () => manager.removeTask(task),
                        onShowLog: () => _showLog(context, task),
                        onCopyUrl: () async {
                          await Clipboard.setData(ClipboardData(text: task.url));
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l.linkCopied)),
                          );
                        },
                      );
                    },
                  ),
                if (history.isEmpty)
                  _EmptyState(hint: l.nothingHereHint, onGoHome: widget.onGoHome)
                else if (finished.isEmpty)
                  _EmptyState(
                    hint: _showFavorites ? l.noFavoritesYet : l.searchFinishedHint,
                    onGoHome: null,
                  )
                else
                  ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    itemCount: finished.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final entry = finished[index];
                      return _HistoryCard(
                        entry: entry,
                        selectionMode: _selectionMode,
                        selected: _selectedIds.contains(entry.id),
                        onToggleSelection: () => _toggleSelection(entry.id),
                        onLongPress: () => _enterSelection(entry.id),
                        onCopyPath: () => _copyPath(entry.filePath),
                        onOpen: () => _openEntry(context, entry),
                        onOpenExternal: () => _openWithSystem(entry.filePath),
                        onToggleFavorite: () => unawaited(manager.history.toggleFavorite(entry.id)),
                        onFolder: () => _openFolder(entry.filePath),
                        onShare: Platform.isAndroid || Platform.isIOS ? () => _share(entry.filePath) : null,
                        onDownloadAgain: () => unawaited(_downloadAgain(context, entry)),
                        onDelete: () => _deleteFile(context, entry),
                        onRemove: () => unawaited(manager.history.remove(entry.id)),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  /// Probes the stored URL again and opens Configure with fresh media info,
  /// so the user can change settings before re-downloading a finished item.
  Future<void> _downloadAgain(BuildContext context, HistoryEntry entry) async {
    if (entry.url.isEmpty) return;
    final manager = TalosScope.of(context);
    try {
      final probe = await manager.engine.probe(entry.url, proxy: manager.settings.value.proxy);
      if (!context.mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ConfigureScreen(probe: probe)),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyError(context, error))),
      );
    }
  }

  Future<void> _openEntry(BuildContext context, HistoryEntry entry) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PlayerScreen(entry: entry)),
    );
  }

  Future<void> _openWithSystem(String path) async {
    final l = AppLocalizations.of(context)!;
    if (Platform.isAndroid && path.startsWith('content://')) {
      final ok = await TalosStorageBridge.openUri(path);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.unknownError)));
      }
      return;
    }
    try {
      final result = await OpenFile.open(path);
      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.unknownError)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.unknownError)));
      }
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hint, this.onGoHome});

  final String hint;
  final VoidCallback? onGoHome;

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
            const SizedBox(height: 8),
            Text(hint, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
            if (onGoHome != null) ...[
              const SizedBox(height: 24),
              FilledButton.tonalIcon(
                onPressed: onGoHome,
                icon: const Icon(Icons.travel_explore_outlined),
                label: Text(l.goHome),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    super.key,
    required this.task,
    required this.dragIndex,
    required this.onCancel,
    required this.onRetry,
    required this.onRemove,
    required this.onShowLog,
    required this.onCopyUrl,
  });

  final DownloadTask task;
  final int? dragIndex;
  final VoidCallback onCancel;
  final VoidCallback onRetry;
  final VoidCallback onRemove;
  final VoidCallback onShowLog;
  final VoidCallback onCopyUrl;

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
                IconButton(tooltip: l.taskLog, icon: const Icon(Icons.description_outlined), onPressed: onShowLog),
                IconButton(tooltip: l.copyUrl, icon: const Icon(Icons.link_outlined), onPressed: onCopyUrl),
                if (running || queued)
                  IconButton(tooltip: l.cancel, icon: const Icon(Icons.close_rounded), onPressed: onCancel),
                if (queued && dragIndex != null)
                  ReorderableDragStartListener(
                    index: dragIndex!,
                    enabled: true,
                    child: Tooltip(
                      message: l.dragToReorder,
                      child: Semantics(
                        label: l.dragToReorder,
                        child: const SizedBox(
                          width: 48,
                          height: 48,
                          child: Center(child: Icon(Icons.drag_handle, size: 24)),
                        ),
                      ),
                    ),
                  ),
                if (failed || cancelled) ...[
                  IconButton(tooltip: l.retry, icon: const Icon(Icons.refresh_rounded), onPressed: onRetry),
                  IconButton(tooltip: l.remove, icon: const Icon(Icons.delete_outline), onPressed: onRemove),
                ],
              ],
            ),
            const SizedBox(height: 12),
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
              const SizedBox(height: 8),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: _resolveTaskError(l, task.error!)));
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.copied)));
                },
                child: Text(
                  _resolveTaskError(l, task.error!),
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
    required this.selectionMode,
    required this.selected,
    required this.onToggleSelection,
    required this.onLongPress,
    required this.onOpen,
    required this.onOpenExternal,
    required this.onToggleFavorite,
    required this.onFolder,
    required this.onCopyPath,
    required this.onShare,
    required this.onDownloadAgain,
    required this.onDelete,
    required this.onRemove,
  });

  final HistoryEntry entry;
  final bool selectionMode;
  final bool selected;
  final VoidCallback onToggleSelection;
  final VoidCallback onLongPress;
  final VoidCallback onOpen;
  final VoidCallback onOpenExternal;
  final VoidCallback onToggleFavorite;
  final VoidCallback onFolder;
  final VoidCallback onCopyPath;
  final VoidCallback? onShare;
  final VoidCallback onDownloadAgain;
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
        onTap: selectionMode ? onToggleSelection : onOpen,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          leading: selectionMode
              ? _SelectionLeading(selected: selected)
              : _ThumbnailLeading(entry: entry),
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
                  path.startsWith('content://')
                      ? '${l.safFolder} ${Uri.tryParse(path)?.host ?? path.split('/').last}'
                      : List<String>.from(path.split(Platform.pathSeparator)).reversed.take(3).toList().reversed.join(Platform.pathSeparator),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace', fontSize: 10),
                ),
              ],
            ],
          ),
          trailing: selectionMode
              ? const SizedBox.shrink()
              : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: entry.favorite ? l.favoriteRemove : l.favoriteAdd,
                icon: Icon(
                  entry.favorite ? Icons.star_rounded : Icons.star_border_rounded,
                  color: entry.favorite ? theme.colorScheme.primary : null,
                ),
                onPressed: onToggleFavorite,
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  switch (value) {
                    case 'open':
                      onOpen();
                    case 'openExternal':
                      onOpenExternal();
                    case 'folder':
                      onFolder();
                    case 'copyPath':
                      onCopyPath();
                    case 'share':
                      onShare?.call();
                    case 'again':
                      onDownloadAgain();
                    case 'delete':
                      onDelete();
                    case 'remove':
                      onRemove();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'open', child: Text(l.open)),
                  PopupMenuItem(value: 'openExternal', child: Text(l.openWithSystemPlayer)),
                  if (isDesktop)
                    PopupMenuItem(value: 'folder', child: Text(l.openFolder))
                  else
                    PopupMenuItem(value: 'copyPath', child: Text(l.copyPath)),
                  if (onShare != null) PopupMenuItem(value: 'share', child: Text(l.share)),
                  PopupMenuItem(value: 'again', child: Text(l.downloadAgain)),
                  const PopupMenuDivider(),
                  PopupMenuItem(value: 'remove', child: Text(l.remove)),
                  PopupMenuItem(value: 'delete', child: Text(l.deleteFile)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class _SelectionLeading extends StatelessWidget {
  const _SelectionLeading({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 48,
      height: 48,
      child: Center(
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? theme.colorScheme.primary : null,
            border: selected ? null : Border.all(color: theme.colorScheme.outline),
          ),
          child: selected
              ? Icon(Icons.check, size: 18, color: theme.colorScheme.onPrimary)
              : null,
        ),
      ),
    );
  }
}

class _ThumbnailLeading extends StatelessWidget {
  const _ThumbnailLeading({required this.entry});

  final HistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = Icon(
      entry.kind == HistoryKind.audio ? Icons.music_note : Icons.movie_outlined,
      color: theme.colorScheme.primary,
    );
    final url = entry.thumbnailUrl;
    if (url == null || url.isEmpty) return icon;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 48,
        height: 48,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => icon,
        ),
      ),
    );
  }
}
