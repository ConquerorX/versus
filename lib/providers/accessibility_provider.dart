import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ═══════════════════════════════════════════════
// Yazı boyutu ölçekleme (0.8 – 1.6)
// ═══════════════════════════════════════════════
final fontScaleProvider = NotifierProvider<FontScaleNotifier, double>(
  FontScaleNotifier.new,
);

class FontScaleNotifier extends Notifier<double> {
  @override
  double build() {
    _load();
    return 1.0;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getDouble('fontScale') ?? 1.0;
  }

  Future<void> setScale(double scale) async {
    state = scale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fontScale', scale);
  }
}

// ═══════════════════════════════════════════════
// Yüksek kontrast modu
// ═══════════════════════════════════════════════
final highContrastProvider = NotifierProvider<HighContrastNotifier, bool>(
  HighContrastNotifier.new,
);

class HighContrastNotifier extends Notifier<bool> {
  @override
  bool build() {
    _load();
    return false;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('highContrast') ?? false;
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('highContrast', state);
  }
}

// ═══════════════════════════════════════════════
// Kalın yazı modu
// ═══════════════════════════════════════════════
final boldTextProvider = NotifierProvider<BoldTextNotifier, bool>(
  BoldTextNotifier.new,
);

class BoldTextNotifier extends Notifier<bool> {
  @override
  bool build() {
    _load();
    return false;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('boldText') ?? false;
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('boldText', state);
  }
}
