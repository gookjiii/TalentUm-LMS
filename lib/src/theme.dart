import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SchoolColors {
  // ── Primary (Restrained Amethyst) ─────────────────────────────────
  static const primary = Color(0xFF6B4CA6); // Restrained Amethyst
  static const primaryLight = Color(0xFF8A6BBF);
  static const primaryDark = Color(0xFF4A2B84);
  static const primaryContainer = Color(0xFFF3EFFF);
  static const onPrimaryContainer = Color(0xFF2A0A64);

  // ── Secondary (Slate Neutrals) ────────────────────────────────────────
  static const secondary = Color(0xFF475569); // Slate 600
  static const secondaryLight = Color(0xFF64748B); // Slate 500
  static const secondaryContainer = Color(0xFFF1F5F9); // Slate 100
  static const onSecondaryContainer = Color(0xFF0F172A); // Slate 900

  // ── Accent / Emerald ───────────────────────────────────────
  static const accent = Color(0xFF059669);
  static const accentContainer = Color(0xFFD1FAE5);

  // ── Semantic Colors (WCAG AA Compliant on White) ──────────────
  static const green = Color(0xFF059669); // Emerald 600
  static const greenContainer = Color(0xFFD1FAE5);
  static const red = Color(0xFFDC2626); // Red 600
  static const redContainer = Color(0xFFFEE2E2);
  static const orange = Color(0xFFB45309); // Amber 700
  static const orangeContainer = Color(0xFFFFEDD5);
  static const yellow = Color(0xFFFBBC04);
  static const purple = Color(0xFF6B4CA6); // Primary Restrained Amethyst
  static const purpleContainer = Color(0xFFF3EFFF);


  // ── Light-mode Neutrals ───────────────────────────────────────
  static const bg = Color(0xFFF8FAFC); // Slate 50
  static const surface = Color(0xFFFFFFFF);
  static const surfaceElevated = Color(0xFFF1F5F9); // Slate 100
  static const text = Color(0xFF0F172A); // Ink Navy text
  static const textSecondary = Color(0xFF334155); // Slate 700
  static const muted = Color(0xFF64748B); // Slate 500
  static const border = Color(0xFFE2E8F0); // Slate 200
  static const borderFocus = Color(0xFFCBD5E1); // Slate 300

  // ── Dark-mode Palette ─────────────────────────────────────────
  static const darkBg = Color(0xFF0F172A); // Slate 900
  static const darkSurface = Color(0xFF1E293B); // Slate 800
  static const darkSurfaceElevated = Color(0xFF334155); // Slate 700
  static const darkBorder = Color(0xFF334155); // Slate 700
  static const darkText = Color(0xFFF8FAFC); // Slate 50
  static const darkTextSecondary = Color(0xFFCBD5E1); // Slate 300
  static const darkMuted = Color(0xFF94A3B8); // Slate 400

  // ── Sidebar ───────────────────────────────────────────────────
  static const sidebarBg = Color(0xFF0F172A); // Ink Navy
  static const sidebarBorder = Color(0xFF1E293B); // Slate 800

  // ── Chat Bubbles ──────────────────────────────────────────────
  static const chatBubbleStart = Color(0xFF6B4CA6);
  static const chatBubbleEnd = Color(0xFF8A6BBF);
  static const chatBubbleOther = Color(0xFFFFFFFF);
  static const chatBubbleOtherBorder = Color(0xFFE2E8F0);

  // ── Deleted Message Styling ─────────────────────────────────
  static const deletedBubble = Color(0xFFFEE2E2);
  static const deletedBubbleBorder = Color(0xFFFCA5A5);
  static const deletedBubbleText = Color(0xFF991B1B);
  static const deletedBubbleDark = Color(0xFF450A0A);
  static const deletedBubbleBorderDark = Color(0xFF7F1D1D);
  static const deletedBubbleTextDark = Color(0xFFFCA5A5);

  // ── Reply Deleted Styling ──────────────────────────────────
  static const replyDeletedBg = Color(0xFFF8FAFC);
  static const replyDeletedBorder = Color(0xFFCBD5E1);
  static const replyDeletedText = Color(0xFF64748B);

  // ── Soft Shadows (Neutral) ─────────────────────────
  static BoxShadow cardShadow = BoxShadow(
    color: Colors.black.withValues(alpha: 0.05), // Softer, more modern shadow
    blurRadius: 24,
    offset: const Offset(0, 8),
    spreadRadius: 0,
  );

  static BoxShadow cardShadowHover = BoxShadow(
    color: Colors.black.withValues(alpha: 0.08), // Neutral stronger on hover
    blurRadius: 24,
    offset: const Offset(0, 6),
    spreadRadius: 0,
  );

  static BoxShadow elevatedShadow = BoxShadow(
    color: Colors.black.withValues(alpha: 0.06),
    blurRadius: 24,
    offset: const Offset(0, 8),
  );

  // ── Elevation System ───────────────────────────────────────────
  static BoxShadow elevation1 = BoxShadow(
    color: Colors.black.withValues(alpha: 0.05),
    blurRadius: 10,
    offset: const Offset(0, 4),
  );
  
  static BoxShadow elevation2 = BoxShadow(
    color: Colors.black.withValues(alpha: 0.08),
    blurRadius: 20,
    offset: const Offset(0, 8),
  );

  static BoxShadow elevation3 = BoxShadow(
    color: Colors.black.withValues(alpha: 0.12),
    blurRadius: 30,
    offset: const Offset(0, 12),
  );

  static BoxShadow glassShadow = BoxShadow(
    color: Colors.black.withValues(alpha: 0.04),
    blurRadius: 40,
    spreadRadius: -4,
    offset: const Offset(0, 10),
  );
}

