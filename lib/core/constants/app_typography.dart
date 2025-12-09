import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// BILEE Typography System
/// Titles: Poppins | Body: Inter
class AppTypography {
  AppTypography._();

  // ========== FONT FAMILIES ==========
  static const String fontFamilyPoppins = 'Poppins';
  static const String fontFamilyInter = 'Inter';

  // ========== FONT WEIGHTS ==========
  static const int light = 300;
  static const int regular = 400;
  static const int medium = 500;
  static const int semiBold = 600;
  static const int bold = 700;
  static const int extraBold = 800;

  // ========== FONT SIZES ==========
  // Headings
  static const double fontSize3XL = 32.0; // H1
  static const double fontSize2XL = 28.0; // H2
  static const double fontSizeXL = 24.0; // H3
  static const double fontSizeLG = 20.0; // H4
  static const double fontSizeMD = 18.0; // H5

  // Body Text
  static const double fontSizeBase = 16.0; // Body Large
  static const double fontSizeSM = 14.0; // Body Regular
  static const double fontSizeXS = 12.0; // Body Small
  static const double fontSize2XS = 10.0; // Caption

  // ========== LINE HEIGHTS ==========
  static const double lineHeightTight = 1.2;
  static const double lineHeightNormal = 1.5;
  static const double lineHeightRelaxed = 1.75;
  static const double lineHeightLoose = 2.0;

  // ========== LETTER SPACING ==========
  static const double letterSpacingTight = -0.5;
  static const double letterSpacingNormal = 0.0;
  static const double letterSpacingWide = 0.5;
  static const double letterSpacingWider = 1.0;

  // ========== TEXT STYLES ==========
  // Heading Styles (Poppins)
  static final TextStyle h1 = GoogleFonts.poppins(
    fontSize: fontSize3XL,
    fontWeight: FontWeight.w700,
    height: lineHeightTight,
    letterSpacing: letterSpacingTight,
  );

  static final TextStyle h2 = GoogleFonts.poppins(
    fontSize: fontSize2XL,
    fontWeight: FontWeight.w600,
    height: lineHeightTight,
  );

  static final TextStyle h3 = GoogleFonts.poppins(
    fontSize: fontSizeXL,
    fontWeight: FontWeight.w600,
    height: lineHeightNormal,
  );

  static final TextStyle h4 = GoogleFonts.poppins(
    fontSize: fontSizeLG,
    fontWeight: FontWeight.w600,
    height: lineHeightNormal,
  );

  static final TextStyle h5 = GoogleFonts.poppins(
    fontSize: fontSizeMD,
    fontWeight: FontWeight.w600,
    height: lineHeightNormal,
  );

  // Body Styles (Inter)
  static final TextStyle body1 = GoogleFonts.inter(
    fontSize: fontSizeBase,
    fontWeight: FontWeight.w400,
    height: lineHeightNormal,
  );

  static final TextStyle body2 = GoogleFonts.inter(
    fontSize: fontSizeSM,
    fontWeight: FontWeight.w400,
    height: lineHeightNormal,
  );

  static final TextStyle body3 = GoogleFonts.inter(
    fontSize: fontSizeXS,
    fontWeight: FontWeight.w400,
    height: lineHeightNormal,
  );

  // Button Style
  static final TextStyle button = GoogleFonts.inter(
    fontSize: fontSizeBase,
    fontWeight: FontWeight.w600,
    letterSpacing: letterSpacingWide,
  );

  // Caption Style
  static final TextStyle caption = GoogleFonts.inter(
    fontSize: fontSizeXS,
    fontWeight: FontWeight.w400,
    height: lineHeightNormal,
  );

  // Label Style
  static final TextStyle label = GoogleFonts.inter(
    fontSize: fontSizeSM,
    fontWeight: FontWeight.w500,
    letterSpacing: letterSpacingWide,
  );
}
