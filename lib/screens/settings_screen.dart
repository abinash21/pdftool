import 'package:flutter/material.dart';
import '../core/theme_controller.dart';

class SettingsScreen extends StatefulWidget {
  final ThemeController themeController;

  const SettingsScreen({super.key, required this.themeController});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _autoDownload = false;
  bool _autoWipe = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                "Preferences",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _themeButton(context, "Light", ThemeMode.light),
                  _themeButton(context, "Dark", ThemeMode.dark),
                  _themeButton(context, "System", ThemeMode.system),
                ],
              ),

              const SizedBox(height: 30),

              _switchTile(
                context,
                "Haptic Feedback",
                widget.themeController.hapticEnabled,
                (value) {
                  widget.themeController.setHaptic(value);
                },
              ),

              _switchTile(context, "Auto-Download", _autoDownload, (value) {
                setState(() => _autoDownload = value);
              }),

              _switchTile(context, "Auto-Wipe History", _autoWipe, (value) {
                setState(() => _autoWipe = value);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _themeButton(BuildContext context, String label, ThemeMode mode) {
    final selected = widget.themeController.themeMode == mode;

    return GestureDetector(
      onTap: () => widget.themeController.setTheme(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label),
      ),
    );
  }

  Widget _switchTile(
    BuildContext context,
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: colorScheme.outlineVariant, width: 1),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: Text(title),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      ),
    );
  }
}
