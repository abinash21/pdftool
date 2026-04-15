import 'package:flutter/services.dart';
import 'theme_controller.dart';

class HapticService {
  static void vibrate(ThemeController controller) {
    if (controller.hapticEnabled) {
      HapticFeedback.selectionClick();
    }
  }
}
