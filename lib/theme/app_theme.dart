import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Mat Obsidyen & Grafit Palet (Yapay zeka neonu içermeyen, organik müzik stüdyosu estetiği)
  static const Color background = Color(0xFF0D0F17);       // Derin füme / mat obsidyen
  static const Color surface = Color(0xFF161924);          // Grafit kart zemini
  static const Color surfaceLight = Color(0xFF1E2333);     // İkincil yüzey
  static const Color border = Color(0xFF282E42);           // 1px zarif sınır çizgisi
  static const Color borderSubtle = Color(0xFF1F2433);

  // Vurgu Renkleri (Sıcak Kehribar / Plak Sarısı & Zümrüt)
  static const Color amber = Color(0xFFF59E0B);            // Sıcak amber
  static const Color amberGlow = Color(0xFFFFB020);
  static const Color emerald = Color(0xFF10B981);          // Doğru cevap zümrüdü
  static const Color crimson = Color(0xFFEF4444);          // Yanlış cevap / iptal
  static const Color coral = Color(0xFFE11D48);            // Canlı vurgu

  // Tipografi Renkleri
  static const Color textPrimary = Color(0xFFF8FAFC);     // Fildişi beyazı
  static const Color textSecondary = Color(0xFF94A3B8);   // Mat arduvaz grisi
  static const Color textMuted = Color(0xFF64748B);       // Sönük gri

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: amber,
        secondary: coral,
        surface: surface,
        error: crimson,
        onPrimary: Colors.black,
        onSurface: textPrimary,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        const TextTheme(
          displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: textPrimary, letterSpacing: -0.5),
          displayMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: -0.3),
          titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
          titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
          bodyLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: textPrimary),
          bodyMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.normal, color: textSecondary),
          labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}
