import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_scope.dart';
import '../core/format.dart';
import '../core/insights.dart';
import '../core/history_store.dart';
import '../core/storage_bridge.dart';
import '../gen/app_localizations.dart';
import '../widgets/section_label.dart';

/// Read-only view of the finished-download library plus one guarded cleanup
/// action. All numbers come from [buildInsights], which is pure and tested.
class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  int? _cacheRevision;
  InsightStats? _cache;
  int? _folderCacheRevision;
  List<({String folder, int count, int bytes})> _folderCache = const [];

  InsightStats _buildStats(List<HistoryEntry> entries, int revision) {
    final stats = buildInsights(entries);
    _cacheRevision = revision;
    _cache = stats;
    return stats;
  }

  /// Folder grouping is O(n) over history. The Insights tab stays mounted and
  /// rebuilds on every progress tick, so cache it by history revision.
  List<({String folder, int count, int bytes})> _buildFolders(
    List<HistoryEntry> entries,
    int revision,
  ) {
    if (_folderCacheRevision == revision) return _folderCache;
    final folders = folderBreakdown(entries);
    _folderCacheRevision = revision;
    _folderCache = folders;
    return folders;
  }

  Future<void> _removeDuplicates(BuildContext context, List<HistoryEntry> entries) async {
    final l = AppLocalizations.of(context)!;
    final manager = TalosScope.of(context);
    final duplicates = duplicateHistoryEntries(entries);
    if (duplicates.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.noDuplicates)),
        );
      }
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.findDuplicates),
        content: Text(l.duplicatesFound(duplicates.length)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l.remove),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await manager.history.removeMany(duplicates.map((e) => e.id));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.duplicatesRemoved(duplicates.length))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final manager = TalosScope.of(context);
    final entries = manager.history.entries;
    // This tab stays mounted in the shell's IndexedStack and rebuilds on every
    // progress tick. Re-sorting up to 300 rows each time is wasted work.
    final revision = manager.history.revision;
    final stats = _cacheRevision == revision && _cache != null
        ? _cache!
        : _buildStats(entries, revision);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.insights),
        actions: [
          IconButton(
            tooltip: l.findDuplicates,
            icon: const Icon(Icons.merge_type_outlined),
            onPressed: () => _removeDuplicates(context, entries),
          ),
        ],
      ),
      body: entries.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  l.noInsightsYet,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                Text(l.insightsHint, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 12),
                _SummaryCard(stats: stats),
                const SizedBox(height: 20),
                SectionLabel(l.activity),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(l.activityHint, style: theme.textTheme.bodySmall),
                        const SizedBox(height: 16),
                        _ActivityBars(days: stats.last7Days),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SectionLabel(l.breakdown),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Column(
                      children: [
                        _TypeRow(
                          label: l.filterVideo,
                          count: stats.videoCount,
                          bytes: stats.videoBytes,
                          share: stats.videoShare,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 14),
                        _TypeRow(
                          label: l.filterAudio,
                          count: stats.audioCount,
                          bytes: stats.audioBytes,
                          share: stats.audioShare,
                          color: theme.colorScheme.tertiary,
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.star_rounded, size: 18, color: theme.colorScheme.primary),
                                const SizedBox(width: 8),
                                Text(l.favorite, style: theme.textTheme.bodyMedium),
                              ],
                            ),
                            Text('${stats.favoriteCount}', style: theme.textTheme.titleMedium),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SectionLabel(l.storageFolders),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Column(
                      children: [
                        for (final folder in _buildFolders(entries, revision).take(6)) ...[
                          Row(
                            children: [
                              Icon(Icons.folder_outlined, size: 18, color: theme.colorScheme.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  folder.folder,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                              Text(
                                '${folder.count} · ${formatBytes(folder.bytes)}',
                                style: theme.textTheme.labelSmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SectionLabel(l.largestDownloads),
                Card(
                  child: Column(
                    children: [
                      for (final entry in stats.largest)
                        ListTile(
                          leading: Icon(
                            entry.kind == HistoryKind.audio ? Icons.music_note_outlined : Icons.movie_outlined,
                            color: theme.colorScheme.primary,
                          ),
                          title: Text(entry.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(formatBytes(entry.sizeBytes), style: theme.textTheme.bodySmall),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SectionLabel(l.cleanup),
                Card(
                  child: ListTile(
                    leading: Icon(Icons.cleaning_services_outlined, color: theme.colorScheme.error),
                    title: Text(l.cleanupOlderThan(30)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _confirmCleanup(context, entries, 30),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _confirmCleanup(BuildContext context, List<HistoryEntry> entries, int days) async {
    final l = AppLocalizations.of(context)!;
    final manager = TalosScope.of(context);
    final now = DateTime.now().millisecondsSinceEpoch;
    final cutoff = now - Duration(days: days).inMilliseconds;
    final old = entries.where((e) => e.dateMs > 0 && e.dateMs < cutoff).toList();
    if (old.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.cleanupNone)));
      }
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.cleanup),
        content: Text(l.cleanupConfirm(old.length)),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text(l.delete)),
        ],
      ),
    );
    if (confirmed != true) return;
    final removed = <String>[];
    for (final entry in old) {
      if (await TalosStorageBridge.deleteDownloadedFile(entry.filePath)) {
        removed.add(entry.id);
      }
    }
    await manager.history.removeMany(removed);
    if (!context.mounted) return;
    final partial = removed.length != old.length;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          partial
              ? l.cleanupPartial(removed.length, old.length)
              : l.cleanupDone(removed.length),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.stats});

  final InsightStats stats;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Expanded(child: _Stat(value: '${stats.totalCount}', label: l.totalDownloads)),
            _Divider(theme: theme),
            Expanded(child: _Stat(value: formatBytes(stats.totalBytes), label: l.totalSize)),
            _Divider(theme: theme),
            Expanded(child: _Stat(value: '${stats.monthCount}', label: l.thisMonth)),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 40,
        color: theme.dividerColor,
      );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(label, style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
      ],
    );
  }
}

class _ActivityBars extends StatelessWidget {
  const _ActivityBars({required this.days});

  final List<int> days;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final max = days.isEmpty ? 1 : days.reduce((a, b) => a > b ? a : b);
    final now = DateTime.now();
    final locale = AppLocalizations.of(context)!.localeName;
    final weekday = DateFormat.E(locale);
    final labels = List<String>.generate(7, (i) {
      final date = now.subtract(Duration(days: 6 - i));
      return weekday.format(date);
    });
    final fullLabels = List<String>.generate(7, (i) {
      final date = now.subtract(Duration(days: 6 - i));
      return '${date.day}/${date.month}: ${days[i]}';
    });

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: Semantics(
              label: fullLabels[i],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 80,
                      alignment: Alignment.bottomCenter,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeOutCubic,
                        width: double.infinity,
                        height: days[i] == 0 ? 4 : (24 + 56 * (days[i] / max)).toDouble(),
                        decoration: BoxDecoration(
                          color: days[i] == 0
                              ? theme.colorScheme.surfaceContainerHighest
                              : theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(labels[i], style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _TypeRow extends StatelessWidget {
  const _TypeRow({
    required this.label,
    required this.count,
    required this.bytes,
    required this.share,
    required this.color,
  });

  final String label;
  final int count;
  final int bytes;
  final double share;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$label  ·  $count', style: theme.textTheme.bodyMedium),
            Text(formatBytes(bytes), style: theme.textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: share.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            color: color,
          ),
        ),
      ],
    );
  }
}
