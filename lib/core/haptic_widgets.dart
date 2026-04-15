import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme_controller.dart';

class HapticInkWell extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final ThemeController controller;
  final BorderRadius? borderRadius;

  const HapticInkWell({
    super.key,
    required this.child,
    required this.controller,
    this.onTap,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: borderRadius,
      onTap: () {
        if (controller.hapticEnabled) {
          HapticFeedback.selectionClick();
        }
        onTap?.call();
      },
      child: child,
    );
  }
}
