import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SpendlyColors {
  // Primary palette — Deep Navy + Electric Indigo
  static const Color primary = Color(0xFF4F46E5);        // Indigo 600
  static const Color primaryDark = Color(0xFF3730A3);    // Indigo 800
  static const Color primaryLight = Color(0xFF818CF8);   // Indigo 400
  static const Color secondary = Color(0xFF10B981);      // Emerald 500
  static const Color secondaryDark = Color(0xFF059669);  // Emerald 600

  // Semantic colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Neutral palette
  static const Color neutral50 = Color(0xFFF8FAFC);
  static const Color neutral100 = Color(0xFFF1F5F9);
  static const Color neutral200 = Color(0xFFE2E8F0);
  static const Color neutral300 = Color(0xFFCBD5E1);
  static const Color neutral400 = Color(0xFF94A3B8);
  static const Color neutral500 = Color(0xFF64748B);
  static const Color neutral600 = Color(0xFF475569);
  static const Color neutral700 = Color(0xFF334155);
  static const Color neutral800 = Color(0xFF1E293B);
  static const Color neutral900 = Color(0xFF0F172A);

  // Dark theme surfaces
  static const Color darkSurface = Color(0xFF0F172A);
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkCardElevated = Color(0xFF283548);

  // Chart colors
  static const List<Color> chartColors = [
    Color(0xFF6366F1),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
    Color(0xFF3B82F6),
    Color(0xFFEC4899),
    Color(0xFF14B8A6),
    Color(0xFFF97316),
    Color(0xFF84CC16),
  ];

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

// ─── Centralised text style constants ────────────────────────────────────────
/// Use these instead of hardcoding TextStyle throughout the app.
class AppTextStyles {
  AppTextStyles._();

  // ── Light-theme styles ────────────────────────────────────────────
  static TextStyle heading1({Color? color}) => GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.0,
        color: color,
      );

  static TextStyle heading2({Color? color}) => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: color,
      );

  static TextStyle sectionLabel({Color? color}) => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
        color: color,
      );

  static TextStyle bodyPrimary({Color? color}) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.5,
        color: color,
      );

  static TextStyle bodySecondary({Color? color}) => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: color,
      );

  static TextStyle caption({Color? color}) => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: color,
      );

  /// Selected chip label (white on primary background)
  static TextStyle chipSelected() => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      );

  /// Unselected chip label (dark on light background)
  static TextStyle chipUnselected() => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: SpendlyColors.neutral700,
      );

  /// Button label
  static TextStyle button() => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      );
}

