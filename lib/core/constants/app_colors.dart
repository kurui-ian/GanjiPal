import 'package:flutter/material.dart';

/// Design system color constants for GanjiPal.
/// Art Direction: Elegant, nature-inspired Kenyan financial companion.
/// Warm Ivory, Deep Forest Green, Muted Sage, Soft Charcoal, Restrained Amber & Crimson.
class AppColors {
  // Brand Colors - Deep Forest Green & Sage
  static const Color primary = Color(0xFF1E4D38); // Kenyan Deep Forest Green
  static const Color primaryLight = Color(0xFF2D6A4F); // Muted Forest Green
  static const Color primaryDark = Color(0xFF113324); // Rich Dark Forest
  static const Color primaryContainer = Color(0xFFE8F2EC); // Soft Sage tint

  // Muted Sage Accents
  static const Color sage = Color(0xFF52B788);
  static const Color sageLight = Color(0xFFD8F3DC);
  static const Color sageDark = Color(0xFF40916C);

  // Executive Signature Gradient (Forest Green)
  static const List<Color> heroGradient = [
    Color(0xFF1E4D38),
    Color(0xFF133627),
  ];

  // Financial Semantics
  static const Color income = Color(0xFF2D6A4F); // Deep Forest Green for Income
  static const Color incomeLight = Color(0xFF52B788); // Muted Sage
  static const Color incomeSurface = Color(0xFFEBF5EE);

  static const Color expense = Color(0xFFC53030); // Clear restrained Terracotta/Crimson
  static const Color expenseLight = Color(0xFFE56B6F);
  static const Color expenseSurface = Color(0xFFFDF2F2);

  static const Color transfer = Color(0xFF2B6CB0); // Dignified Slate Blue
  static const Color transferLight = Color(0xFF63B3ED);
  static const Color transferSurface = Color(0xFFEBF4FA);

  static const Color withdrawal = Color(0xFFD97706); // Restrained Amber Gold
  static const Color withdrawalLight = Color(0xFFFBBF24);
  static const Color withdrawalSurface = Color(0xFFFEF7EC);

  static const Color warning = Color(0xFFD97706);
  static const Color neutral = Color(0xFF6C757D);
  static const Color adjustment = Color(0xFF0D9488);
  static const Color unclassified = Color(0xFF6B7280);

  // Earthy, cohesive Chart & Category Palette
  static const List<Color> chartPalette = [
    Color(0xFF1E4D38), // Forest Green
    Color(0xFF52B788), // Sage
    Color(0xFFD97706), // Amber Gold
    Color(0xFF2B6CB0), // Slate Blue
    Color(0xFFC05621), // Warm Clay
    Color(0xFF687864), // Muted Olive
    Color(0xFF9C6670), // Rose Taupe
    Color(0xFF4A5568), // Charcoal Slate
  ];

  // Neutral surfaces - Light Theme (Warm Ivory Ground)
  static const Color lightBackground = Color(0xFFFBFBEE); // Warm Ivory
  static const Color lightSurface = Color(0xFFFFFFFF); // Pure White Surface
  static const Color lightSurfaceVariant = Color(0xFFF3F5EC); // Warm Tinted Container
  static const Color lightBorder = Color(0xFFE3E6DC); // Quiet 1px Border
  static const Color lightTextPrimary = Color(0xFF1A201C); // Soft Deep Charcoal
  static const Color lightTextSecondary = Color(0xFF5A665E); // Warm Readable Gray
  static const Color lightTextTertiary = Color(0xFF8A958E); // Muted Caption Gray

  // Neutral surfaces - Dark Theme (Deep Charcoal Ground with Forest Undertone)
  static const Color darkBackground = Color(0xFF0F1411); // Deep Charcoal Forest
  static const Color darkSurface = Color(0xFF171F1B); // Dark Slate Forest
  static const Color darkSurfaceVariant = Color(0xFF212C26); // Card Surface
  static const Color darkBorder = Color(0xFF2C3A32); // Quiet Dark Border
  static const Color darkTextPrimary = Color(0xFFF2F5F3); // Crisp Clear Primary
  static const Color darkTextSecondary = Color(0xFF9AA8A0); // Muted Sage Gray
  static const Color darkTextTertiary = Color(0xFF6B7A72); // Subtle Gray

  // Subtle Aura / Highlight Accents
  static const Color darkCardHighlight = Color(0xFF25332C);
  static const Color darkSurfaceHighlight = Color(0xFF25332C);
  static const Color darkSurfaceBorder = Color(0xFF2C3A32);
  static const Color brandAuraGlow = Color(0x261E4D38);
  static const Color incomeGlow = Color(0x242D6A4F);
  static const Color expenseGlow = Color(0x24C53030);
}
