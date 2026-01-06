import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../constants/app_dimensions.dart';

/// BILEE App Theme Configuration
/// Provides both Light and Dark theme with premium design
class AppTheme {
  AppTheme._();

  // ========== LIGHT THEME ==========
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    // Color Scheme
    colorScheme: const ColorScheme.light(
      primary: AppColors.primaryBlue,
      primaryContainer: AppColors.primaryBlueLight,
      secondary: AppColors.tealAccent,
      surface: AppColors.lightSurface,
      error: AppColors.error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.lightTextPrimary,
      onError: Colors.white,
      outline: AppColors.lightBorder,
    ),

    // Scaffold Background
    scaffoldBackgroundColor: AppColors.lightBackground,

    // App Bar Theme
    appBarTheme: AppBarTheme(
      elevation: AppDimensions.elevationNone,
      centerTitle: false,
      backgroundColor: AppColors.lightSurface,
      foregroundColor: AppColors.lightTextPrimary,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: AppTypography.fontSizeLG,
        fontWeight: FontWeight.w600,
        color: AppColors.lightTextPrimary,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.lightTextPrimary,
        size: AppDimensions.iconMD,
      ),
    ),

    // Text Theme - Poppins for Titles, Inter for Body
    textTheme: TextTheme(
      // Display Styles (Poppins - Extra Large Titles)
      displayLarge: GoogleFonts.poppins(
        fontSize: AppTypography.fontSize3XL,
        fontWeight: FontWeight.w700,
        color: AppColors.lightTextPrimary,
        height: AppTypography.lineHeightTight,
      ),
      displayMedium: GoogleFonts.poppins(
        fontSize: AppTypography.fontSize2XL,
        fontWeight: FontWeight.w700,
        color: AppColors.lightTextPrimary,
        height: AppTypography.lineHeightTight,
      ),
      displaySmall: GoogleFonts.poppins(
        fontSize: AppTypography.fontSizeXL,
        fontWeight: FontWeight.w600,
        color: AppColors.lightTextPrimary,
        height: AppTypography.lineHeightTight,
      ),

      // Headline Styles (Poppins - Titles)
      headlineLarge: GoogleFonts.poppins(
        fontSize: AppTypography.fontSizeXL,
        fontWeight: FontWeight.w600,
        color: AppColors.lightTextPrimary,
        height: AppTypography.lineHeightNormal,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: AppTypography.fontSizeLG,
        fontWeight: FontWeight.w600,
        color: AppColors.lightTextPrimary,
        height: AppTypography.lineHeightNormal,
      ),
      headlineSmall: GoogleFonts.poppins(
        fontSize: AppTypography.fontSizeMD,
        fontWeight: FontWeight.w600,
        color: AppColors.lightTextPrimary,
        height: AppTypography.lineHeightNormal,
      ),

      // Title Styles (Poppins - Subtitles)
      titleLarge: GoogleFonts.poppins(
        fontSize: AppTypography.fontSizeLG,
        fontWeight: FontWeight.w600,
        color: AppColors.lightTextPrimary,
      ),
      titleMedium: GoogleFonts.poppins(
        fontSize: AppTypography.fontSizeBase,
        fontWeight: FontWeight.w600,
        color: AppColors.lightTextPrimary,
      ),
      titleSmall: GoogleFonts.poppins(
        fontSize: AppTypography.fontSizeSM,
        fontWeight: FontWeight.w600,
        color: AppColors.lightTextPrimary,
      ),

      // Body Styles (Inter - Body Text)
      bodyLarge: GoogleFonts.inter(
        fontSize: AppTypography.fontSizeBase,
        fontWeight: FontWeight.w400,
        color: AppColors.lightTextPrimary,
        height: AppTypography.lineHeightNormal,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: AppTypography.fontSizeSM,
        fontWeight: FontWeight.w400,
        color: AppColors.lightTextPrimary,
        height: AppTypography.lineHeightNormal,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: AppTypography.fontSizeXS,
        fontWeight: FontWeight.w400,
        color: AppColors.lightTextSecondary,
        height: AppTypography.lineHeightNormal,
      ),

      // Label Styles (Inter - Buttons, Labels)
      labelLarge: GoogleFonts.inter(
        fontSize: AppTypography.fontSizeBase,
        fontWeight: FontWeight.w600,
        color: AppColors.lightTextPrimary,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: AppTypography.fontSizeSM,
        fontWeight: FontWeight.w600,
        color: AppColors.lightTextPrimary,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: AppTypography.fontSizeXS,
        fontWeight: FontWeight.w600,
        color: AppColors.lightTextSecondary,
      ),
    ),

    // Card Theme
    cardTheme: CardThemeData(
      elevation: AppDimensions.elevationSM,
      surfaceTintColor: Colors.transparent,
      shadowColor: AppColors.shadowMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
      ),
      margin: const EdgeInsets.all(AppDimensions.spacingMD),
    ),

    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: AppDimensions.elevationXS,
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, AppDimensions.buttonHeightMD),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: AppTypography.fontSizeBase,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // Outlined Button Theme
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryBlue,
        minimumSize: const Size(double.infinity, AppDimensions.buttonHeightMD),
        side: const BorderSide(
          color: AppColors.primaryBlue,
          width: AppDimensions.borderNormal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
        ),
        textStyle: GoogleFonts.inter(
          fontSize: AppTypography.fontSizeBase,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // Text Button Theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryBlue,
        textStyle: GoogleFonts.inter(
          fontSize: AppTypography.fontSizeBase,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.lightSurface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMD,
        vertical: AppDimensions.paddingSM,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
        borderSide: const BorderSide(
          color: AppColors.lightBorder,
          width: AppDimensions.borderThin,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
        borderSide: const BorderSide(
          color: AppColors.lightBorder,
          width: AppDimensions.borderThin,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
        borderSide: const BorderSide(
          color: AppColors.primaryBlue,
          width: AppDimensions.borderThick,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
        borderSide: const BorderSide(
          color: AppColors.error,
          width: AppDimensions.borderThin,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
        borderSide: const BorderSide(
          color: AppColors.error,
          width: AppDimensions.borderThick,
        ),
      ),
      labelStyle: GoogleFonts.inter(
        fontSize: AppTypography.fontSizeSM,
        color: AppColors.lightTextSecondary,
      ),
      hintStyle: GoogleFonts.inter(
        fontSize: AppTypography.fontSizeSM,
        color: AppColors.lightTextTertiary,
      ),
      errorStyle: GoogleFonts.inter(
        fontSize: AppTypography.fontSizeXS,
        color: AppColors.error,
      ),
    ),

    // Icon Theme
    iconTheme: const IconThemeData(
      color: AppColors.lightTextPrimary,
      size: AppDimensions.iconMD,
    ),

    // Divider Theme
    dividerTheme: const DividerThemeData(
      color: AppColors.lightDivider,
      thickness: AppDimensions.dividerThickness,
      space: AppDimensions.spacingMD,
    ),

    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.lightSurface,
      selectedItemColor: AppColors.primaryBlue,
      unselectedItemColor: AppColors.lightTextTertiary,
      selectedLabelStyle: GoogleFonts.inter(
        fontSize: AppTypography.fontSizeXS,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: GoogleFonts.inter(
        fontSize: AppTypography.fontSizeXS,
        fontWeight: FontWeight.w400,
      ),
      type: BottomNavigationBarType.fixed,
      elevation: AppDimensions.elevationMD,
    ),

    // Floating Action Button Theme
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primaryBlue,
      foregroundColor: Colors.white,
      elevation: AppDimensions.elevationMD,
    ),

    // Dialog Theme
    dialogTheme: DialogThemeData(
      surfaceTintColor: Colors.transparent,
      elevation: AppDimensions.elevationLG,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.modalRadius),
      ),
      titleTextStyle: GoogleFonts.poppins(
        fontSize: AppTypography.fontSizeLG,
        fontWeight: FontWeight.w600,
        color: AppColors.lightTextPrimary,
      ),
      contentTextStyle: GoogleFonts.inter(
        fontSize: AppTypography.fontSizeSM,
        color: AppColors.lightTextPrimary,
      ),
    ),

    // Chip Theme
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.lightBackground,
      selectedColor: AppColors.primaryBlueLight,
      labelStyle: GoogleFonts.inter(
        fontSize: AppTypography.fontSizeSM,
        fontWeight: FontWeight.w500,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingSM,
        vertical: AppDimensions.paddingXS,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.chipRadius),
      ),
    ),

    // Progress Indicator Theme
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primaryBlue,
    ),
  );

  // ========== DARK THEME ==========
  // static ThemeData darkTheme = ThemeData(
  //   useMaterial3: true,
  //   brightness: Brightness.dark,

  //   // Color Scheme
  //   colorScheme: const ColorScheme.dark(
  //     primary: AppColors.primaryBlueLight,
  //     primaryContainer: AppColors.primaryBlue,
  //     secondary: AppColors.tealAccent,
  //     surface: AppColors.darkSurface,
  //     error: AppColors.errorLight,
  //     onPrimary: Colors.white,
  //     onSecondary: Colors.white,
  //     onSurface: AppColors.darkTextPrimary,
  //     onError: Colors.white,
  //     outline: AppColors.darkBorder,
  //   ),

  //   // Scaffold Background
  //   scaffoldBackgroundColor: AppColors.darkBackground,

  //   // App Bar Theme
  //   appBarTheme: AppBarTheme(
  //     elevation: AppDimensions.elevationNone,
  //     centerTitle: false,
  //     backgroundColor: AppColors.darkSurface,
  //     foregroundColor: AppColors.darkTextPrimary,
  //     systemOverlayStyle: SystemUiOverlayStyle.light,
  //     titleTextStyle: GoogleFonts.poppins(
  //       fontSize: AppTypography.fontSizeLG,
  //       fontWeight: FontWeight.w600,
  //       color: AppColors.darkTextPrimary,
  //     ),
  //     iconTheme: const IconThemeData(
  //       color: AppColors.darkTextPrimary,
  //       size: AppDimensions.iconMD,
  //     ),
  //   ),

  //   // Text Theme
  //   textTheme: TextTheme(
  //     displayLarge: GoogleFonts.poppins(
  //       fontSize: AppTypography.fontSize3XL,
  //       fontWeight: FontWeight.w700,
  //       color: AppColors.darkTextPrimary,
  //       height: AppTypography.lineHeightTight,
  //     ),
  //     displayMedium: GoogleFonts.poppins(
  //       fontSize: AppTypography.fontSize2XL,
  //       fontWeight: FontWeight.w700,
  //       color: AppColors.darkTextPrimary,
  //       height: AppTypography.lineHeightTight,
  //     ),
  //     displaySmall: GoogleFonts.poppins(
  //       fontSize: AppTypography.fontSizeXL,
  //       fontWeight: FontWeight.w600,
  //       color: AppColors.darkTextPrimary,
  //       height: AppTypography.lineHeightTight,
  //     ),
  //     headlineLarge: GoogleFonts.poppins(
  //       fontSize: AppTypography.fontSizeXL,
  //       fontWeight: FontWeight.w600,
  //       color: AppColors.darkTextPrimary,
  //       height: AppTypography.lineHeightNormal,
  //     ),
  //     headlineMedium: GoogleFonts.poppins(
  //       fontSize: AppTypography.fontSizeLG,
  //       fontWeight: FontWeight.w600,
  //       color: AppColors.darkTextPrimary,
  //       height: AppTypography.lineHeightNormal,
  //     ),
  //     headlineSmall: GoogleFonts.poppins(
  //       fontSize: AppTypography.fontSizeMD,
  //       fontWeight: FontWeight.w600,
  //       color: AppColors.darkTextPrimary,
  //       height: AppTypography.lineHeightNormal,
  //     ),
  //     titleLarge: GoogleFonts.poppins(
  //       fontSize: AppTypography.fontSizeLG,
  //       fontWeight: FontWeight.w600,
  //       color: AppColors.darkTextPrimary,
  //     ),
  //     titleMedium: GoogleFonts.poppins(
  //       fontSize: AppTypography.fontSizeBase,
  //       fontWeight: FontWeight.w600,
  //       color: AppColors.darkTextPrimary,
  //     ),
  //     titleSmall: GoogleFonts.poppins(
  //       fontSize: AppTypography.fontSizeSM,
  //       fontWeight: FontWeight.w600,
  //       color: AppColors.darkTextPrimary,
  //     ),
  //     bodyLarge: GoogleFonts.inter(
  //       fontSize: AppTypography.fontSizeBase,
  //       fontWeight: FontWeight.w400,
  //       color: AppColors.darkTextPrimary,
  //       height: AppTypography.lineHeightNormal,
  //     ),
  //     bodyMedium: GoogleFonts.inter(
  //       fontSize: AppTypography.fontSizeSM,
  //       fontWeight: FontWeight.w400,
  //       color: AppColors.darkTextPrimary,
  //       height: AppTypography.lineHeightNormal,
  //     ),
  //     bodySmall: GoogleFonts.inter(
  //       fontSize: AppTypography.fontSizeXS,
  //       fontWeight: FontWeight.w400,
  //       color: AppColors.darkTextSecondary,
  //       height: AppTypography.lineHeightNormal,
  //     ),
  //     labelLarge: GoogleFonts.inter(
  //       fontSize: AppTypography.fontSizeBase,
  //       fontWeight: FontWeight.w600,
  //       color: AppColors.darkTextPrimary,
  //     ),
  //     labelMedium: GoogleFonts.inter(
  //       fontSize: AppTypography.fontSizeSM,
  //       fontWeight: FontWeight.w600,
  //       color: AppColors.darkTextPrimary,
  //     ),
  //     labelSmall: GoogleFonts.inter(
  //       fontSize: AppTypography.fontSizeXS,
  //       fontWeight: FontWeight.w600,
  //       color: AppColors.darkTextSecondary,
  //     ),
  //   ),

  //   // Card Theme
  //   cardTheme: CardThemeData(
  //     elevation: AppDimensions.elevationSM,
  //     surfaceTintColor: Colors.transparent,
  //     shadowColor: Colors.black45,
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
  //     ),
  //     margin: const EdgeInsets.all(AppDimensions.spacingMD),
  //   ),

  //   // Elevated Button Theme
  //   elevatedButtonTheme: ElevatedButtonThemeData(
  //     style: ElevatedButton.styleFrom(
  //       elevation: AppDimensions.elevationXS,
  //       backgroundColor: AppColors.primaryBlueLight,
  //       foregroundColor: Colors.white,
  //       minimumSize: const Size(double.infinity, AppDimensions.buttonHeightMD),
  //       shape: RoundedRectangleBorder(
  //         borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
  //       ),
  //       textStyle: GoogleFonts.inter(
  //         fontSize: AppTypography.fontSizeBase,
  //         fontWeight: FontWeight.w600,
  //       ),
  //     ),
  //   ),

  //   // Outlined Button Theme
  //   outlinedButtonTheme: OutlinedButtonThemeData(
  //     style: OutlinedButton.styleFrom(
  //       foregroundColor: AppColors.primaryBlueLight,
  //       minimumSize: const Size(double.infinity, AppDimensions.buttonHeightMD),
  //       side: const BorderSide(
  //         color: AppColors.primaryBlueLight,
  //         width: AppDimensions.borderNormal,
  //       ),
  //       shape: RoundedRectangleBorder(
  //         borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
  //       ),
  //       textStyle: GoogleFonts.inter(
  //         fontSize: AppTypography.fontSizeBase,
  //         fontWeight: FontWeight.w600,
  //       ),
  //     ),
  //   ),

  //   // Text Button Theme
  //   textButtonTheme: TextButtonThemeData(
  //     style: TextButton.styleFrom(
  //       foregroundColor: AppColors.primaryBlueLight,
  //       textStyle: GoogleFonts.inter(
  //         fontSize: AppTypography.fontSizeBase,
  //         fontWeight: FontWeight.w600,
  //       ),
  //     ),
  //   ),

  //   // Input Decoration Theme
  //   inputDecorationTheme: InputDecorationTheme(
  //     filled: true,
  //     fillColor: AppColors.darkSurface,
  //     contentPadding: const EdgeInsets.symmetric(
  //       horizontal: AppDimensions.paddingMD,
  //       vertical: AppDimensions.paddingSM,
  //     ),
  //     border: OutlineInputBorder(
  //       borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
  //       borderSide: const BorderSide(
  //         color: AppColors.darkBorder,
  //         width: AppDimensions.borderThin,
  //       ),
  //     ),
  //     enabledBorder: OutlineInputBorder(
  //       borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
  //       borderSide: const BorderSide(
  //         color: AppColors.darkBorder,
  //         width: AppDimensions.borderThin,
  //       ),
  //     ),
  //     focusedBorder: OutlineInputBorder(
  //       borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
  //       borderSide: const BorderSide(
  //         color: AppColors.primaryBlueLight,
  //         width: AppDimensions.borderThick,
  //       ),
  //     ),
  //     errorBorder: OutlineInputBorder(
  //       borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
  //       borderSide: const BorderSide(
  //         color: AppColors.errorLight,
  //         width: AppDimensions.borderThin,
  //       ),
  //     ),
  //     focusedErrorBorder: OutlineInputBorder(
  //       borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
  //       borderSide: const BorderSide(
  //         color: AppColors.errorLight,
  //         width: AppDimensions.borderThick,
  //       ),
  //     ),
  //     labelStyle: GoogleFonts.inter(
  //       fontSize: AppTypography.fontSizeSM,
  //       color: AppColors.darkTextSecondary,
  //     ),
  //     hintStyle: GoogleFonts.inter(
  //       fontSize: AppTypography.fontSizeSM,
  //       color: AppColors.darkTextTertiary,
  //     ),
  //     errorStyle: GoogleFonts.inter(
  //       fontSize: AppTypography.fontSizeXS,
  //       color: AppColors.errorLight,
  //     ),
  //   ),

  //   // Icon Theme
  //   iconTheme: const IconThemeData(
  //     color: AppColors.darkTextPrimary,
  //     size: AppDimensions.iconMD,
  //   ),

  //   // Divider Theme
  //   dividerTheme: const DividerThemeData(
  //     color: AppColors.darkDivider,
  //     thickness: AppDimensions.dividerThickness,
  //     space: AppDimensions.spacingMD,
  //   ),

  //   // Bottom Navigation Bar Theme
  //   bottomNavigationBarTheme: BottomNavigationBarThemeData(
  //     backgroundColor: AppColors.darkSurface,
  //     selectedItemColor: AppColors.primaryBlueLight,
  //     unselectedItemColor: AppColors.darkTextTertiary,
  //     selectedLabelStyle: GoogleFonts.inter(
  //       fontSize: AppTypography.fontSizeXS,
  //       fontWeight: FontWeight.w600,
  //     ),
  //     unselectedLabelStyle: GoogleFonts.inter(
  //       fontSize: AppTypography.fontSizeXS,
  //       fontWeight: FontWeight.w400,
  //     ),
  //     type: BottomNavigationBarType.fixed,
  //     elevation: AppDimensions.elevationMD,
  //   ),

  //   // Floating Action Button Theme
  //   floatingActionButtonTheme: const FloatingActionButtonThemeData(
  //     backgroundColor: AppColors.primaryBlueLight,
  //     foregroundColor: Colors.white,
  //     elevation: AppDimensions.elevationMD,
  //   ),

  //   // Dialog Theme
  //   dialogTheme: DialogThemeData(
  //     surfaceTintColor: Colors.transparent,
  //     elevation: AppDimensions.elevationLG,
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.circular(AppDimensions.modalRadius),
  //     ),
  //     titleTextStyle: GoogleFonts.poppins(
  //       fontSize: AppTypography.fontSizeLG,
  //       fontWeight: FontWeight.w600,
  //       color: AppColors.darkTextPrimary,
  //     ),
  //     contentTextStyle: GoogleFonts.inter(
  //       fontSize: AppTypography.fontSizeSM,
  //       color: AppColors.darkTextPrimary,
  //     ),
  //   ),

  //   // Chip Theme
  //   chipTheme: ChipThemeData(
  //     backgroundColor: AppColors.darkBackground,
  //     selectedColor: AppColors.primaryBlue,
  //     labelStyle: GoogleFonts.inter(
  //       fontSize: AppTypography.fontSizeSM,
  //       fontWeight: FontWeight.w500,
  //     ),
  //     padding: const EdgeInsets.symmetric(
  //       horizontal: AppDimensions.paddingSM,
  //       vertical: AppDimensions.paddingXS,
  //     ),
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.circular(AppDimensions.chipRadius),
  //     ),
  //   ),

  //   // Progress Indicator Theme
  //   progressIndicatorTheme: const ProgressIndicatorThemeData(
  //     color: AppColors.primaryBlueLight,
  //   ),
  // );
}
