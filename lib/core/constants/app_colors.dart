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

  // Financial Semantics - Restrained & Accurate
  static const Color income = Color(0xFF2D6A4F); // Restrained Deep Forest Green
  static const Color incomeLight = Color(0xFF40916C); // Calm Green
  static const Color incomeSurface = Color(0xFFEBF5EE);

  static const Color expense = Color(0xFFB91C1C); // Restrained Terracotta / Crimson
  static const Color expenseLight = Color(0xFFE56B6F);
  static const Color expenseSurface = Color(0xFFFDF2F2);

  static const Color transfer = Color(0xFF3B82F6); // Neutral Slate Blue
  static const Color transferLight = Color(0xFF60A5FA);
  static const Color transferSurface = Color(0xFFEFF6FF);

  static const Color withdrawal = Color(0xFFD97706); // Restrained Amber Gold
  static const Color withdrawalLight = Color(0xFFFBBF24);
  static const Color withdrawalSurface = Color(0xFFFEF7EC);

  static const Color warning = Color(0xFFD97706);
  static const Color neutral = Color(0xFF6B7280);
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

  // Surfaces - Light Theme (Warm off-white ground)
  static const Color lightBackground = Color(0xFFF7F8F5); // Warm clean off-white
  static const Color lightSurface = Color(0xFFFFFFFF); // Pure White Surface
  static const Color lightSurfaceVariant = Color(0xFFEFF1EC); // Subtle tonal separation
  static const Color lightBorder = Color(0xFFE2E5DC); // Quiet 0.75-1px Border
  static const Color lightDivider = Color(0xFFEAEDE4); // Hairline divider
  static const Color lightTextPrimary = Color(0xFF141A17); // High-contrast charcoal
  static const Color lightTextSecondary = Color(0xFF6B7570); // Readable muted grey
  static const Color lightTextTertiary = Color(0xFF949E99); // Subtle Caption

  // Surfaces - Dark Theme (Near-black ground with subtle forest undertone)
  static const Color darkBackground = Color(0xFF0C100E); // Near-black forest undertone
  static const Color darkSurface = Color(0xFF141916); // Clean dark card surface
  static const Color darkSurfaceVariant = Color(0xFF1B221E); // Layered surface
  static const Color darkBorder = Color(0xFF242C27); // Quiet Dark Border
  static const Color darkDivider = Color(0xFF1C2420); // Hairline divider
  static const Color darkTextPrimary = Color(0xFFF0F4F2); // Near-white
  static const Color darkTextSecondary = Color(0xFF8B9791); // Muted readable grey
  static const Color darkTextTertiary = Color(0xFF5F6B65); // Subtle Gray

  // Backward compatibility aliases
  static const Color darkCardHighlight = Color(0xFF212C26);
  static const Color darkSurfaceHighlight = Color(0xFF1B221E);
  static const Color darkSurfaceBorder = Color(0xFF242C27);
  static const Color brandAuraGlow = Color(0x1F1E4D38);
  static const Color incomeGlow = Color(0x1F2D6A4F);
  static const Color expenseGlow = Color(0x1FB91C1C);
}
