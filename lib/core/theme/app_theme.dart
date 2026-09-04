import 'package:flutter/material.dart';

/// Same brand green Dad-mobile uses everywhere (nav bar, buttons, cards) —
/// was `Colors.indigo` before, a leftover default that didn't match the
/// main CRM app at all despite this being its own companion.
const kBrandColor = Color(0xFF578732);
const kBrandSurface = Color(0xFFF9FAEF);

class AppTheme {
  AppTheme._();

  static ThemeData light = ThemeData(
    useMaterial3: true,
    colorSchemeSeed: kBrandColor,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: kBrandColor,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kBrandColor,
        side: const BorderSide(color: kBrandColor),
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      shadowColor: Colors.black.withValues(alpha: 0.06),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kBrandSurface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: kBrandColor),
    // Default Material icon size (24) read as slightly small/timid next to
    // this app's bigger status/action icons — nudged up a touch app-wide.
    iconTheme: const IconThemeData(size: 26),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? kBrandColor : null,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? kBrandColor.withValues(alpha: 0.4) : null,
      ),
    ),
  );
}
