/// Application-wide constants.
abstract final class AppConstants {
  static const appName = 'Nexon ERP';
  static const tagline = 'Modern Cloud ERP for Wholesale Businesses';
  static const companyName = 'FreshHarvest Distributors';
  static const companyGst = '29AABCF1234Z1Z5';

  // Layout breakpoints
  static const mobileBreakpoint = 600.0;
  static const tabletBreakpoint = 1024.0;
  static const desktopBreakpoint = 1280.0;

  // Sidebar
  static const sidebarExpandedWidth = 260.0;
  static const sidebarCollapsedWidth = 72.0;

  // Animation durations
  static const animationFast = Duration(milliseconds: 200);
  static const animationNormal = Duration(milliseconds: 350);
  static const animationSlow = Duration(milliseconds: 600);
}