// ─────────────────────────────────────────────────────────────────
// DESIGN TOKENS
// ─────────────────────────────────────────────────────────────────
class AppSpacing {
  const AppSpacing._();
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;
}

class AppRadius {
  const AppRadius._();
  static const sm = BorderRadius.all(Radius.circular(8));
  static const md = BorderRadius.all(Radius.circular(12));
  static const lg = BorderRadius.all(Radius.circular(16));
  static const xl = BorderRadius.all(Radius.circular(20));
  static const full = BorderRadius.all(Radius.circular(999));
}

class AppTextStyle {
  const AppTextStyle._();
  static const labelSm = TextStyle(fontSize: 11, fontWeight: FontWeight.w600);
  static const labelMd = TextStyle(fontSize: 13, fontWeight: FontWeight.w600);
  static const bodyMd = TextStyle(fontSize: 15, fontWeight: FontWeight.w500);
  static const titleSm = TextStyle(fontSize: 18, fontWeight: FontWeight.w700);
  static const titleLg = TextStyle(fontSize: 24, fontWeight: FontWeight.w800);
  
  static TextStyle display(BuildContext context) => GoogleFonts.nunito(
        fontSize: 28,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.3,
        color: Theme.of(context).colorScheme.onSurface,
      );

  static TextStyle mono({double fontSize = 13, FontWeight fontWeight = FontWeight.w500, Color? color}) => 
      GoogleFonts.jetBrainsMono(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );
}

// ─────────────────────────────────────────────────────────────────
// LIGHT THEME
// ─────────────────────────────────────────────────────────────────
class NoAnimationPageTransitionsBuilder extends PageTransitionsBuilder {
  const NoAnimationPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}

