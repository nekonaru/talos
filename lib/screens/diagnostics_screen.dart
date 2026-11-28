import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../core/engine/models.dart';
import '../gen/app_localizations.dart';
import '../widgets/section_label.dart';

/// Read-only view of engine and queue state, useful when a download behaves
/// unexpectedly. It never changes settings.
class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  EngineStatus? _status;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final status = await TalosScope.read(context).engine.status();
      if (mounted) setState(() => _status = status);
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final manager = TalosScope.of(context);
    final settings = manager.settings.value;
    final status = _status;

    return Scaffold(
      appBar: AppBar(title: Text(l.diagnostics)),
      floatingActionButton: FloatingActionButton.small(
        onPressed: _load,
        tooltip: l.retry,
        child: const Icon(Icons.refresh),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          SectionLabel(l.engine),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: Text(l.engineStatus),
                  subtitle: Text(status == null
                      ? (_error ?? l.checking)
                      : status.ready
                          ? l.engineReady
                          : l.engineMissing),
                ),
                ListTile(
                  title: Text(l.engineVersion),
                  subtitle: Text(status?.version ?? '-'),
                ),
                ListTile(
                  title: Text(l.ffmpeg),
                  subtitle: Text(status?.ffmpegPath?.isEmpty ?? true
                      ? l.engineMissing
                      : status!.ffmpegPath!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SectionLabel(l.activeTasks),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: Text(l.pauseQueue),
                  subtitle: Text(settings.queuePaused ? l.permissionGranted : l.permissionDenied),
                ),
                ListTile(
                  title: Text(l.wifiOnly),
                  subtitle: Text(settings.wifiOnly ? l.permissionGranted : l.permissionDenied),
                ),
                ListTile(
                  title: Text(l.batterySaver),
                  subtitle: Text(settings.batterySaverEnabled ? l.permissionGranted : l.permissionDenied),
                ),
                ListTile(
                  title: Text(l.quietHours),
                  subtitle: Text(settings.quietHoursEnabled ? l.permissionGranted : l.permissionDenied),
                ),
                ListTile(
                  title: Text(l.pendingTasks),
                  subtitle: Text('${manager.tasks.length}'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
