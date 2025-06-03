import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Warna utama
  static const Color primaryColor = Color(0xFF4A6572);
  static const Color accentColor = Color(0xFFF9AA33);
  static const Color lightColor = Color(0xFFEEF5DB);
  static const Color darkColor = Color(0xFF344955);
  static const Color errorColor = Color(0xFFD32F2F);

  // Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    // Menggunakan Google Fonts Poppins
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: accentColor,
      surface: Colors.white,
      background: Color(0xFFF5F5F5),
      error: errorColor,
    ),
    scaffoldBackgroundColor: Color(0xFFF5F5F5),
    appBarTheme: AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: primaryColor),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: BorderSide(color: primaryColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: accentColor,
      foregroundColor: Colors.white,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: primaryColor),
      ),
    ),
  );

  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    // Menggunakan Google Fonts Poppins
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
    colorScheme: ColorScheme.dark(
      primary: accentColor,
      secondary: primaryColor,
      surface: Color(0xFF1E2329),
      background: Color(0xFF121212),
      error: errorColor,
    ),
    scaffoldBackgroundColor: Color(0xFF121212),
    appBarTheme: AppBarTheme(
      backgroundColor: darkColor,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentColor,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: accentColor),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: accentColor,
        side: BorderSide(color: accentColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
    ),
    cardTheme: CardTheme(
      elevation: 2,
      color: Color(0xFF1E2329),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: accentColor,
      foregroundColor: Colors.black,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFF1E2329),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade800),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade800),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: accentColor),
      ),
    ),
  );
}
