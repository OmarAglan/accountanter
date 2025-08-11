// lib/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    fontFamily: GoogleFonts.inter().fontFamily,
    
    // Color Scheme
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.primaryForeground,
      secondary: AppColors.accent,
      onSecondary: AppColors.accentForeground,
      background: AppColors.background,
      onBackground: AppColors.foreground,
      surface: AppColors.card,
      onSurface: AppColors.foreground,
      error: AppColors.destructive,
      onError: AppColors.primaryForeground,
    ),

    // Scaffolding and Background
    scaffoldBackgroundColor: AppColors.background,
    
    // Typography (based on h1, h2, p etc. in globals.css)
    textTheme: TextTheme(
      headlineMedium: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.foreground), // H1
      headlineSmall: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.foreground), // H2
      titleLarge: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.foreground), // H3
      bodyLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.foreground), // Body
      bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.normal, color: AppColors.mutedForeground), // Caption
      labelLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500), // Button text
    ),

    // Component Themes
    cardTheme: CardThemeData( // <--- THIS IS THE FIX
      elevation: 0,
      color: AppColors.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // --radius is 6px, but 12 looks better for cards
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
    ),
    
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.card, // --input-background
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6), // --radius
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppColors.ring, width: 2),
      ),
      labelStyle: GoogleFonts.inter(
        color: AppColors.mutedForeground,
        fontWeight: FontWeight.w500,
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.primaryForeground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6), // --radius
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    ),

     textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.accent,
        textStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  );
}