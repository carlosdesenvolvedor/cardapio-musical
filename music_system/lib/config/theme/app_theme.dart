import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFFE5B80B); // Brand Yellow
  static const Color backgroundColor = Color(0xFF121212);
  static const Color surfaceColor = Color(0xFF181818);
  static const Color errorColor = Color(0xFFE91E63);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      canvasColor: backgroundColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: primaryColor,
        surface: surfaceColor,
        error: errorColor,
        onSurface: Colors.white,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 32,
        ),
        titleLarge: GoogleFonts.outfit(
          color: Colors.white,
          fontWeight: FontWeight.bold, // changed to bold
          fontSize: 22,
        ),
        bodyLarge: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: GoogleFonts.inter(
          color: const Color(0xFFB3B3B3), // Spotify grey text
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        margin: EdgeInsets.zero, // Remove default margin
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8), // slightly sharper
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.black, // Spotify usually uses black text on green buttons
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(500), // pill shape
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        ),
      ),
      iconTheme: const IconThemeData(color: Color(0xFFB3B3B3)),
    );
  }
}