ThemeData schoolTheme({Color primaryColor = SchoolColors.primary, bool isPerformance = false}) {
  final scheme = ColorScheme.fromSeed(
    seedColor: primaryColor,
    brightness: Brightness.light,
    primary: primaryColor,
    onPrimary: Colors.white,
    primaryContainer: SchoolColors.primaryContainer,
    onPrimaryContainer: SchoolColors.onPrimaryContainer,
    secondary: SchoolColors.secondary,
    onSecondary: Colors.white,
    secondaryContainer: SchoolColors.secondaryContainer,
    onSecondaryContainer: SchoolColors.onSecondaryContainer,
    tertiary: SchoolColors.accent,
    onTertiary: Colors.white,
    error: SchoolColors.red,
    surface: SchoolColors.surface,
    onSurface: SchoolColors.text,
    surfaceContainerHighest: SchoolColors.surfaceElevated,
    outlineVariant: SchoolColors.border,
  );

  final fallbackFonts = [
    'Apple Color Emoji',
    'Segoe UI Emoji',
    'Noto Color Emoji',
    'Android Emoji',
    'EmojiOne',
  ];

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    splashFactory: isPerformance ? NoSplash.splashFactory : null,
    pageTransitionsTheme: isPerformance
        ? const PageTransitionsTheme(
            builders: <TargetPlatform, PageTransitionsBuilder>{
              TargetPlatform.android: NoAnimationPageTransitionsBuilder(),
              TargetPlatform.iOS: NoAnimationPageTransitionsBuilder(),
              TargetPlatform.linux: NoAnimationPageTransitionsBuilder(),
              TargetPlatform.macOS: NoAnimationPageTransitionsBuilder(),
              TargetPlatform.windows: NoAnimationPageTransitionsBuilder(),
            },
          )
        : null,
    scaffoldBackgroundColor: SchoolColors.bg,
    textTheme: GoogleFonts.nunitoTextTheme(ThemeData.light().textTheme)
        .apply(
          fontFamilyFallback: fallbackFonts,
          bodyColor: SchoolColors.text,
          displayColor: SchoolColors.text,
        ),

    appBarTheme: AppBarTheme(
      backgroundColor: SchoolColors.bg,
      foregroundColor: SchoolColors.text,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: SchoolColors.border,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: GoogleFonts.nunito(
        color: SchoolColors.text,
        fontSize: 22,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.3,
      ).copyWith(fontFamilyFallback: fallbackFonts),
    ),

    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: SchoolColors.border, width: 1.2),
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        minimumSize: const WidgetStatePropertyAll(Size(64, 44)),
        textStyle: WidgetStatePropertyAll(
          GoogleFonts.nunito(
            fontWeight: FontWeight.w700,
            fontSize: 14.5,
            letterSpacing: -0.1,
          ),
        ),
        elevation: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) return 0;
          if (states.contains(WidgetState.hovered)) return 3;
          return 0;
        }),
        shadowColor: const WidgetStatePropertyAll(
          Colors.transparent,
        ),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        textStyle: GoogleFonts.nunito(
          fontWeight: FontWeight.w700,
          fontSize: 14.5,
          letterSpacing: -0.1,
        ),
        minimumSize: const Size(64, 44),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: const BorderSide(color: SchoolColors.border, width: 1.2),
        textStyle: GoogleFonts.nunito(
          fontWeight: FontWeight.w700,
          fontSize: 14.5,
          letterSpacing: -0.1,
        ),
        minimumSize: const Size(64, 44),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: GoogleFonts.nunito(
          fontWeight: FontWeight.w700,
          fontSize: 14.5,
          letterSpacing: -0.1,
        ),
      ),
    ),

    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.all(8),
        splashFactory: isPerformance ? NoSplash.splashFactory : InkRipple.splashFactory,
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: SchoolColors.border, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: SchoolColors.border, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: SchoolColors.red, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: SchoolColors.red, width: 1.5),
      ),
      labelStyle: GoogleFonts.nunito(
        color: SchoolColors.muted,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: GoogleFonts.nunito(
        color: SchoolColors.muted,
        fontWeight: FontWeight.w400,
      ),
      floatingLabelStyle: GoogleFonts.nunito(
        color: primaryColor,
        fontWeight: FontWeight.w700,
        fontSize: 13,
      ),
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      height: 68,
      indicatorColor: primaryColor.withValues(alpha: 0.08),
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return GoogleFonts.nunito(
            color: primaryColor,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          );
        }
        return GoogleFonts.nunito(
          color: SchoolColors.muted,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(color: primaryColor, size: 22);
        }
        return const IconThemeData(color: SchoolColors.muted, size: 22);
      }),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: SchoolColors.text,
      contentTextStyle: GoogleFonts.nunito(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 8,
    ),

    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      labelStyle: GoogleFonts.nunito(
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
    ),

    dividerTheme: const DividerThemeData(
      color: SchoolColors.border,
      space: 1,
      thickness: 1,
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 24,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: GoogleFonts.nunito(
        color: SchoolColors.text,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
      contentTextStyle: GoogleFonts.nunito(
        color: SchoolColors.textSecondary,
        fontSize: 14,
        height: 1.55,
      ),
    ),

    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      iconColor: SchoolColors.muted,
      titleTextStyle: GoogleFonts.nunito(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: SchoolColors.text,
      ),
    ),

    popupMenuTheme: PopupMenuThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: SchoolColors.text,
      ),
    ),

    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 16,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      showDragHandle: true,
      dragHandleColor: SchoolColors.border,
      dragHandleSize: const Size(40, 4),
    ),

    tabBarTheme: TabBarThemeData(
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: Colors.transparent,
      labelColor: primaryColor,
      unselectedLabelColor: SchoolColors.muted,
      labelStyle: GoogleFonts.nunito(
        fontWeight: FontWeight.w700,
        fontSize: 13,
      ),
      unselectedLabelStyle: GoogleFonts.nunito(
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      indicator: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: primaryColor.withValues(alpha: 0.08),
      ),
    ),

    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: SchoolColors.text,
        borderRadius: BorderRadius.circular(10),
      ),
      textStyle: GoogleFonts.nunito(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      waitDuration: const Duration(milliseconds: 400),
    ),

    searchBarTheme: SearchBarThemeData(
      backgroundColor: const WidgetStatePropertyAll(Color(0xFFF1F5F9)),
      shadowColor: const WidgetStatePropertyAll(Colors.transparent),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      elevation: const WidgetStatePropertyAll(0),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: SchoolColors.border, width: 1),
        ),
      ),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 12),
      ),
      textStyle: WidgetStatePropertyAll(
        GoogleFonts.nunito(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: SchoolColors.text,
        ),
      ),
      hintStyle: WidgetStatePropertyAll(
        GoogleFonts.nunito(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: SchoolColors.muted,
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────
// DARK THEME
// ─────────────────────────────────────────────────────────────────
ThemeData schoolDarkTheme({Color primaryColor = SchoolColors.primaryLight, bool isPerformance = false}) {
  final scheme = ColorScheme.fromSeed(
    seedColor: primaryColor,
    brightness: Brightness.dark,
    primary: primaryColor,
    onPrimary: const Color(0xFF001A3D),
    primaryContainer: const Color(0xFF1A3260),
    onPrimaryContainer: const Color(0xFFD0E4FF),
    secondary: SchoolColors.secondaryLight,
    onSecondary: const Color(0xFF1E1B4B),
    secondaryContainer: const Color(0xFF312E81),
    onSecondaryContainer: const Color(0xFFE0E7FF),
    tertiary: const Color(0xFF5EEAD4),
    onTertiary: const Color(0xFF003731),
    error: const Color(0xFFFF6B6B),
    surface: SchoolColors.darkSurface,
    onSurface: SchoolColors.darkText,
    surfaceContainerHighest: SchoolColors.darkSurfaceElevated,
    outline: const Color(0xFF2D4060),
    outlineVariant: const Color(0xFF1E2D45),
    surfaceTint: Colors.transparent,
  );

  final fallbackFonts = [
    'Apple Color Emoji',
    'Segoe UI Emoji',
    'Noto Color Emoji',
    'Android Emoji',
    'EmojiOne',
  ];

  final textTheme =
      GoogleFonts.nunitoTextTheme(ThemeData.dark().textTheme).apply(
        fontFamilyFallback: fallbackFonts,
        bodyColor: SchoolColors.darkText,
        displayColor: SchoolColors.darkText,
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    splashFactory: isPerformance ? NoSplash.splashFactory : null,
    pageTransitionsTheme: isPerformance
        ? const PageTransitionsTheme(
            builders: <TargetPlatform, PageTransitionsBuilder>{
              TargetPlatform.android: NoAnimationPageTransitionsBuilder(),
              TargetPlatform.iOS: NoAnimationPageTransitionsBuilder(),
              TargetPlatform.linux: NoAnimationPageTransitionsBuilder(),
              TargetPlatform.macOS: NoAnimationPageTransitionsBuilder(),
              TargetPlatform.windows: NoAnimationPageTransitionsBuilder(),
            },
          )
        : null,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: SchoolColors.darkBg,
    textTheme: textTheme,

    appBarTheme: AppBarTheme(
      backgroundColor: SchoolColors.darkBg,
      foregroundColor: SchoolColors.darkText,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: SchoolColors.darkBorder,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: GoogleFonts.nunito(
        color: SchoolColors.darkText,
        fontSize: 22,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.3,
      ).copyWith(fontFamilyFallback: fallbackFonts),
    ),

    cardTheme: CardThemeData(
      color: SchoolColors.darkSurface,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: SchoolColors.darkBorder, width: 1.2),
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        minimumSize: const WidgetStatePropertyAll(Size(64, 44)),
        textStyle: WidgetStatePropertyAll(
          GoogleFonts.nunito(
            fontWeight: FontWeight.w700,
            fontSize: 14.5,
            letterSpacing: -0.1,
          ),
        ),
        elevation: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) return 0;
          if (states.contains(WidgetState.hovered)) return 3;
          return 0;
        }),
        shadowColor: const WidgetStatePropertyAll(
          Colors.transparent,
        ),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        textStyle: GoogleFonts.nunito(
          fontWeight: FontWeight.w700,
          fontSize: 14.5,
          letterSpacing: -0.1,
        ),
        minimumSize: const Size(64, 44),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: const BorderSide(color: SchoolColors.darkBorder, width: 1.2),
        textStyle: GoogleFonts.nunito(
          fontWeight: FontWeight.w700,
          fontSize: 14.5,
          letterSpacing: -0.1,
        ),
        minimumSize: const Size(64, 44),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: GoogleFonts.nunito(
          fontWeight: FontWeight.w700,
          fontSize: 14.5,
          letterSpacing: -0.1,
        ),
      ),
    ),

    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.all(8),
        splashFactory: isPerformance ? NoSplash.splashFactory : InkRipple.splashFactory,
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: SchoolColors.darkSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: SchoolColors.darkBorder, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: SchoolColors.darkBorder, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 1.5),
      ),
      labelStyle: GoogleFonts.nunito(
        color: SchoolColors.darkMuted,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: GoogleFonts.nunito(
        color: const Color(0xFF475569),
        fontWeight: FontWeight.w400,
      ),
      floatingLabelStyle: GoogleFonts.nunito(
        color: primaryColor,
        fontWeight: FontWeight.w700,
        fontSize: 13,
      ),
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: SchoolColors.darkSurface,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      height: 68,
      indicatorColor: primaryColor.withValues(alpha: 0.12),
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return GoogleFonts.nunito(
            color: primaryColor,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          );
        }
        return GoogleFonts.nunito(
          color: SchoolColors.darkMuted,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(
            color: primaryColor,
            size: 22,
          );
        }
        return const IconThemeData(color: SchoolColors.darkMuted, size: 22);
      }),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFFF1F5F9),
      contentTextStyle: GoogleFonts.nunito(
        color: SchoolColors.text,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 8,
    ),

    dividerTheme: const DividerThemeData(
      color: SchoolColors.darkBorder,
      space: 1,
      thickness: 1,
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: SchoolColors.darkSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 24,
      shadowColor: Colors.black38,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: GoogleFonts.nunito(
        color: SchoolColors.darkText,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
      contentTextStyle: GoogleFonts.nunito(
        color: SchoolColors.darkTextSecondary,
        fontSize: 14,
        height: 1.55,
      ),
    ),

    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      iconColor: SchoolColors.darkMuted,
      titleTextStyle: GoogleFonts.nunito(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: SchoolColors.darkText,
      ),
    ),

    popupMenuTheme: PopupMenuThemeData(
      color: SchoolColors.darkSurfaceElevated,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: SchoolColors.darkText,
      ),
    ),

    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: SchoolColors.darkSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 16,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      showDragHandle: true,
      dragHandleColor: SchoolColors.darkBorder,
      dragHandleSize: const Size(40, 4),
    ),

    tabBarTheme: TabBarThemeData(
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: Colors.transparent,
      labelColor: primaryColor,
      unselectedLabelColor: SchoolColors.darkMuted,
      labelStyle: GoogleFonts.nunito(
        fontWeight: FontWeight.w700,
        fontSize: 13,
      ),
      unselectedLabelStyle: GoogleFonts.nunito(
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      indicator: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: primaryColor.withValues(alpha: 0.12),
      ),
    ),

    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: SchoolColors.darkText,
        borderRadius: BorderRadius.circular(10),
      ),
      textStyle: GoogleFonts.nunito(
        color: SchoolColors.darkBg,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      waitDuration: const Duration(milliseconds: 400),
    ),

    searchBarTheme: SearchBarThemeData(
      backgroundColor: WidgetStatePropertyAll(SchoolColors.darkSurface),
      shadowColor: const WidgetStatePropertyAll(Colors.transparent),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      elevation: const WidgetStatePropertyAll(0),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: SchoolColors.darkBorder, width: 1),
        ),
      ),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 12),
      ),
      textStyle: WidgetStatePropertyAll(
        GoogleFonts.nunito(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: SchoolColors.darkText,
        ),
      ),
      hintStyle: WidgetStatePropertyAll(
        GoogleFonts.nunito(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: SchoolColors.darkMuted,
        ),
      ),
    ),
  );
}
