import 'package:flutter/material.dart';

class AppResponsive {
  const AppResponsive._();

  /// Standard breakpoint for mobile devices.
  static const double mobileBreakpoint = 700;

  /// Standard breakpoint for tablet/large mobile.
  static const double tabletBreakpoint = 900;

  /// Checks if the current screen width is mobile.
  static bool isMobile(BuildContext context) {
    return MediaQuery.sizeOf(context).width < mobileBreakpoint;
  }

  /// Checks if the current screen width is tablet or larger.
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  /// Checks if the current screen width is desktop (wide).
  static bool isDesktop(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= tabletBreakpoint;
  }

  /// Returns a responsive padding based on screen size, accounting for bottom safe area.
  static EdgeInsets screenPadding(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    if (isMobile(context)) {
      return EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0 + bottomPadding);
    } else if (isTablet(context)) {
      return EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 24.0 + bottomPadding);
    } else {
      return EdgeInsets.fromLTRB(32.0, 32.0, 32.0, 32.0 + bottomPadding);
    }
  }

  /// Returns a responsive horizontal padding.
  static double horizontalPadding(BuildContext context) {
    if (isMobile(context)) return 16.0;
    if (isTablet(context)) return 24.0;
    return 32.0;
  }
}

extension ResponsiveExtension on BuildContext {
  bool get isMobile => AppResponsive.isMobile(this);
  bool get isTablet => AppResponsive.isTablet(this);
  bool get isDesktop => AppResponsive.isDesktop(this);
  EdgeInsets get screenPadding => AppResponsive.screenPadding(this);
  double get horizontalPadding => AppResponsive.horizontalPadding(this);
}
