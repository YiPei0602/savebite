import 'package:flutter/material.dart';

/// SaveBite Design System - Color Palette
/// 
/// This class defines all colors used throughout the SaveBite app.
/// Follow this strictly to maintain brand consistency.
class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // ============================================================================
  // BRAND COLORS
  // ============================================================================
  
  /// Primary Brand Color - Blue Stone (Deep Teal)
  /// Usage: Headers, primary buttons, active states, brand elements
  static const Color primary = Color(0xFF00615F);
  static const Color primaryLight = Color(0xFF008F8C);
  static const Color primaryDark = Color(0xFF004643);
  
  /// Accent Color - Mango Tango (Vibrant Orange)
  /// Usage: Discount tags, call-to-actions, price highlights, urgency indicators
  static const Color accent = Color(0xFFFF8C42);
  static const Color accentLight = Color(0xFFFFA76B);
  static const Color accentDark = Color(0xFFE67329);

  // ============================================================================
  // BACKGROUND & SURFACE COLORS
  // ============================================================================
  
  /// Main Background - Vista White (Warm Off-White)
  /// Usage: App background, screen backgrounds
  static const Color background = Color(0xFFF9F3F0);
  
  /// Card/Surface Background
  /// Usage: Cards, elevated surfaces, containers
  static const Color surface = Color(0xFFFFFFFF);
  
  /// Secondary Background
  /// Usage: Input fields, disabled states, subtle backgrounds
  static const Color surfaceVariant = Color(0xFFF0E8E4);

  // ============================================================================
  // TEXT COLORS
  // ============================================================================
  
  /// Primary Text - Dark Slate
  static const Color textPrimary = Color(0xFF2B2D42);
  
  /// Secondary Text - Cool Gray
  static const Color textSecondary = Color(0xFF8D99AE);
  
  /// Tertiary Text - Light Gray
  static const Color textTertiary = Color(0xFFB8C1CC);
  
  /// Text on Primary Color
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  
  /// Text on Accent Color
  static const Color textOnAccent = Color(0xFF212529);

  // ============================================================================
  // SEMANTIC COLORS
  // ============================================================================
  
  /// Success - Caribbean Green
  /// Usage: Success messages, confirmations, positive indicators
  static const Color success = Color(0xFF06D6A0);
  
  /// Warning - Yellow
  /// Usage: Warnings, caution messages, expiring items
  static const Color warning = Color(0xFFFFC107);
  
  /// Error - Red Salsa
  /// Usage: Error messages, destructive actions, validation errors
  static const Color error = Color(0xFFE63946);
  
  /// Info - Blue
  /// Usage: Information messages, tips, neutral notifications
  static const Color info = Color(0xFF17A2B8);

  // ============================================================================
  // IMPACT DASHBOARD COLORS
  // ============================================================================
  
  /// Meals Saved Indicator
  static const Color mealsSaved = Color(0xFF00615F); // Primary teal
  
  /// CO2 Reduced Indicator
  static const Color co2Reduced = Color(0xFF06D6A0); // Caribbean green
  
  /// Money Saved Indicator
  static const Color moneySaved = Color(0xFFFF8C42); // Accent orange

  // ============================================================================
  // DIVIDERS & BORDERS
  // ============================================================================
  
  /// Divider Color
  static const Color divider = Color(0xFFDEE2E6);
  
  /// Border Color
  static const Color border = Color(0xFFCED4DA);
  
  /// Border Color (Active/Focused)
  static const Color borderActive = Color(0xFF00615F);

  // ============================================================================
  // SHADOWS & OVERLAYS
  // ============================================================================
  
  /// Shadow Color
  static const Color shadow = Color(0x1A000000);
  
  /// Overlay (for modals, bottom sheets)
  static const Color overlay = Color(0x80000000);
  
  /// Shimmer Base (for loading states)
  static const Color shimmerBase = Color(0xFFE9ECEF);
  
  /// Shimmer Highlight
  static const Color shimmerHighlight = Color(0xFFF8F9FA);

  // ============================================================================
  // ROLE-SPECIFIC COLORS
  // ============================================================================
  
  /// Merchant Role Indicator
  static const Color merchant = Color(0xFF6F42C1);
  
  /// Consumer Role Indicator
  static const Color consumer = Color(0xFF007BFF);
  
  /// NGO Role Indicator
  static const Color ngo = Color(0xFFE83E8C);

  // ============================================================================
  // FOOD CATEGORY COLORS (Optional - for visual categorization)
  // ============================================================================
  
  static const Color categoryBakery = Color(0xFFFFD93D);
  static const Color categoryMeats = Color(0xFFFF6B6B);
  static const Color categoryVegetables = Color(0xFF51CF66);
  static const Color categoryDairy = Color(0xFF74C0FC);
  static const Color categoryPrepared = Color(0xFFFF8C42);
  static const Color categoryOther = Color(0xFF868E96);
}
