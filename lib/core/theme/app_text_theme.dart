import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Font families + the TextTheme built from them.
/// Fraunces (serif) = headings/brand name. Work Sans (sans) = everything else.
class AppTextTheme {
  AppTextTheme._();

  static const String fontFamilyHeading = 'Fraunces';
  static const String fontFamilyBody = 'WorkSans';

  static TextTheme get textTheme => const TextTheme(
        // "Care-Nepal" logo wordmark
        displaySmall: TextStyle(
          fontFamily: fontFamilyHeading,
          fontSize: 26,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),

        // Screen titles: "Create your account", "Welcome back"
        headlineSmall: TextStyle(
          fontFamily: fontFamilyHeading,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
          height: 1.2,
        ),

        // Subtitle under the title: "Join thousands of families..."
        bodyLarge: TextStyle(
          fontFamily: fontFamilyBody,
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: AppColors.textDark,
        ),

        // Hint/placeholder text, helper text, fine print
        bodyMedium: TextStyle(
          fontFamily: fontFamilyBody,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textMuted,
        ),

        // Small print, e.g. "By signing up you agree to..."
        bodySmall: TextStyle(
          fontFamily: fontFamilyBody,
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.textMuted,
        ),

        // Button labels, toggle labels ("Sign Up" / "Log In")
        labelLarge: TextStyle(
          fontFamily: fontFamilyBody,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
      );
}