import 'package:flutter/material.dart';

import 'downloads_screen.dart';
import 'home_screen.dart';
import 'insights_screen.dart';
import 'settings_screen.dart';
import '../gen/app_localizations.dart';

class TalosShell extends StatefulWidget {
  const TalosShell({super.key});

  @override
  State<TalosShell> createState() => _TalosShellState();
}

class _TalosShellState extends State<TalosShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // Built once: IndexedStack rebuilds on every progress tick, and these
    // children must not be recreated each time.
    _pages = [
      const HomeScreen(),
      DownloadsScreen(onGoHome: () => setState(() => _index = 0)),
      const InsightsScreen(),
      const SettingsScreen(),
    ];
  }

  late final List<Widget> _pages;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final pages = _pages;

    final destinations = [
      NavigationDestination(icon: const Icon(Icons.travel_explore_outlined), selectedIcon: const Icon(Icons.travel_explore), label: l.home),
      NavigationDestination(icon: const Icon(Icons.download_outlined), selectedIcon: const Icon(Icons.download), label: l.downloads),
      NavigationDestination(icon: const Icon(Icons.insights_outlined), selectedIcon: const Icon(Icons.insights), label: l.insights),
      NavigationDestination(icon: const Icon(Icons.tune_outlined), selectedIcon: const Icon(Icons.tune), label: l.settings),
    ];

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              labelType: NavigationRailLabelType.all,
              destinations: [
                NavigationRailDestination(icon: const Icon(Icons.travel_explore_outlined), selectedIcon: const Icon(Icons.travel_explore), label: Text(l.home)),
                NavigationRailDestination(icon: const Icon(Icons.download_outlined), selectedIcon: const Icon(Icons.download), label: Text(l.downloads)),
                NavigationRailDestination(icon: const Icon(Icons.insights_outlined), selectedIcon: const Icon(Icons.insights), label: Text(l.insights)),
                NavigationRailDestination(icon: const Icon(Icons.tune_outlined), selectedIcon: const Icon(Icons.tune), label: Text(l.settings)),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: IndexedStack(index: _index, children: pages)),
          ],
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: destinations,
      ),
    );
  }
}
