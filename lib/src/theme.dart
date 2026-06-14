import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


/// Quản lý toàn bộ màu sắc, tách biệt hoàn toàn để dễ tái sử dụng
class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFF7C3AED); // Vibrant Amethyst
  static const Color secondary = Color(0xFF6366F1); // Indigo
  static const Color accent = Color(0xFF7C3AED);
  static const Color success = Color(0xFF059669); // Emerald Growth
  static const Color orange = Color(0xFFF59E0B);

  // Dark Theme Colors (Elite Digital Campus)
  static const Color darkBackground = Color(0xFF0F172A); // Deep Indigo Foundation
  static const Color darkSurface = Color(0x801E293B); // rgba(30, 41, 59, 0.5)
  static const Color darkBorder = Color(0x14FFFFFF); // rgba(255, 255, 255, 0.08)
  static const Color darkTextMain = Color(0xFFF8FAFC);
  static const Color darkTextMuted = Color(0xFF94A3B8);

  // Light Theme Colors (Clean Material)
  static const Color lightBackground = Color(0xFFF9FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFECEBF3);
  static const Color lightTextMain = Color(0xFF0F172A);
  static const Color lightTextMuted = Color(0xFF64748B);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Hiệu ứng bóng đổ (Shadows) đã được TỐI ƯU HÓA HIỆU NĂNG
