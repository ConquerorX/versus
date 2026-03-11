import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ═══════════════════════════════════════════════
  // Editorial Luxury — Dinamik Accent Renk
  // ═══════════════════════════════════════════════
  
  // Varsayılan ana renkler (copper — fallback)
  static const copper = Color(0xFFC8956C);
  static const copperLight = Color(0xFFE8B88A);
  static const copperDark = Color(0xFFAA7B56);
  
  // Nötr tonlar
  static const charcoal = Color(0xFF1B1B1F);
  static const cardDark = Color(0xFF2D2D34);
  static const surfaceDark = Color(0xFF232328);
  static const borderDark = Color(0xFF3A3A42);
  
  static const warmWhite = Color(0xFFFAF8F5);
  static const cream = Color(0xFFF0EDE8);
  static const cardLight = Color(0xFFFFFFFF);
  
  // Semantik
  static const sage = Color(0xFF5B8A72);       // Başarı / güçlü
  static const mutedRed = Color(0xFFC75B5B);   // Tehlike / zayıf
  static const slate = Color(0xFF6B7280);      // Nötr metin

  // Gradients
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFFC8956C), Color(0xFFAA7B56)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const cardGradient = LinearGradient(
    colors: [Color(0xFF2D2D34), Color(0xFF1B1B1F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const luxuryGradient = LinearGradient(
    colors: [Color(0xFFC8956C), Color(0xFFE8B88A), Color(0xFFC8956C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ═══════ LIGHT THEME ═══════
  static ThemeData lightTheme(Color accent, Color tertiary, {bool isHighContrast = false}) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        brightness: Brightness.light,
        tertiary: tertiary,
        // Yüksek kontrastta renkleri daha keskin yap
        primary: isHighContrast ? Colors.blue[900] : null,
        onPrimary: isHighContrast ? Colors.white : null,
      ),
    );

    final bg = isHighContrast ? Colors.white : warmWhite;
    final textColor = isHighContrast ? Colors.black : charcoal;

    return base.copyWith(
      textTheme: GoogleFonts.dmSansTextTheme(base.textTheme).apply(
        bodyColor: textColor,
        displayColor: textColor,
      ),
      scaffoldBackgroundColor: bg,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.playfairDisplay(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: textColor),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardLight,
        hintStyle: GoogleFonts.dmSans(color: slate, fontSize: 14),
        labelStyle: GoogleFonts.dmSans(color: slate, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cream),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cream),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accent, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
          textStyle: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: cardLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        clipBehavior: Clip.antiAlias,
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: accent.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: accent);
          }
          return GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w400, color: slate);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: accent, size: 24);
          }
          return IconThemeData(color: slate, size: 24);
        }),
        backgroundColor: cardLight,
        elevation: 0,
      ),
    );
  }

  // ═══════ DARK THEME ═══════
  static ThemeData darkTheme(Color accent, Color tertiary, {bool isHighContrast = false}) {
    final accentLight = HSLColor.fromColor(accent).withLightness(isHighContrast ? 0.8 : 0.7).toColor();

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        brightness: Brightness.dark,
        tertiary: tertiary,
        primary: isHighContrast ? Colors.yellowAccent : null,
        onPrimary: isHighContrast ? Colors.black : null, // Sarı buton üstüne siyah yazı
      ),
    );

    final bg = isHighContrast ? Colors.black : charcoal;
    final cardBg = isHighContrast ? const Color(0xFF121212) : cardDark;
    final textColor = isHighContrast ? Colors.white : const Color(0xFFF5F0EB);

    return base.copyWith(
      textTheme: GoogleFonts.dmSansTextTheme(base.textTheme).apply(
        bodyColor: textColor,
        displayColor: textColor,
      ),
      scaffoldBackgroundColor: bg,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.playfairDisplay(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: textColor),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardBg,
        hintStyle: GoogleFonts.dmSans(color: isHighContrast ? Colors.grey[300] : slate, fontSize: 14),
        labelStyle: GoogleFonts.dmSans(color: isHighContrast ? Colors.grey[300] : slate, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: isHighContrast ? Colors.white : borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: isHighContrast ? Colors.white : borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accent, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
          textStyle: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: isHighContrast ? const BorderSide(color: Colors.white, width: 1.5) : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: accent.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: accentLight);
          }
          return GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w400, color: slate);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: accentLight, size: 24);
          }
          return IconThemeData(color: slate, size: 24);
        }),
        backgroundColor: charcoal,
        elevation: 0,
      ),
    );
  }
}

