import 'package:flutter/material.dart';

/// Single source of truth for every color used in the app.
/// Never hardcode a hex value in a screen/widget — reference AppColors instead,
/// so a brand tweak only means changing it here.
class AppColors {
  AppColors._();

  /// Primary brand blue — main CTA buttons ("Create my account", "Log in to Care-Nepal"),
  /// selected tab underline/border, primary icons.
  static const Color primaryBlue = Color(0xFF8EC5F0);

  /// Accent red — selected Sign up/Log in toggle background, "Log in instead" /
  /// "Sign up free" links, "Forgot password?" link.
  static const Color accentRed = Color(0xFFE13B32);

  /// Core dark text — headings, primary body text, entered field values.
  static const Color textDark = Color(0xFF1A1A1A);

  // --- The 3 colors above are the exact ones you gave me. Everything below is a
  // --- sensible neutral I added so the UI has borders/placeholders/etc. Swap the
  // --- hex values below anytime you get exact specs for them.
  static const Color textMuted = Color(0xFF8A8A8A); // hint/placeholder text
  static const Color borderGray = Color(0xFFE3E3E3); // input & pill borders
  static const Color surface = Color(0xFFF6F6F6); // unselected toggle bg, input fill
  static const Color background = Color(0xFFFFFFFF); // scaffold/card background
  static const Color statusGreenBg = Color(0xFFA8E4B0);
  static const Color statusPinkBg = Color(0xFFF7B9B9);
  static const Color statusGreenText = Color(0xFF2E7D3A);

  static get primary => null;


}
