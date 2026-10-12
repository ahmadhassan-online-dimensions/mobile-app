import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// VUE & OR design tokens, from the "Mobile App Redesign" wireframes.
class AppColors {
  // Grounds
  static const cream = Color(0xFFF6F2EC);
  static const paper = Color(0xFFFDFBF7); // cards, inputs
  static const sand = Color(0xFFEDE6DA); // soft panels
  static const stone = Color(0xFFE4DCCD); // image placeholders
  static const dark = Color(0xFF1A1612); // film / hero / lens guide panel
  static const darkSoft = Color(0xFF2A241F);

  // Ink
  static const ink = Color(0xFF16120E);
  static const text = Color(0xFF3D3630);
  static const muted = Color(0xFF6E655B);
  static const onDark = Color(0xFFF3EDE4);
  static const onDarkMuted = Color(0xFFB9AFA2);

  // Gold
  static const gold = Color(0xFF8C7040); // text on light (AA contrast)
  static const goldBright = Color(0xFFC9A45C); // accents, text on dark
  static const plated = Color(0xFFD9D4CB);

  static const line = Color(0xFFE2D9CB);
  static const lineStrong = Color(0xFFCFC4B3);
  static const error = Color(0xFFA3342B);

  // Splash / launcher icon ground (matches the VUE & OR logo artwork).
  static const brandCream = Color(0xFFEFE8DE);
  static const brandCreamLight = Color(0xFFF7F2EB);
}

/// Cormorant Garamond (display, with italic accents) + Manrope (UI).
/// Widget tests switch [useGoogleFonts] off so nothing is fetched.
class AppText {
  static bool useGoogleFonts = true;

  static TextStyle serif({
    double size = 16,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.ink,
    double? height,
    double? letterSpacing,
    bool italic = false,
  }) {
    final base = TextStyle(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
    );
    return useGoogleFonts ? GoogleFonts.cormorantGaramond(textStyle: base) : base.copyWith(fontFamily: 'serif');
  }

  static TextStyle sans({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.text,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
  }) {
    final base = TextStyle(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      decoration: decoration,
      decorationColor: color,
    );
    return useGoogleFonts ? GoogleFonts.manrope(textStyle: base) : base;
  }

  /// "THE COLLECTION" — gold spaced capitals above headings.
  static TextStyle eyebrow({Color color = AppColors.gold}) =>
      sans(size: 11.5, weight: FontWeight.w600, color: color, letterSpacing: 2.4);

  /// Small spaced capitals for labels on photos and section titles.
  static TextStyle caps({Color color = AppColors.muted, double size = 11}) =>
      sans(size: size, weight: FontWeight.w500, color: color, letterSpacing: 1.8);

  /// Button labels: "ENTER THE COLLECTION".
  static TextStyle button({Color color = Colors.white}) =>
      sans(size: 13, weight: FontWeight.w600, color: color, letterSpacing: 2.6);

  static TextStyle display({Color color = AppColors.ink, double size = 46, bool italic = false}) =>
      serif(size: size, weight: FontWeight.w400, color: color, height: 1.05, italic: italic);

  static TextStyle h1({Color color = AppColors.ink, bool italic = false}) =>
      serif(size: 38, weight: FontWeight.w400, color: color, height: 1.08, italic: italic);

  static TextStyle h2({Color color = AppColors.ink, bool italic = false}) =>
      serif(size: 30, weight: FontWeight.w400, color: color, height: 1.12, italic: italic);

  static TextStyle h3({Color color = AppColors.ink}) =>
      serif(size: 26, weight: FontWeight.w500, color: color, height: 1.15);

  static TextStyle body({Color color = AppColors.text, double size = 15}) =>
      sans(size: size, color: color, height: 1.55);
}

ThemeData buildTheme() {
  final base = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.goldBright,
      primary: AppColors.ink,
      onPrimary: Colors.white,
      secondary: AppColors.gold,
      surface: AppColors.cream,
      onSurface: AppColors.ink,
      error: AppColors.error,
    ),
    scaffoldBackgroundColor: AppColors.cream,
  );

  const square = RoundedRectangleBorder(borderRadius: BorderRadius.zero);
  final textTheme = base.textTheme.apply(
    fontFamily: AppText.sans().fontFamily,
    bodyColor: AppColors.text,
    displayColor: AppColors.ink,
  );

  return base.copyWith(
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.cream,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      foregroundColor: AppColors.ink,
      titleTextStyle: AppText.caps(color: AppColors.ink, size: 12.5),
      shape: const Border(bottom: BorderSide(color: AppColors.line)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.ink,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.lineStrong,
        disabledForegroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(48, 56),
        shape: square,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        textStyle: AppText.button(),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        side: const BorderSide(color: AppColors.ink),
        minimumSize: const Size(48, 52),
        shape: square,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        textStyle: AppText.button(color: AppColors.ink),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.ink,
        minimumSize: const Size(48, 48),
        textStyle: AppText.sans(size: 14, weight: FontWeight.w500),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.paper,
      labelStyle: AppText.sans(size: 14, color: AppColors.muted),
      floatingLabelStyle: AppText.sans(size: 13, color: AppColors.gold),
      hintStyle: AppText.sans(size: 15, color: AppColors.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: AppColors.line),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: AppColors.line),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: AppColors.ink),
      ),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1, space: 1),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.ink,
      behavior: SnackBarBehavior.floating,
      shape: square,
      contentTextStyle: AppText.sans(size: 14, color: Colors.white),
      actionTextColor: AppColors.goldBright,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.goldBright),
    checkboxTheme: CheckboxThemeData(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? AppColors.ink : Colors.transparent,
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {TargetPlatform.android: FadeForwardsPageTransitionsBuilder()},
    ),
  );
}

/// AED 9,800 style price.
String formatAed(num amount) {
  final whole = amount.round().toString();
  final buf = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    if (i > 0 && (whole.length - i) % 3 == 0) buf.write(',');
    buf.write(whole[i]);
  }
  return 'AED $buf';
}
