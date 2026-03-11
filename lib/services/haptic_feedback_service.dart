import 'package:flutter/services.dart';

/// Haptic geri bildirim servisi
class HapticService {
  /// Hafif dokunma — buton basışları, sayfa geçişleri
  static void lightTap() {
    HapticFeedback.lightImpact();
  }

  /// Orta titreşim — önemli aksiyonlar
  static void mediumImpact() {
    HapticFeedback.mediumImpact();
  }

  /// Ağır titreşim — büyük kararlar, karşılaştırma başlat
  static void heavyImpact() {
    HapticFeedback.heavyImpact();
  }

  /// Başarı titreşimi — sonuç geldi
  static void success() {
    HapticFeedback.mediumImpact();
  }

  /// Seçim değişikliği
  static void selectionClick() {
    HapticFeedback.selectionClick();
  }
}
