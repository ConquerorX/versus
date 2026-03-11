import 'package:audioplayers/audioplayers.dart';

/// Kısa ses efektleri servisi
class SoundService {
  static final AudioPlayer _player = AudioPlayer();

  /// Zar atma / merak sesi — "Şansımı Dene" basıldığında
  static Future<void> playDiceRoll() async {
    try {
      await _player.play(AssetSource('sounds/dice_roll.mp3'), volume: 0.6);
    } catch (_) {}
  }

  /// Woosh efekti — Karşılaştırma başladığında
  static Future<void> playWoosh() async {
    try {
      await _player.play(AssetSource('sounds/woosh.mp3'), volume: 0.6);
    } catch (_) {}
  }

  /// Success/Ding — Sonuç geldiğinde
  static Future<void> playSuccess() async {
    try {
      await _player.play(AssetSource('sounds/success.mp3'), volume: 0.6);
    } catch (_) {}
  }

  /// Tıklama sesi — Genel buton basımı
  static Future<void> playTap() async {
    try {
      await _player.play(AssetSource('sounds/tap.mp3'), volume: 0.6);
    } catch (_) {}
  }

  /// Dispose
  static void dispose() {
    _player.dispose();
  }
}
