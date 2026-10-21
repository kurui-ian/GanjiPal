import 'package:flutter/material.dart';

/// Design system color constants for GanjiPal modern financial interface.
class AppColors {
  // Brand colors (Modern Indigo & Violet palette inspired by contemporary fintech)
  static const Color primary = Color(0xFF6366F1); // Electric Indigo
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4F46E5);

  // Hero Card Gradient
  static const List<Color> heroGradient = [
    Color(0xFF6366F1),
    Color(0xFF8B5CF6),
  ];

  // Financial Semantics
  static const Color income = Color(0xFF10B981); // Emerald Green
  static const Color incomeLight = Color(0xFF34D399);

  static const Color expense = Color(0xFFF43F5E); // Modern Rose / Coral
  static const Color expenseLight = Color(0xFFFB7185);

  static const Color transfer = Color(0xFF3B82F6); // Clean Sky Blue
  static const Color transferLight = Color(0xFF60A5FA);

  static const Color withdrawal = Color(0xFFF59E0B); // Warm Amber
  static const Color withdrawalLight = Color(0xFFFBBF24);

  static const Color neutral = Color(0xFF64748B);

  // Pastel Palette for Donut Charts & Category Badges
  static const Color pastelPurple = Color(0xFF8B5CF6);
  static const Color pastelPink = Color(0xFFEC4899);
  static const Color pastelBlue = Color(0xFF0EA5E9);
  static const Color pastelGreen = Color(0xFF10B981);
  static const Color pastelOrange = Color(0xFFF97316);
  static const Color pastelYellow = Color(0xFFF59E0B);
  static const Color pastelTeal = Color(0xFF14B8A6);
  static const Color pastelIndigo = Color(0xFF6366F1);

  static const List<Color> chartPalette = [
    Color(0xFF6366F1), // Indigo
    Color(0xFFEC4899), // Pink
    Color(0xFF10B981), // Emerald
    Color(0xFF0EA5E9), // Sky Blue
    Color(0xFFF59E0B), // Amber
    Color(0xFF8B5CF6), // Purple
    Color(0xFF14B8A6), // Teal
    Color(0xFFF97316), // Orange
  ];

  // Neutral surfaces - Light Theme
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF1F5F9);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightBorder = Color(0xFFE2E8F0);

  // Neutral surfaces - Dark Theme
  static const Color darkBackground = Color(0xFF0B0F19);
  static const Color darkSurface = Color(0xFF151C2C);
  static const Color darkSurfaceVariant = Color(0xFF1E293B);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkBorder = Color(0xFF26334D);

  // Surface elevation & glowing aura accents
  static const Color darkCardHighlight = Color(0xFF1E283D);
  static const Color brandAuraGlow = Color(0x336366F1);
  static const Color incomeGlow = Color(0x2E10B981);
  static const Color expenseGlow = Color(0x2EF43F5E);
}
