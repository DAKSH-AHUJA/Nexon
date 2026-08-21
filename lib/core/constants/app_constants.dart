/// Application-wide constants.
abstract final class AppConstants {
  static const appName = 'Nexon ERP';
  static const tagline =
      'ERP for vegetable trading, customer dues, and daily cash flow';
  static const companyName = 'Rajesh Trading Company';
  static const companyGst = 'GSTIN not configured';
  static const companyAccountName = companyName;
  static const companyPassword = '12345';
  static const businessCategory = 'Wholesale Vegetable Trading';

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
