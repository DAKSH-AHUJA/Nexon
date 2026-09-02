import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

/// Responsive layout utilities.
class Responsive {
  const Responsive(this.context);

  final BuildContext context;

  double get width => MediaQuery.sizeOf(context).width;
  double get height => MediaQuery.sizeOf(context).height;

  bool get isMobile => width < AppConstants.mobileBreakpoint;
  bool get isTablet =>
      width >= AppConstants.mobileBreakpoint &&
      width < AppConstants.desktopBreakpoint;
  bool get isDesktop => width >= AppConstants.desktopBreakpoint;

  /// Returns mobile, tablet, or desktop value based on screen width.
  T value<T>({required T mobile, T? tablet, required T desktop}) {
    if (isDesktop) return desktop;
    if (isTablet) return tablet ?? desktop;
    return mobile;
  }

  int get gridColumns {
    if (isDesktop) return 4;
    if (isTablet) return 2;
    return 1;
  }

  double get contentPadding {
    if (isDesktop) return 32;
    if (isTablet) return 24;
    return 16;
  }
}