class AppShadows {
  // Thay vì blur 40px gây lag, ta dùng blur 20px với màu đậm hơn để tạo Glow
  static final List<BoxShadow> glowPrimary = [
    BoxShadow(
      color: Color(0x407C3AED), // AppColors.primary.withOpacity(0.25)
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];

  static final List<BoxShadow> softCardDark = [
    BoxShadow(
      color: Color(0x4D000000), // Colors.black.withOpacity(0.3)
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];
}


class SchoolColors {
  // ── Primary Purple (Vibrant Amethyst) ──────────────────────────────
  static const primary = Color(0xFF7C3AED); // Vibrant Amethyst
  static const primaryLight = Color(0xFFA78BFA);
  static const primaryDark = Color(0xFF5B21B6);
  static const primaryContainer = Color(0xFFEDE9FE);
  static const onPrimaryContainer = Color(0xFF1E1B4B);

  // ── Secondary / Indigo ────────────────────────────────────────
  static const secondary = Color(0xFF6366F1); // Vibrant Indigo
  static const secondaryLight = Color(0xFFA5B4FC);
  static const secondaryContainer = Color(0xFFEEF2FF);
  static const onSecondaryContainer = Color(0xFF312E81);

  // ── Accent / Success / Growth ───────────────────────────────────
  static const accent = Color(0xFF7C3AED); // Same as primary for accent consistency
  static const success = Color(0xFF059669); // Emerald Growth
  static const accentContainer = Color(0xFFD1FAE5);

  // ── Semantic Colors (WCAG AA Compliant) ────────────────────────
  static const green = Color(0xFF059669); // Emerald 600
  static const greenContainer = Color(0xFFD1FAE5);
  static const red = Color(0xFFEF4444); // Red 500
  static const redContainer = Color(0xFFFEE2E2);
  static const orange = Color(0xFFF59E0B); // Amber 500
  static const orangeContainer = Color(0xFFFFEDD5);
  static const yellow = Color(0xFFFBBF24);
  static const purple = Color(0xFF7C3AED); // Primary
  static const purpleContainer = Color(0xFFEDE9FE);


  // ── Light-mode Palette (Elite Digital Campus) ───────────────────
  static const Color bg = Color(0xFFF8FAFC); // Slate 50
  static const Color surface = Color(0xA6FFFFFF); // rgba(255, 255, 255, 0.65)
  static const Color surfaceElevated = Color(0xFFF1F5F9);
  static const Color text = Color(0xFF0F172A); // Ink Navy
  static const Color textSecondary = Color(0xFF475569);
  static const Color muted = Color(0xFF64748B);
  static const Color border = Color(0x0FFFFFFF); // rgba(0, 0, 0, 0.06) - Note: In CSS it was black but here it was defined as Color(0xFFECEBF3) previously. Let's use the new spec.
  static const Color borderBright = Color(0x1FFFFFFF); // rgba(0, 0, 0, 0.12)
  static const Color borderFocus = Color(0xFFC4B5FD);

  // ── Dark-mode Palette (Elite Digital Campus) ────────────────────
  static const Color darkBg = Color(0xFF0F172A); // Deep Indigo Foundation
  static const Color darkSurface = Color(0x801E293B); // rgba(30, 41, 59, 0.5)
  static const Color darkSurfaceElevated = Color(0xFF1B1E3B);
  static const Color darkBorder = Color(0x14FFFFFF); // rgba(255, 255, 255, 0.08)
  static const Color darkBorderBright = Color(0x26FFFFFF); // rgba(255, 255, 255, 0.15)
  static const Color darkText = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkMuted = Color(0xFF64748B);

  // ── Gradients ─────────────────────────────────────────────────
  static const gradPrimary = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradSurface = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x08FFFFFF), // rgba(255, 255, 255, 0.03)
      Colors.transparent,
    ],
  );

  static const gradSurfaceLight = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xCCFFFFFF), // rgba(255, 255, 255, 0.8)
      Color(0x4DFFFFFF), // rgba(255, 255, 255, 0.3)
    ],
  );

  // ── Sidebar ───────────────────────────────────────────────────
  static const sidebarBg = Color(0xFF1E1B4B);
  static const sidebarBorder = Color(0xFF312E81);

  // ── Chat Bubbles ──────────────────────────────────────────────
  static const chatBubbleStart = Color(0xFF7C3AED);
  static const chatBubbleEnd = Color(0xFF8B5CF6);
  static const chatBubbleOther = Colors.white;
  static const chatBubbleOtherBorder = Color(0xFFEFE7FC);

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

  // ── Glow / Shadow helpers (Enhanced) ─────────────────────────
  static final navyShadowColor = const Color(0xFF0F172A).withValues(alpha: 0.06);

  static BoxShadow cardShadow = BoxShadow(
    color: const Color(0xFF7C3AED).withValues(alpha: 0.06), // Colored shadow
    blurRadius: 24,
    offset: const Offset(0, 6),
    spreadRadius: 0,
  );

  static BoxShadow lightNavyShadow = BoxShadow(
    color: navyShadowColor,
    blurRadius: 60,
    offset: const Offset(0, 30),
  );

  static BoxShadow cardShadowHover = BoxShadow(
    color: const Color(0xFF7C3AED).withValues(alpha: 0.15), // Stronger glow on hover
    blurRadius: 36,
    offset: const Offset(0, 10),
    spreadRadius: 2,
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

class AppLayout {
  const AppLayout._();

  static const double maxContentWidth = 1200.0;
  
  // Standard paddings for both margins
  static const EdgeInsets pagePaddingMobile = EdgeInsets.symmetric(horizontal: 20);
  static const EdgeInsets pagePaddingTablet = EdgeInsets.symmetric(horizontal: 32);
  static const EdgeInsets pagePaddingDesktop = EdgeInsets.symmetric(horizontal: 48);

  static EdgeInsets pagePadding(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < 600) return pagePaddingMobile;
    if (w < 1024) return pagePaddingTablet;
    return pagePaddingDesktop;
  }
}

class AppTextStyle {
  const AppTextStyle._();
  
