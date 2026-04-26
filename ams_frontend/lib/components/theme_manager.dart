import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeManager {
  ThemeManager._();

  // ── Helper ────────────────────────────────────────────────────
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  // ═════════════════════════════════════════════════════════════
  // STATIC TOKENS — dark mode constants (backward compatibility)
  // ═════════════════════════════════════════════════════════════

  // ── Background ────────────────────────────────────────────────
  static const Color bgBase  = Color(0xFF0A0A0F);
  static const Color bgBase2 = Color(0xFF0D0D10);

  // ── Brand ─────────────────────────────────────────────────────
  static const Color brand      = Color(0xFF1B3769);
  static const Color brandLight = Color(0xFF2D5299);

  // ── Surfaces (dark) ───────────────────────────────────────────
  static const Color surfaceBg           = Color(0x14162B4C);
  static const Color surfaceBorder       = Color(0x332D5299);
  static const Color surfaceBorderStrong = Color(0x4D2D5299);
  static const Color divider             = Color(0x262D5299);

  // ── Accents ───────────────────────────────────────────────────
  static const Color accentBlue   = Color(0xFF60A5FA);
  static const Color accentGreen  = Color(0xFF34D399);
  static const Color accentPink   = Color(0xFFF472B6);
  static const Color accentPurple = Color(0xFFA78BFA);

  // ── Text (dark) ───────────────────────────────────────────────
  static const Color textPrimary   = Color(0xE6FFFFFF);
  static const Color textBody      = Color(0xD9FFFFFF);
  static const Color textSecondary = Color(0x80FFFFFF);
  static const Color textMuted     = Color(0x66FFFFFF);
  static const Color textHint      = Color(0x59FFFFFF);
  static const Color textFaint     = Color(0x33FFFFFF);

  // ── Error ─────────────────────────────────────────────────────
  static const Color errorBg     = Color(0x1AEF4444);
  static const Color errorBorder = Color(0x33EF4444);
  static const Color errorText   = Color(0xFFFC8181);

  // ── Input (dark) ──────────────────────────────────────────────
  static const Color inputFill    = Color(0x0F1B3769);
  static const Color inputBorder  = Color(0x262D5299);
  static const Color inputFocused = Color(0xFF60A5FA);
  static const Color inputError   = Color(0xFFFC8181);

  // ── Radius ────────────────────────────────────────────────────
  static const double radiusCard  = 16.0;
  static const double radiusInner = 12.0;
  static const double radiusBtn   = 10.0;
  static const double radiusTag   =  6.0;

  // ═════════════════════════════════════════════════════════════
  // CONTEXT-AWARE TOKENS
  // Both modes share the same brand/accent palette.
  // Light mode: crisp white surfaces with blue-tinted frost edges.
  // Dark mode : original glass-morphism tokens above.
  // ═════════════════════════════════════════════════════════════

  // ── Backgrounds ───────────────────────────────────────────────
  /// Page background — near-black vs pure white-blue frost
  static Color bg(BuildContext context) => isDark(context)
      ? const Color(0xFF0A0A0F)
      : const Color(0xFFF0F4FF);

  /// Secondary background (card interiors, tab content area)
  static Color bg2(BuildContext context) => isDark(context)
      ? const Color(0xFF0D1120)
      : const Color(0xFFF8FAFF);

  /// Scaffold-level base (matches Scaffold backgroundColor)
  static Color scaffold(BuildContext context) => isDark(context)
      ? const Color(0xFF0A0A0F)
      : const Color(0xFFEEF2FF);

  // ── Surfaces ──────────────────────────────────────────────────
  /// Card / panel fill
  static Color surface(BuildContext context) => isDark(context)
      ? const Color(0x14162B4C)   // dark: translucent navy
      : const Color(0xFFFFFFFF);  // light: pure white

  /// Elevated surface (form cards, landscape panel)
  static Color surfaceElevated(BuildContext context) => isDark(context)
      ? const Color(0xFF111827)
      : const Color(0xFFFFFFFF);
  
  static Color surfaceElevatedDarker(BuildContext context) =>
      isDark(context) ? const Color.fromARGB(255, 12, 17, 29) : const Color(0xFFFFFFFF);

  /// Subtle tint for hover / active states
  static Color surfaceTint(BuildContext context) => isDark(context)
      ? const Color(0x1A1B3769)
      : const Color(0xFFEBF0FF);

  // ── Borders ───────────────────────────────────────────────────
  /// Default card border
  static Color border(BuildContext context) => isDark(context)
      ? const Color(0x332D5299)
      : const Color(0xFFBFCFEC);

  /// Stronger border (form cards, focused containers)
  static Color borderStrong(BuildContext context) => isDark(context)
      ? const Color(0x4D2D5299)
      : const Color(0xFF93AFDF);

  /// Hairline divider
  static Color dividerColor(BuildContext context) => isDark(context)
      ? const Color(0x262D5299)
      : const Color(0xFFDDE6F5);

  // ── Text ──────────────────────────────────────────────────────
  static Color primary(BuildContext context) => isDark(context)
      ? const Color(0xE6FFFFFF)   // 90 % white
      : const Color(0xFF0D1A33);  // deep navy

  static Color bodyColor(BuildContext context) => isDark(context)
      ? const Color(0xD9FFFFFF)   // 85 % white
      : const Color(0xFF1E3050);

  static Color secondary(BuildContext context) => isDark(context)
      ? const Color(0x80FFFFFF)   // 50 % white
      : const Color(0xFF4A6490);

  static Color muted(BuildContext context) => isDark(context)
      ? const Color(0x66FFFFFF)   // 40 % white
      : const Color(0xFF6A84B0);

  static Color hint(BuildContext context) => isDark(context)
      ? const Color(0x59FFFFFF)   // 35 % white
      : const Color(0xFF8BA3C4);

  static Color faint(BuildContext context) => isDark(context)
      ? const Color(0x33FFFFFF)   // 20 % white
      : const Color(0xFFB8CADE);

  // ── Accents (context-aware — slightly brighter on light) ──────
  static Color blue(BuildContext context) => isDark(context)
      ? const Color(0xFF60A5FA)
      : const Color(0xFF2563EB);

  static Color green(BuildContext context) => isDark(context)
      ? const Color(0xFF34D399)
      : const Color(0xFF059669);

  static Color pink(BuildContext context) => isDark(context)
      ? const Color(0xFFF472B6)
      : const Color(0xFFDB2777);

  static Color purple(BuildContext context) => isDark(context)
      ? const Color(0xFFA78BFA)
      : const Color(0xFF7C3AED);

  // ── Input ─────────────────────────────────────────────────────
  static Color inputFillColor(BuildContext context) => isDark(context)
      ? const Color(0x0F1B3769)
      : const Color(0xFFF5F8FF);

  static Color inputBorderColor(BuildContext context) => isDark(context)
      ? const Color(0x262D5299)
      : const Color(0xFFBFD0ED);

  static Color inputFocusedColor(BuildContext context) => isDark(context)
      ? const Color(0xFF60A5FA)
      : const Color(0xFF2563EB);

  static Color inputLabelColor(BuildContext context) => isDark(context)
      ? const Color(0x80FFFFFF)
      : const Color(0xFF4A6490);

  static Color inputHintColor(BuildContext context) => isDark(context)
      ? const Color(0x33FFFFFF)
      : const Color(0xFFACC0D8);

  static Color inputIconColor(BuildContext context) => isDark(context)
      ? const Color(0x60FFFFFF)
      : const Color(0xFF7A9AC0);

  // ── Error ─────────────────────────────────────────────────────
  static Color errorBgColor(BuildContext context) => isDark(context)
      ? const Color(0x1AEF4444)
      : const Color(0xFFFFF0F0);

  static Color errorBorderColor(BuildContext context) => isDark(context)
      ? const Color(0x33EF4444)
      : const Color(0xFFFFCDD2);

  static Color errorTextColor(BuildContext context) => isDark(context)
      ? const Color(0xFFFC8181)
      : const Color(0xFFDC2626);

  // ── Toggle icon (☀ / 🌙 button) ──────────────────────────────
  static Color toggleIcon(BuildContext context) => isDark(context)
      ? const Color(0x80FFFFFF)
      : const Color(0xFF4A6490);

  // ═════════════════════════════════════════════════════════════
  // CONTEXT-AWARE TEXT STYLES
  // ═════════════════════════════════════════════════════════════

  static TextStyle heroStyle(BuildContext context) => GoogleFonts.dmSans(
    fontSize: 48,
    fontWeight: FontWeight.w800,
    color: primary(context),
    height: 1.1,
    letterSpacing: -1.5,
  );

  static TextStyle titleStyle(BuildContext context) => GoogleFonts.dmSans(
    fontSize: 22,
    fontWeight: FontWeight.w900,
    color: primary(context),
    letterSpacing: 3,
  );

  static TextStyle subtitleStyle(BuildContext context) => GoogleFonts.dmSans(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: secondary(context),
  );

  static TextStyle labelStyle(BuildContext context) => GoogleFonts.dmSans(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: muted(context),
    letterSpacing: 0.5,
  );

  static TextStyle bodyStyle(BuildContext context) => GoogleFonts.dmSans(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: bodyColor(context),
  );

  static TextStyle buttonStyle(BuildContext context) => GoogleFonts.dmSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
    // Button text is always white (sits on brand-colored button bg)
    color: Colors.white,
  );

  // ── Static text styles (dark-only, backward compat) ───────────
  static TextStyle heroText = GoogleFonts.dmSans(
    fontSize: 48, fontWeight: FontWeight.w800,
    color: textPrimary, height: 1.1, letterSpacing: -1.5,
  );

  static TextStyle titleText = GoogleFonts.dmSans(
    fontSize: 22, fontWeight: FontWeight.w900,
    color: textPrimary, letterSpacing: 3,
  );

  static TextStyle subtitleText = GoogleFonts.dmSans(
    fontSize: 13, fontWeight: FontWeight.w400,
    color: textSecondary,
  );

  static TextStyle labelText = GoogleFonts.dmSans(
    fontSize: 11, fontWeight: FontWeight.w600,
    color: textMuted, letterSpacing: 0.5,
  );

  static TextStyle bodyText = GoogleFonts.dmSans(
    fontSize: 13, fontWeight: FontWeight.w400,
    color: textBody,
  );

  static TextStyle buttonText = GoogleFonts.dmSans(
    fontSize: 14, fontWeight: FontWeight.w600,
    letterSpacing: 0.3, color: Colors.white,
  );

  // ═════════════════════════════════════════════════════════════
  // CONTEXT-AWARE DECORATIONS
  // ═════════════════════════════════════════════════════════════

  /// Standard card (list items, info panels)
  static BoxDecoration cardDeco(BuildContext context) => BoxDecoration(
    color: surface(context),
    borderRadius: BorderRadius.circular(radiusCard),
    border: Border.all(color: border(context)),
    // Light mode gets a very subtle shadow instead of glow
    boxShadow: isDark(context)
        ? null
        : [BoxShadow(color: const Color(0xFF1B3769).withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4))],
  );

  /// Form / login card (heavier border, slightly different fill)
  static BoxDecoration formCardDeco(BuildContext context) => BoxDecoration(
    color: isDark(context) ? const Color(0x1A1B3769) : Colors.white,
    borderRadius: BorderRadius.circular(radiusCard),
    border: Border.all(color: borderStrong(context)),
    boxShadow: isDark(context)
        ? null
        : [BoxShadow(color: const Color(0xFF1B3769).withOpacity(0.10), blurRadius: 24, offset: const Offset(0, 8))],
  );

  /// Portrait header container (top panel on mobile)
  static BoxDecoration portraitHeaderDeco(BuildContext context) => BoxDecoration(
    color: isDark(context) ? Colors.transparent : const Color(0xFFEBF0FF),
  );

  /// Tab content panel (rounded top, sits below portrait header)
  static BoxDecoration tabPanelDeco(BuildContext context) => BoxDecoration(
    color: isDark(context) ? const Color(0xFF0D1120) : Colors.white,
    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
    border: Border(
      top: BorderSide(color: borderStrong(context)),
    ),
    boxShadow: isDark(context)
        ? null
        : [BoxShadow(color: const Color(0xFF1B3769).withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -4))],
  );

  // ═════════════════════════════════════════════════════════════
  // CONTEXT-AWARE INPUT DECORATION
  // ═════════════════════════════════════════════════════════════

  static InputDecoration inputDeco(
    BuildContext context, {
    required String label,
    required IconData icon,
    String? hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: GoogleFonts.dmSans(
        color: inputLabelColor(context),
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: GoogleFonts.dmSans(
        color: inputHintColor(context),
        fontSize: 13,
      ),
      prefixIcon: Icon(icon, size: 16, color: inputIconColor(context)),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: inputFillColor(context),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusInner),
        borderSide: BorderSide(color: inputBorderColor(context)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusInner),
        borderSide: BorderSide(color: inputBorderColor(context)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusInner),
        borderSide: BorderSide(color: inputFocusedColor(context), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusInner),
        borderSide: BorderSide(color: errorTextColor(context)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusInner),
        borderSide: BorderSide(color: errorTextColor(context), width: 1.5),
      ),
      errorStyle: GoogleFonts.dmSans(
        color: errorTextColor(context),
        fontSize: 11,
      ),
    );
  }

  // ── Static inputDecoration (dark-only, backward compat) ───────
  static InputDecoration inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: GoogleFonts.dmSans(
        color: const Color(0x80FFFFFF),
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: GoogleFonts.dmSans(color: const Color(0x33FFFFFF), fontSize: 13),
      prefixIcon: Icon(icon, size: 16, color: const Color(0x60FFFFFF)),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: inputFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusInner),
        borderSide: const BorderSide(color: inputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusInner),
        borderSide: const BorderSide(color: inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusInner),
        borderSide: const BorderSide(color: inputFocused, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusInner),
        borderSide: const BorderSide(color: inputError),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusInner),
        borderSide: const BorderSide(color: inputError, width: 1.5),
      ),
      errorStyle: GoogleFonts.dmSans(color: errorText, fontSize: 11),
    );
  }

  // ── Static decorations (dark-only, backward compat) ───────────
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: surfaceBg,
    borderRadius: BorderRadius.circular(radiusCard),
    border: Border.all(color: surfaceBorder),
  );

  static BoxDecoration get formCardDecoration => BoxDecoration(
    color: const Color(0x1A1B3769),
    borderRadius: BorderRadius.circular(radiusCard),
    border: Border.all(color: surfaceBorderStrong),
  );

  // ═════════════════════════════════════════════════════════════
  // THEME DATA FACTORIES
  // Call these in main.dart → MaterialApp(theme:, darkTheme:)
  // ═════════════════════════════════════════════════════════════

  static const Color _seed = Color(0xFF1B3769);

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seed,
      primary: _seed,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: const Color(0xFFEEF2FF),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((_) => Colors.transparent),
      checkColor: WidgetStateProperty.all(Colors.white),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((_) => _seed),
      trackColor: WidgetStateProperty.resolveWith((_) => const Color(0xFFBFCFEC)),
    ),
    timePickerTheme: TimePickerThemeData(
      backgroundColor: Colors.white,
      hourMinuteColor: _seed.withOpacity(0.10),
      hourMinuteTextColor: _seed,
      dialHandColor: _seed,
      dialBackgroundColor: _seed.withOpacity(0.06),
      entryModeIconColor: _seed,
      dayPeriodColor: _seed.withOpacity(0.10),
      dayPeriodTextColor: _seed,
      helpTextStyle: const TextStyle(fontWeight: FontWeight.w600),
    ),
    inputDecorationTheme: InputDecorationTheme(
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFF2563EB)),
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seed,
      primary: _seed,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF0A0A0F),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((_) => Colors.transparent),
      checkColor: WidgetStateProperty.all(Colors.white),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((_) => _seed),
      trackColor: WidgetStateProperty.resolveWith((_) => const Color(0xFFECECEC)),
    ),
    timePickerTheme: TimePickerThemeData(
      backgroundColor: const Color(0xFF111827),
      hourMinuteColor: _seed.withOpacity(0.12),
      hourMinuteTextColor: const Color(0xFF60A5FA),
      dialHandColor: const Color(0xFF60A5FA),
      dialBackgroundColor: _seed.withOpacity(0.08),
      entryModeIconColor: const Color(0xFF60A5FA),
      dayPeriodColor: _seed.withOpacity(0.12),
      dayPeriodTextColor: const Color(0xFF60A5FA),
      helpTextStyle: const TextStyle(fontWeight: FontWeight.w600),
    ),
    inputDecorationTheme: InputDecorationTheme(
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFF60A5FA)),
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );
}