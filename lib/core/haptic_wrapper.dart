import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme_controller.dart';

class HapticWrapper extends StatelessWidget {
  final Widget child;
  final ThemeController controller;

  const HapticWrapper({
    super.key,
    required this.child,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) {
        if (controller.hapticEnabled) {
          HapticFeedback.selectionClick();
        }
      },
      child: child,
    );
  }
}
