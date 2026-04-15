import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdftool/core/history_manager.dart';

import 'theme/app_theme.dart';
import 'core/theme_controller.dart';
import 'screens/main_shell.dart';
import 'core/haptic_wrapper.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const PdftoolApp());
}

class PdftoolApp extends StatefulWidget {
  const PdftoolApp({super.key});

  @override
  State<PdftoolApp> createState() => _PdftoolAppState();
}

class _PdftoolAppState extends State<PdftoolApp> {
  final ThemeController _controller = ThemeController();
  final HistoryManager _historyManager = HistoryManager();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, _) {
        return HapticWrapper(
          controller: _controller,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            themeMode: _controller.themeMode,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            home: MainShell(
              themeController: _controller,
              historyManager: _historyManager,
            ),
          ),
        );
      },
    );
  }
}
