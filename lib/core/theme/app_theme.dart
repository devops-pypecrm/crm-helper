import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Same brand green Dad-mobile uses everywhere (nav bar, buttons, cards) —
/// was `Colors.indigo` before, a leftover default that didn't match the
/// main CRM app at all despite this being its own companion.
const kBrandColor = Color(0xFF578732);
const kBrandSurface = Color(0xFFF9FAEF);

/// Darker/lighter steps off [kBrandColor] used to build a richer
/// [ColorScheme] than `colorSchemeSeed` alone produces, plus the soft
/// colored-shadow look used by [PremiumCard]/[PrimaryButton] — Material's
/// own elevation system only shades shadows black, so anywhere this app
/// wants a tinted shadow it has to build the `BoxShadow` itself from these.
const kBrandColorDark = Color(0xFF3F6424);
const kBrandColorLight = Color(0xFF8FBE6B);

/// Corner radius used for cards, inputs, and sheets across the app —
/// bumped up from the old 14-18px Material default to read as softer and
/// more "iOS-bubbly".
const kCardRadius = 22.0;
const kButtonRadius = 999.0; // fully pill-shaped
const kButtonHeight = 52.0;

class AppTheme {
  AppTheme._();

  static final ColorScheme _colorScheme = ColorScheme.fromSeed(
    seedColor: kBrandColor,
    brightness: Brightness.light,
  ).copyWith(
    primary: kBrandColor,
    secondary: kBrandColorDark,
    surface: Colors.white,
    surfaceTint: Colors.transparent,
  );

  static ThemeData light = ThemeData(
    useMaterial3: true,
    colorScheme: _colorScheme,
    scaffoldBackgroundColor: const Color(0xFFFBFCF8),
    textTheme: GoogleFonts.plusJakartaSansTextTheme().apply(
      bodyColor: const Color(0xFF1B1F17),
      displayColor: const Color(0xFF1B1F17),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFFFBFCF8),
      foregroundColor: const Color(0xFF1B1F17),
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF1B1F17),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: kBrandColor,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(kButtonHeight),
        textStyle: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700),
        shape: const StadiumBorder(),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kBrandColor,
        side: const BorderSide(color: kBrandColor, width: 1.4),
        minimumSize: const Size.fromHeight(kButtonHeight),
        textStyle: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700),
        shape: const StadiumBorder(),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: kBrandColor,
        textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        shape: const StadiumBorder(),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kCardRadius)),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kBrandSurface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: kBrandColor, width: 1.6),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: kBrandColor),
    // Default Material icon size (24) read as slightly small/timid next to
    // this app's bigger status/action icons — nudged up a touch app-wide.
    iconTheme: const IconThemeData(size: 26, color: Color(0xFF1B1F17)),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? kBrandColor : null,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? kBrandColor.withValues(alpha: 0.4) : null,
      ),
    ),
    dividerTheme: const DividerThemeData(color: Color(0xFFE7E9E0), space: 24, thickness: 1),
  );
}
