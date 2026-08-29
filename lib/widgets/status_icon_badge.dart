import 'package:flutter/material.dart';
import 'package:nepal_care/core/theme/app_colors.dart';

/// The colored rounded-square icon used on status screens — pink with a
/// message icon on the OTP screen, green with a shield-check on Verified heleo e.
class StatusIconBadge extends StatelessWidget {
  const StatusIconBadge({
    super.key,
    required this.icon,
    required this.backgroundColor,
    this.iconColor = AppColors.textDark,
    this.size = 72,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(icon, color: iconColor, size: size * 0.45),
    );
  }
}
