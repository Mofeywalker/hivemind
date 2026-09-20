import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Accent / Primary Brand (Honey Amber)
  static const Color primary = Color(0xFFF59E0B);
  static const Color primaryHover = Color(0xFFD97706);
  static const Color primaryLight = Color(0xFFFEF3C7);
  static const Color primaryDark = Color(0xFFB45309);

  // Functional Colors
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Light Mode Palette
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceSubtle = Color(0xFFF1F5F9);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightBorderSubtle = Color(0xFFF1F5F9);
  static const Color lightTextPrimary = Color(0xFF0F172A); // High-contrast Slate 900
  static const Color lightTextSecondary = Color(0xFF475569); // Slate 600 (contrast ratio > 5.5:1)
  static const Color lightTextMuted = Color(0xFF64748B); // Slate 500 (contrast ratio > 4.5:1)

  // Dark Mode Palette (Obsidian / High Contrast Minimalist)
  static const Color darkBackground = Color(0xFF090A0F);
  static const Color darkSurface = Color(0xFF13151D);
  static const Color darkSurfaceSubtle = Color(0xFF1E212E);
  static const Color darkBorder = Color(0xFF2E3446);
  static const Color darkBorderSubtle = Color(0xFF222634);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8); // High contrast on dark
  static const Color darkTextMuted = Color(0xFF7E8B9B); // High contrast on dark
}
