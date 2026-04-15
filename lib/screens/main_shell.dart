import 'package:flutter/material.dart';
import 'package:pdftool/core/history_manager.dart';
import '../core/theme_controller.dart';
import 'home_screen.dart';
import 'tools_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'package:flutter/services.dart';

class MainShell extends StatefulWidget {
  final ThemeController themeController;
  final HistoryManager historyManager;

  const MainShell({
    super.key,
    required this.themeController,
    required this.historyManager,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(
        themeController: widget.themeController,
        onMoreEnginesTap: () {
          setState(() => index = 1);
        },
        historyManager: widget.historyManager,
      ),
      ToolsScreen(historyManager: widget.historyManager),
      HistoryScreen(historyManager: widget.historyManager),
      SettingsScreen(themeController: widget.themeController),
    ];

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        if (widget.themeController.hapticEnabled) {
          HapticFeedback.selectionClick();
        }
      },
      child: Scaffold(
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.05, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: KeyedSubtree(key: ValueKey(index), child: pages[index]),
        ),
        bottomNavigationBar: _buildBottomBar(context),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return BottomAppBar(
      color: Theme.of(context).colorScheme.surface,
      elevation: 8,
      shape: const CircularNotchedRectangle(),
      child: SizedBox(
        height: 70,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(context, Icons.home, 0),
            _navItem(context, Icons.grid_view, 1),
            _navItem(context, Icons.history, 2),
            _navItem(context, Icons.settings, 3),
          ],
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context, IconData icon, int i) {
    final selected = index == i;

    return IconButton(
      onPressed: () => setState(() => index = i),
      icon: AnimatedScale(
        scale: selected ? 1.2 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Icon(
          icon,
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
