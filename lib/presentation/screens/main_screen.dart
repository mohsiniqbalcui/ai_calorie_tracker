import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/settings_cubit.dart';
import '../pro/pro_shell.dart';
import 'graph_screen.dart';
import 'home_screen.dart';
import 'settings_screen.dart';

/// Chooses between the Simple and Pro UI based on the single mode toggle.
class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isPro = context.select((SettingsCubit c) => c.state.isPro);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: isPro ? const ProShell(key: ValueKey('pro')) : const SimpleShell(key: ValueKey('simple')),
    );
  }
}

class SimpleShell extends StatefulWidget {
  const SimpleShell({super.key});

  @override
  State<SimpleShell> createState() => _SimpleShellState();
}

class _SimpleShellState extends State<SimpleShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    const screens = [HomeScreen(), GraphScreen(), SettingsScreen()];
    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart_rounded), label: 'Progress'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings_rounded), label: 'Settings'),
        ],
      ),
    );
  }
}
