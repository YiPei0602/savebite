import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// SaveBite Design System - Typography
/// 
/// This class defines all text styles used throughout the SaveBite app.
/// Uses Google Fonts 'Inter' for a modern, clean look (matching Grab Food).
class AppTypography {
  // Private constructor to prevent instantiation
  AppTypography._();

  // ============================================================================
  // HEADINGS
  // ============================================================================
  
  /// H1 - Large Page Titles
  /// Usage: Main screen titles, welcome messages
  static TextStyle h1 = GoogleFonts.inter(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  /// H2 - Section Headers
  /// Usage: Section titles, card headers
  static TextStyle h2 = GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  /// H3 - Subsection Headers
  /// Usage: Subsection titles, dialog titles
  static TextStyle h3 = GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  /// H4 - Small Headers
  /// Usage: Card titles, list item headers
  static TextStyle h4 = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  /// H5 - Tiny Headers
  /// Usage: Labels, small section headers
  static TextStyle h5 = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  // ============================================================================
  // BODY TEXT
  // ============================================================================
  
  /// Body Large - Primary Content
  /// Usage: Main content, descriptions, paragraphs
  static TextStyle bodyLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  /// Body Medium - Secondary Content
  /// Usage: Secondary information, metadata
  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  /// Body Small - Tertiary Content
  /// Usage: Helper text, captions, footnotes
  static TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  // ============================================================================
  // SPECIALIZED TEXT STYLES
  // ============================================================================
  
  /// Button Text - Large
  /// Usage: Primary buttons, prominent CTAs
  static TextStyle buttonLarge = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
    height: 1.2,
    letterSpacing: 0.5,
  );

  /// Button Text - Medium
  /// Usage: Secondary buttons, standard CTAs
  static TextStyle buttonMedium = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
    height: 1.2,
    letterSpacing: 0.5,
  );

  /// Button Text - Small
  /// Usage: Small buttons, chip buttons
  static TextStyle buttonSmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
    height: 1.2,
    letterSpacing: 0.5,
  );

  /// Caption - Small Descriptive Text
  /// Usage: Image captions, timestamps, metadata
  static TextStyle caption = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.3,
  );

  /// Overline - Uppercase Labels
  /// Usage: Category labels, section labels
  static TextStyle overline = GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    height: 1.5,
    letterSpacing: 1.5,
  );

  // ============================================================================
  // PRICE & NUMBERS
  // ============================================================================
  
  /// Price - Large (Original Price)
  static TextStyle priceLarge = GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  /// Price - Medium (Discounted Price)
  static TextStyle priceMedium = GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.accent,
    height: 1.2,
  );

  /// Price - Small (Crossed Out Price)
  static TextStyle priceSmall = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
    height: 1.2,
    decoration: TextDecoration.lineThrough,
  );

  /// Discount Badge
  static TextStyle discountBadge = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: AppColors.textOnAccent,
    height: 1.2,
  );

  // ============================================================================
  // IMPACT DASHBOARD
  // ============================================================================
  
  /// Impact Number - Large metric display
  static TextStyle impactNumber = GoogleFonts.inter(
    fontSize: 36,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
    height: 1.2,
  );

  /// Impact Label - Metric description
  static TextStyle impactLabel = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.3,
  );

  // ============================================================================
  // INPUT FIELDS
  // ============================================================================
  
  /// Input Text - Text field content
  static TextStyle inputText = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  /// Input Label - Text field label
  static TextStyle inputLabel = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.3,
  );

  /// Input Hint - Placeholder text
  static TextStyle inputHint = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textTertiary,
    height: 1.5,
  );

  /// Input Error - Error message
  static TextStyle inputError = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.error,
    height: 1.3,
  );

  // ============================================================================
  // LINKS
  // ============================================================================
  
  /// Link - Clickable text
  static TextStyle link = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.primary,
    height: 1.5,
    decoration: TextDecoration.underline,
  );

  /// Link Small - Small clickable text
  static TextStyle linkSmall = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.primary,
    height: 1.5,
    decoration: TextDecoration.underline,
  );
}
