import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class C {
  static const red = Color(0xFFB71C1C);
  static const redDark = Color(0xFF8E1515);
  static const redLight = Color(0xFFE53935);
  static const yellow = Color(0xFFFFC107);
  static const cream = Color(0xFFFFF6DC);
  static const peach = Color(0xFFFFE3D9);
  static const bg = Color(0xFFFAFAFB);
  static const field = Color(0xFFF2F2F5);
  static const softCard = Color(0xFFF7F7F9);
  static const ink = Color(0xFF1B1B1F);
  static const grey = Color(0xFF7A7A85);
  static const line = Color(0xFFE9E9EE);
  static const green = Color(0xFF1F8A4C);
  static const greenBg = Color(0xFFDDF3E5);
  static const blue = Color(0xFF1D5FB8);
  static const blueBg = Color(0xFFDCEBFF);
  static const pinkBg = Color(0xFFF9D9D9);

  static const heroGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFD9CC), Color(0xFFFFEFE8), Color(0xFFFFF7E6)]);
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
        seedColor: C.red,
        primary: C.red,
        secondary: C.yellow,
        surface: Colors.white),
    scaffoldBackgroundColor: C.bg,
  );
  OutlineInputBorder b(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: c, width: w));
  return base.copyWith(
    textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme)
        .apply(bodyColor: C.ink, displayColor: C.ink),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: C.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      toolbarHeight: 62,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 19, fontWeight: FontWeight.w700, color: C.ink),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: C.field,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
      border: b(Colors.transparent),
      enabledBorder: b(Colors.transparent),
      focusedBorder: b(C.red.withOpacity(.75), 1.5),
      errorBorder: b(Colors.red.shade300, 1.2),
      focusedErrorBorder: b(Colors.red.shade400, 1.5),
      hintStyle: GoogleFonts.plusJakartaSans(color: C.grey, fontSize: 14),
      labelStyle: GoogleFonts.plusJakartaSans(color: C.grey, fontSize: 14),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      indicatorColor: Colors.transparent,
      elevation: 0,
      height: 72,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStateProperty.resolveWith((s) =>
          GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: s.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w500,
              color: s.contains(WidgetState.selected) ? C.red : C.grey)),
      iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
          size: 25, color: s.contains(WidgetState.selected) ? C.red : C.grey)),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: SharedAxisPageTransitionsBuilder(
          transitionType: SharedAxisTransitionType.horizontal, fillColor: C.bg),
      TargetPlatform.iOS: SharedAxisPageTransitionsBuilder(
          transitionType: SharedAxisTransitionType.horizontal, fillColor: C.bg),
    }),
    bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white, surfaceTintColor: Colors.transparent),
    snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
  );
}
