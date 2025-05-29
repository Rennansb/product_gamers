// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  static Color primaryColor = Colors.green.shade700;
  static Color secondaryColor = Colors.teal.shade600;
  static Color accentColor = Colors.amber.shade600;

  static Color primaryDarkColor = Colors.green.shade400;
  static Color secondaryDarkColor = Colors.teal.shade300;
  static Color accentDarkColor = Colors.amber.shade400;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: Colors.grey[100],
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: Colors.white, // Cor de fundo de Cards, Dialogs
        background: Colors.grey[100]!, // Cor de fundo principal
        error: Colors.red.shade700,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.black87, // Cor do texto em Cards, etc.
        onBackground: Colors.black87, // Cor do texto no fundo principal
        onError: Colors.white,
        tertiary: accentColor, // Cor de acento
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        color: Colors.white,
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: primaryColor,
        ),
        headlineSmall: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.grey[800],
        ), // Usado para títulos de seção
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ), // Títulos em cards, etc.
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.black54,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: Colors.black87),
        bodyMedium: TextStyle(fontSize: 14, color: Colors.black54),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: primaryColor,
        ), // Para botões de texto, etc.
        labelMedium: TextStyle(fontSize: 12, color: Colors.grey[700]),
        labelSmall: TextStyle(fontSize: 10, color: Colors.grey[600]),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey[200],
        selectedColor: primaryColor,
        secondarySelectedColor: primaryColor,
        labelStyle: TextStyle(color: Colors.black87),
        secondaryLabelStyle: TextStyle(color: Colors.white),
        iconTheme: IconThemeData(color: primaryColor),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade300,
        thickness: 0.8,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryDarkColor,
      scaffoldBackgroundColor: Colors.grey[900],
      colorScheme: ColorScheme.dark(
        primary: primaryDarkColor,
        secondary: secondaryDarkColor,
        surface: Colors.grey[800]!, // Cor de fundo de Cards, Dialogs
        background: Colors.grey[900]!, // Cor de fundo principal
        error: Colors.red.shade400,
        onPrimary: Colors.black, // Texto em botões primários
        onSecondary: Colors.black,
        onSurface: Colors.white70, // Cor do texto em Cards, etc.
        onBackground: Colors.white70, // Cor do texto no fundo principal
        onError: Colors.black,
        tertiary: accentDarkColor,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey[850], // Um pouco mais claro que o fundo
        foregroundColor: Colors.white,
        elevation: 2,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      cardTheme: CardTheme(
        color: Colors.grey[800],
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      listTileTheme: ListTileThemeData(
        tileColor: Colors.grey[800],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: primaryDarkColor,
        ),
        headlineSmall: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.grey[300],
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.white70,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.white60,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: Colors.white70),
        bodyMedium: TextStyle(fontSize: 14, color: Colors.white60),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: primaryDarkColor,
        ),
        labelMedium: TextStyle(fontSize: 12, color: Colors.grey[400]),
        labelSmall: TextStyle(fontSize: 10, color: Colors.grey[500]),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryDarkColor,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey[700],
        selectedColor: primaryDarkColor,
        secondarySelectedColor: primaryDarkColor,
        labelStyle: TextStyle(color: Colors.white70),
        secondaryLabelStyle: TextStyle(color: Colors.black),
        iconTheme: IconThemeData(color: primaryDarkColor),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade700,
        thickness: 0.8,
      ),
    );
  }
}
