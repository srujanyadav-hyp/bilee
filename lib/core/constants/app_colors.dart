import 'package:flutter/material.dart';

/// BILEE App Color System
/// Premium blue gradient with clean backgrounds
class AppColors {
  AppColors._();

  // ========== PRIMARY COLORS ==========
  /// Primary Gradient Start - Teal-Green #00D4AA
  static const Color primaryBlue = Color(0xFF00D4AA);

  /// Primary Gradient End - Blue #1E5BFF
  static const Color primaryBlueLight = Color(0xFF1E5BFF);

  /// Splash Screen Gradient - Teal to Blue
  /// Left Side (Start): Teal-Green #00D4AA
  static const Color splashGradientStart = Color(0xFF00D4AA);

  /// Right Side (End): Blue #1E5BFF
  static const Color splashGradientEnd = Color(0xFF1E5BFF);

  /// Primary Gradient (UI Components)
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlue, primaryBlueLight],
  );

  /// Splash Screen Gradient (Splash Animation)
  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [splashGradientStart, splashGradientEnd],
  );

  // ========== LIGHT THEME COLORS ==========
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCardBackground = Color(0xFFFFFFFF);

  // Text Colors - Light Theme
  static const Color lightTextPrimary = Color(0xFF212529);
  static const Color lightTextSecondary = Color(0xFF6C757D);
  static const Color lightTextTertiary = Color(0xFFADB5BD);

  // Border & Divider - Light Theme
  static const Color lightBorder = Color(0xFFDEE2E6);
  static const Color lightDivider = Color(0xFFE9ECEF);

  // ========== DARK THEME COLORS ==========
  static const Color darkBackground = Color(0xFF0D1117);
  static const Color darkSurface = Color(0xFF161B22);
  static const Color darkCardBackground = Color(0xFF21262D);

  // Text Colors - Dark Theme
  static const Color darkTextPrimary = Color(0xFFF0F6FC);
  static const Color darkTextSecondary = Color(0xFF8B949E);
  static const Color darkTextTertiary = Color(0xFF6E7681);

  // Border & Divider - Dark Theme
  static const Color darkBorder = Color(0xFF30363D);
  static const Color darkDivider = Color(0xFF21262D);

  // ========== SEMANTIC COLORS ==========
  /// Success - Green
  static const Color success = Color(0xFF28A745);
  static const Color successLight = Color(0xFF34D058);

  /// Error - Red
  static const Color error = Color(0xFFDC3545);
  static const Color errorLight = Color(0xFFF85149);

  /// Warning - Orange
  static const Color warning = Color(0xFFFFC107);
  static const Color warningLight = Color(0xFFFFD33D);

  /// Info - Light Blue
  static const Color info = Color(0xFF17A2B8);
  static const Color infoLight = Color(0xFF58A6FF);

  // ========== SPECIAL COLORS ==========
  /// Teal Accent (from app icon)
  static const Color tealAccent = Color(0xFF00D4AA);

  /// Merchant Role Color
  static const Color merchantColor = Color(0xFF1976D2);

  /// Customer Role Color
  static const Color customerColor = Color(0xFF42A5F5);

  // ========== OVERLAY COLORS ==========
  static const Color overlayLight = Color(0x1A000000); // 10% black
  static const Color overlayMedium = Color(0x4D000000); // 30% black
  static const Color overlayDark = Color(0x80000000); // 50% black

  // ========== SHADOW COLORS ==========
  static const Color shadowLight = Color(0x0A000000);
  static const Color shadowMedium = Color(0x14000000);
  static const Color shadowDark = Color(0x1F000000);

  // ========== QR CODE COLORS ==========
  static const Color qrCodeForeground = Color(0xFF000000);
  static const Color qrCodeBackground = Color(0xFFFFFFFF);

  // ========== RECEIPT COLORS ==========
  static const Color receiptPaper = Color(0xFFFFFEF9);
  static const Color receiptText = Color(0xFF2D3436);
  static const Color receiptBorder = Color(0xFFDFE6E9);
}
