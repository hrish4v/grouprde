import 'package:flutter/foundation.dart';

/// A tiny in-app log so we can diagnose startup issues on-device (no logcat
/// needed). Lines are shown on the loading screen. Timestamps are seconds
/// since app start.
class DebugLog {
  DebugLog._();

  static final List<String> lines = [];
  static final ValueNotifier<int> tick = ValueNotifier<int>(0);
  static final Stopwatch _sw = Stopwatch()..start();

  static void add(String msg) {
    final t = (_sw.elapsedMilliseconds / 1000).toStringAsFixed(1);
    lines.add('[$t s] $msg');
    if (lines.length > 60) lines.removeAt(0);
    tick.value++;
    debugPrint('[GroupRide] $msg');
  }
}
