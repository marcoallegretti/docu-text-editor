import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // App Colors
  static const Color primaryColor = Color(0xFF1565C0); // Blue
  static const Color accentColor = Color(0xFF42A5F5); // Light Blue
  static const Color paperColor = Colors.white;
  static const Color toolbarColor = Color(0xFFF5F5F5);
  static const Color textColor = Color(0xFF212121);
  static const Color secondaryTextColor = Color(0xFF757575);
  static const Color disabledColor = Color(0xFFBDBDBD);
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color successColor = Color(0xFF388E3C);
  static const Color warningColor = Color(0xFFF57C00);
  static const Color linkColor = Color(0xFF0277BD);
  static const Color focusColor = Color(0xFFE3F2FD);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryColor, accentColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF1976D2), Color(0xFF64B5F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Border Radius
  static const double borderRadius = 8.0;
  static const double smallBorderRadius = 4.0;
  static const double largeBorderRadius = 12.0;

  // Margins and Padding
  static const double smallMargin = 8.0;
  static const double defaultMargin = 16.0;
  static const double largeMargin = 24.0;

  static const double smallPadding = 8.0;
  static const double defaultPadding = 16.0;
  static const double largePadding = 24.0;

  // Elevations
  static const double defaultElevation = 2.0;
  static const double cardElevation = 1.0;
  static const double dialogElevation = 8.0;

  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // Card Styles
  static BoxDecoration cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(borderRadius),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 6,
        offset: const Offset(0, 2),
      ),
    ],
  );

  // Button Styles
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
    ),
    textStyle: const TextStyle(fontWeight: FontWeight.w500),
  );

  static ButtonStyle secondaryButtonStyle = OutlinedButton.styleFrom(
    foregroundColor: primaryColor,
    side: const BorderSide(color: primaryColor),
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
    ),
    textStyle: const TextStyle(fontWeight: FontWeight.w500),
  );

  static ButtonStyle textButtonStyle = TextButton.styleFrom(
    foregroundColor: primaryColor,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
    ),
    textStyle: const TextStyle(fontWeight: FontWeight.w500),
  );

  static ButtonStyle toolbarButtonStyle = TextButton.styleFrom(
    foregroundColor: textColor,
    backgroundColor: Colors.transparent,
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(4),
    ),
  );

  // Toolbar Icon Style
  static IconThemeData toolbarIconTheme = const IconThemeData(
    color: textColor,
    size: 20,
  );

  // Icon Button Style
  static ButtonStyle iconButtonStyle = IconButton.styleFrom(
    foregroundColor: primaryColor,
    backgroundColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
    ),
  );

  // Input Decoration
  static InputDecorationTheme inputDecorationTheme = InputDecorationTheme(
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: const BorderSide(color: disabledColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: const BorderSide(color: disabledColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: const BorderSide(color: primaryColor),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      borderSide: const BorderSide(color: errorColor),
    ),
    filled: true,
    fillColor: Colors.white,
    hintStyle: TextStyle(color: secondaryTextColor.withOpacity(0.7)),
  );

  // Editor Paper Style
  static BoxDecoration editorPaperDecoration = BoxDecoration(
    color: paperColor,
    borderRadius: BorderRadius.circular(2),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 8,
        offset: const Offset(0, 1),
      ),
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 1,
        offset: const Offset(0, 1),
      ),
    ],
  );

  // Dark Mode Colors
  static const Color darkPrimaryColor =
      Color(0xFF2196F3); // A brighter blue for dark theme
  static const Color darkAccentColor =
      Color(0xFF64B5F6); // Light Blue for dark theme
  static const Color darkBackgroundColor = Color(0xFF121212);
  static const Color darkSurfaceColor = Color(0xFF1E1E1E);
  static const Color darkCardColor = Color(0xFF262626);
  static const Color darkTextColor = Colors.white;
  static const Color darkSecondaryTextColor = Color(0xFFB0B0B0);
  static const Color darkDividerColor = Color(0xFF444444);
  static const Color darkToolbarColor = Color(0xFF333333);
  static const Color darkPaperColor = Color(0xFF2C2C2C);

  // Dark Theme Box Decoration
  static BoxDecoration darkCardDecoration = BoxDecoration(
    color: darkCardColor,
    borderRadius: BorderRadius.circular(borderRadius),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.2),
        blurRadius: 6,
        offset: const Offset(0, 2),
      ),
    ],
  );

  // Dark Editor Paper Style
  static BoxDecoration darkEditorPaperDecoration = BoxDecoration(
    color: darkPaperColor,
    borderRadius: BorderRadius.circular(2),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.2),
        blurRadius: 8,
        offset: const Offset(0, 1),
      ),
    ],
  );

  // Theme Data
  static ThemeData lightTheme = ThemeData(
    primaryColor: primaryColor,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: accentColor,
      error: errorColor,
      surface: paperColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textColor,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: Colors.grey[100],
    appBarTheme: AppBarTheme(
      backgroundColor: primaryColor,
      elevation: 0,
      centerTitle: false,
      iconTheme: const IconThemeData(color: Colors.white),
      actionsIconTheme: const IconThemeData(color: Colors.white),
      titleSpacing: defaultPadding,
      toolbarHeight: 60,
      titleTextStyle: GoogleFonts.poppins(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardTheme(
      elevation: cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      clipBehavior: Clip.antiAlias,
    ),
    tabBarTheme: TabBarTheme(
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white.withOpacity(0.7),
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: GoogleFonts.poppins(
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
      unselectedLabelStyle: GoogleFonts.poppins(
        fontWeight: FontWeight.w400,
        fontSize: 14,
      ),
    ),
    dialogTheme: DialogTheme(
      elevation: dialogElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      titleTextStyle: GoogleFonts.poppins(
        color: textColor,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.grey[800],
      contentTextStyle: GoogleFonts.poppins(
        color: Colors.white,
        fontSize: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      textStyle: GoogleFonts.poppins(
        color: Colors.white,
        fontSize: 12,
      ),
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.poppins(
          fontSize: 28, fontWeight: FontWeight.bold, color: textColor),
      displayMedium: GoogleFonts.poppins(
          fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
      displaySmall: GoogleFonts.poppins(
          fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
      headlineMedium: GoogleFonts.poppins(
          fontSize: 18, fontWeight: FontWeight.w600, color: textColor),
      headlineSmall: GoogleFonts.poppins(
          fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
      titleLarge: GoogleFonts.poppins(
          fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
      bodyLarge:
          GoogleFonts.poppins(fontSize: 16, color: textColor, height: 1.5),
      bodyMedium:
          GoogleFonts.poppins(fontSize: 14, color: textColor, height: 1.5),
      bodySmall: GoogleFonts.poppins(
          fontSize: 12, color: secondaryTextColor, height: 1.5),
      labelLarge: GoogleFonts.poppins(
          fontSize: 14, fontWeight: FontWeight.w500, color: textColor),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButtonStyle),
    outlinedButtonTheme: OutlinedButtonThemeData(style: secondaryButtonStyle),
    textButtonTheme: TextButtonThemeData(style: textButtonStyle),
    iconTheme: const IconThemeData(color: textColor, size: 24),
    iconButtonTheme: IconButtonThemeData(style: iconButtonStyle),
    inputDecorationTheme: inputDecorationTheme,
    dividerTheme:
        const DividerThemeData(color: disabledColor, thickness: 0.5, space: 1),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: primaryColor.withOpacity(0.1),
      labelTextStyle: WidgetStateProperty.all(
        GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
      ),
      iconTheme: WidgetStateProperty.all(
        const IconThemeData(size: 24),
      ),
      elevation: 2,
    ),
    useMaterial3: false,
  );

  // Dark Theme Data
  static ThemeData darkTheme = ThemeData(
    primaryColor: darkPrimaryColor,
    colorScheme: ColorScheme.dark(
      primary: darkPrimaryColor,
      secondary: darkAccentColor,
      error: errorColor,
      surface: darkSurfaceColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: darkTextColor,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: darkBackgroundColor,
    appBarTheme: AppBarTheme(
      backgroundColor: darkSurfaceColor,
      elevation: 0,
      centerTitle: false,
      iconTheme: const IconThemeData(color: Colors.white),
      actionsIconTheme: const IconThemeData(color: Colors.white),
      titleSpacing: defaultPadding,
      toolbarHeight: 60,
      titleTextStyle: GoogleFonts.poppins(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardTheme(
      color: darkCardColor,
      elevation: cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      clipBehavior: Clip.antiAlias,
    ),
    tabBarTheme: TabBarTheme(
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white.withOpacity(0.7),
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: GoogleFonts.poppins(
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
      unselectedLabelStyle: GoogleFonts.poppins(
        fontWeight: FontWeight.w400,
        fontSize: 14,
      ),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: darkSurfaceColor,
      elevation: dialogElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      titleTextStyle: GoogleFonts.poppins(
        color: darkTextColor,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: darkCardColor,
      contentTextStyle: GoogleFonts.poppins(
        color: darkTextColor,
        fontSize: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: darkCardColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      textStyle: GoogleFonts.poppins(
        color: darkTextColor,
        fontSize: 12,
      ),
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.poppins(
          fontSize: 28, fontWeight: FontWeight.bold, color: darkTextColor),
      displayMedium: GoogleFonts.poppins(
          fontSize: 24, fontWeight: FontWeight.bold, color: darkTextColor),
      displaySmall: GoogleFonts.poppins(
          fontSize: 20, fontWeight: FontWeight.bold, color: darkTextColor),
      headlineMedium: GoogleFonts.poppins(
          fontSize: 18, fontWeight: FontWeight.w600, color: darkTextColor),
      headlineSmall: GoogleFonts.poppins(
          fontSize: 16, fontWeight: FontWeight.w600, color: darkTextColor),
      titleLarge: GoogleFonts.poppins(
          fontSize: 14, fontWeight: FontWeight.w600, color: darkTextColor),
      bodyLarge:
          GoogleFonts.poppins(fontSize: 16, color: darkTextColor, height: 1.5),
      bodyMedium:
          GoogleFonts.poppins(fontSize: 14, color: darkTextColor, height: 1.5),
      bodySmall: GoogleFonts.poppins(
          fontSize: 12, color: darkSecondaryTextColor, height: 1.5),
      labelLarge: GoogleFonts.poppins(
          fontSize: 14, fontWeight: FontWeight.w500, color: darkTextColor),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: darkPrimaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w500),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: darkPrimaryColor,
        side: const BorderSide(color: darkPrimaryColor),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w500),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: darkPrimaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w500),
      ),
    ),
    iconTheme: const IconThemeData(color: darkTextColor, size: 24),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: darkPrimaryColor,
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: const BorderSide(color: darkDividerColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: const BorderSide(color: darkDividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: const BorderSide(color: darkPrimaryColor),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: const BorderSide(color: errorColor),
      ),
      filled: true,
      fillColor: darkCardColor,
      hintStyle: TextStyle(color: darkSecondaryTextColor.withOpacity(0.7)),
    ),
    dividerTheme: const DividerThemeData(
        color: darkDividerColor, thickness: 0.5, space: 1),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: darkPrimaryColor,
      foregroundColor: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: darkSurfaceColor,
      indicatorColor: darkPrimaryColor.withOpacity(0.2),
      labelTextStyle: WidgetStateProperty.all(
        GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
      ),
      iconTheme: WidgetStateProperty.all(
        const IconThemeData(size: 24),
      ),
      elevation: 2,
    ),
    useMaterial3: false,
  );
}
