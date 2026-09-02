import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Brightness-aware palette lookups, so widgets don't have to repeat
/// `Theme.of(context).brightness == Brightness.dark ? darkX : lightX`.
extension ThemeContextX on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  Color get appBackground =>
      isDarkMode ? AppColors.darkBackground : AppColors.lightBackground;

  Color get appSurface =>
      isDarkMode ? AppColors.darkSurface : AppColors.lightSurface;

  Color get appCard => isDarkMode ? AppColors.darkCard : AppColors.lightCard;

  Color get appCardElevated =>
      isDarkMode ? AppColors.darkCardElevated : AppColors.lightBackground;

  Color get appBorder =>
      isDarkMode ? AppColors.darkBorder : AppColors.lightBorder;

  /// Muted body text (labels, secondary values).
  Color get mutedText =>
      isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

  /// Least prominent text (hints, captions).
  Color get subtleText =>
      isDarkMode ? AppColors.textTertiaryDark : AppColors.textTertiaryLight;
}