  static final labelSm = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  static final labelMd = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  static final bodyMd = GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );

  static final titleSm = GoogleFonts.plusJakartaSans(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
  );

  static final titleLg = GoogleFonts.plusJakartaSans(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.4,
  );
  
  static TextStyle display(BuildContext context) => GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        height: 1.1,
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
ThemeData schoolTheme({Color primaryColor = SchoolColors.primary}) {
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
    tertiary: SchoolColors.success,
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
    scaffoldBackgroundColor: SchoolColors.bg,
    textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme)
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
      titleTextStyle: GoogleFonts.plusJakartaSans(
        color: SchoolColors.text,
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
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
          EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
          ),
        ),
        minimumSize: const WidgetStatePropertyAll(Size(double.infinity, 52)),
        textStyle: WidgetStatePropertyAll(
          GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        elevation: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) return 0;
          if (states.contains(WidgetState.hovered)) return 4;
          return 0;
        }),
        shadowColor: WidgetStatePropertyAll(
          SchoolColors.primary.withValues(alpha: 0.35),
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: const BorderSide(color: SchoolColors.border, width: 1.5),
        textStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
        minimumSize: const Size(double.infinity, 52),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        textStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
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
      labelStyle: GoogleFonts.inter(
        color: SchoolColors.muted,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: GoogleFonts.inter(
        color: SchoolColors.muted,
        fontWeight: FontWeight.w400,
      ),
      floatingLabelStyle: GoogleFonts.inter(
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
          return GoogleFonts.inter(
            color: primaryColor,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          );
        }
        return GoogleFonts.inter(
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
      contentTextStyle: GoogleFonts.inter(
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
      labelStyle: GoogleFonts.inter(
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
      titleTextStyle: GoogleFonts.inter(
        color: SchoolColors.text,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
      contentTextStyle: GoogleFonts.inter(
        color: SchoolColors.textSecondary,
        fontSize: 14,
        height: 1.55,
      ),
    ),

    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      iconColor: SchoolColors.muted,
      titleTextStyle: GoogleFonts.inter(
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
      textStyle: GoogleFonts.inter(
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
      labelStyle: GoogleFonts.inter(
        fontWeight: FontWeight.w700,
        fontSize: 13,
      ),
      unselectedLabelStyle: GoogleFonts.inter(
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
      textStyle: GoogleFonts.inter(
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
        GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: SchoolColors.text,
        ),
      ),
      hintStyle: WidgetStatePropertyAll(
        GoogleFonts.inter(
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
ThemeData schoolDarkTheme({Color primaryColor = SchoolColors.primaryLight}) {
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
      GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
        fontFamilyFallback: fallbackFonts,
        bodyColor: SchoolColors.darkText,
        displayColor: SchoolColors.darkText,
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
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
      titleTextStyle: GoogleFonts.inter(
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
          EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
          ),
        ),
        minimumSize: const WidgetStatePropertyAll(Size(double.infinity, 52)),
        textStyle: WidgetStatePropertyAll(
          GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        elevation: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) return 0;
          if (states.contains(WidgetState.hovered)) return 4;
          return 0;
        }),
        shadowColor: WidgetStatePropertyAll(
          SchoolColors.primaryLight.withValues(alpha: 0.3),
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: const BorderSide(color: SchoolColors.darkBorder, width: 1.5),
        textStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
        minimumSize: const Size(double.infinity, 52),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        textStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
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
      labelStyle: GoogleFonts.inter(
        color: SchoolColors.darkMuted,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: GoogleFonts.inter(
        color: const Color(0xFF475569),
        fontWeight: FontWeight.w400,
      ),
      floatingLabelStyle: GoogleFonts.inter(
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
          return GoogleFonts.inter(
            color: primaryColor,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          );
        }
        return GoogleFonts.inter(
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
      contentTextStyle: GoogleFonts.inter(
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
      titleTextStyle: GoogleFonts.inter(
        color: SchoolColors.darkText,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
      contentTextStyle: GoogleFonts.inter(
        color: SchoolColors.darkTextSecondary,
        fontSize: 14,
        height: 1.55,
      ),
    ),

    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      iconColor: SchoolColors.darkMuted,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 16,
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
      textStyle: GoogleFonts.inter(
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
      labelStyle: GoogleFonts.inter(
        fontWeight: FontWeight.w700,
        fontSize: 13,
      ),
      unselectedLabelStyle: GoogleFonts.inter(
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
      textStyle: GoogleFonts.inter(
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
        GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: SchoolColors.darkText,
        ),
      ),
      hintStyle: WidgetStatePropertyAll(
        GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: SchoolColors.darkMuted,
        ),
      ),
    ),
  );
}
