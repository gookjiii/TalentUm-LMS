import 'package:flutter_riverpod/flutter_riverpod.dart';

/// StateNotifier to manage low performance mode across the app
class PerformanceModeNotifier extends StateNotifier<bool> {
  PerformanceModeNotifier() : super(_detectDefaultLowPerformance());

  static bool _detectDefaultLowPerformance() {
    return false;
  }

  void toggle() {
    state = !state;
  }

  void setLowPerformance(bool enable) {
    state = enable;
  }
}

/// Global provider for checking low performance mode status
final performanceModeProvider =
    StateNotifierProvider<PerformanceModeNotifier, bool>((ref) {
  return PerformanceModeNotifier();
});