class SpendlyTheme {
  static TextTheme _buildTextTheme(Color textColor) {
    final base = GoogleFonts.interTextTheme().apply(
      bodyColor: textColor,
      displayColor: textColor,
    );
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -1.0,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        height: 1.5,
      ),
    );
  }

  static ThemeData get lightTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: SpendlyColors.primary,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFE0E7FF),
      onPrimaryContainer: SpendlyColors.primaryDark,
      secondary: SpendlyColors.secondary,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFD1FAE5),
      onSecondaryContainer: SpendlyColors.secondaryDark,
      error: SpendlyColors.danger,
      onError: Colors.white,
      surface: SpendlyColors.neutral50,
      onSurface: SpendlyColors.neutral900,
      surfaceContainerHighest: SpendlyColors.neutral100,
      onSurfaceVariant: SpendlyColors.neutral600,
      outline: SpendlyColors.neutral200,
      outlineVariant: SpendlyColors.neutral100,
      shadow: SpendlyColors.neutral900,
      inverseSurface: SpendlyColors.neutral900,
      onInverseSurface: Colors.white,
      inversePrimary: SpendlyColors.primaryLight,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: _buildTextTheme(SpendlyColors.neutral900),
      scaffoldBackgroundColor: SpendlyColors.neutral100,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: Colors.white,
        shadowColor: SpendlyColors.neutral900.withAlpha(20),
        surfaceTintColor: Colors.transparent,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: SpendlyColors.neutral900,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: SpendlyColors.neutral200,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: SpendlyColors.neutral900,
          letterSpacing: -0.3,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: SpendlyColors.primary,
        unselectedItemColor: SpendlyColors.neutral400,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: SpendlyColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: SpendlyColors.primary,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: const BorderSide(color: SpendlyColors.primary, width: 1.5),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: SpendlyColors.primary,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: SpendlyColors.neutral100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SpendlyColors.neutral200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SpendlyColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SpendlyColors.danger),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.inter(
          color: SpendlyColors.neutral400,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: GoogleFonts.inter(
          color: SpendlyColors.neutral600,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: GoogleFonts.inter(
          color: SpendlyColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
      // ── Chip theme — FIXED ──────────────────────────────────────────────
      // Selected chips now use a solid primary background with white text,
      // making them clearly distinguishable from the unselected state.
      chipTheme: ChipThemeData(
        backgroundColor: SpendlyColors.neutral200,
        // Solid primary background for selected state (was nearly invisible alpha-25)
        selectedColor: SpendlyColors.primary,
        checkmarkColor: Colors.white,
        disabledColor: SpendlyColors.neutral200,
        labelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
          fontSize: 13,
          color: SpendlyColors.neutral700,
        ),
        secondaryLabelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        showCheckmark: false,
      ),
      dividerTheme: const DividerThemeData(
        color: SpendlyColors.neutral100,
        thickness: 1,
        space: 1,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: SpendlyColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: SpendlyColors.neutral900,
        contentTextStyle: GoogleFonts.inter(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: SpendlyColors.neutral900,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        backgroundColor: Colors.white,
      ),
    );
  }

  static ThemeData get darkTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: SpendlyColors.primaryLight,
      onPrimary: SpendlyColors.neutral900,
      primaryContainer: SpendlyColors.primaryDark,
      onPrimaryContainer: SpendlyColors.primaryLight,
      secondary: SpendlyColors.secondary,
      onSecondary: SpendlyColors.neutral900,
      secondaryContainer: Color(0xFF065F46),
      onSecondaryContainer: Color(0xFFD1FAE5),
      error: SpendlyColors.danger,
      onError: Colors.white,
      surface: SpendlyColors.darkSurface,
      onSurface: Colors.white,
      surfaceContainerHighest: SpendlyColors.darkCardElevated,
      onSurfaceVariant: SpendlyColors.neutral400,
      outline: SpendlyColors.neutral700,
      outlineVariant: SpendlyColors.neutral800,
      shadow: Colors.black,
      inverseSurface: Colors.white,
      onInverseSurface: SpendlyColors.neutral900,
      inversePrimary: SpendlyColors.primary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: _buildTextTheme(Colors.white),
      scaffoldBackgroundColor: SpendlyColors.darkSurface,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: SpendlyColors.darkCardElevated,
        surfaceTintColor: Colors.transparent,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: SpendlyColors.darkCard,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.8,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: -0.3,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: SpendlyColors.darkCardElevated,
        selectedItemColor: SpendlyColors.primaryLight,
        unselectedItemColor: SpendlyColors.neutral600,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: SpendlyColors.primaryLight,
          foregroundColor: SpendlyColors.neutral900,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: SpendlyColors.darkCardElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SpendlyColors.neutral700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: SpendlyColors.primaryLight, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.inter(color: SpendlyColors.neutral500),
        labelStyle: GoogleFonts.inter(
          color: SpendlyColors.neutral400,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: GoogleFonts.inter(
          color: SpendlyColors.primaryLight,
          fontWeight: FontWeight.w600,
        ),
      ),
      // ── Dark chip theme — FIXED ────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: SpendlyColors.neutral700,
        selectedColor: SpendlyColors.primaryLight,
        checkmarkColor: SpendlyColors.neutral900,
        disabledColor: SpendlyColors.neutral800,
        labelStyle: GoogleFonts.inter(
          color: SpendlyColors.neutral300,
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        secondaryLabelStyle: GoogleFonts.inter(
          color: SpendlyColors.neutral900,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide.none,
        showCheckmark: false,
      ),
      dividerTheme: const DividerThemeData(
        color: SpendlyColors.neutral700,
        thickness: 1,
        space: 1,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: SpendlyColors.primaryLight,
        foregroundColor: SpendlyColors.neutral900,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: SpendlyColors.neutral800,
        contentTextStyle: GoogleFonts.inter(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: SpendlyColors.darkCardElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        backgroundColor: SpendlyColors.darkCardElevated,
      ),
    );
  }
}
