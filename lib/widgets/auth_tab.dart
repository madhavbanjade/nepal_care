import 'package:flutter/material.dart';
import 'package:nepal_care/core/theme/app_colors.dart';
import 'package:nepal_care/core/theme/app_text_theme.dart';

enum AuthTab { signUp, logIn }

/// The "Sign Up | Log In" segmented pill at the top of both auth screens.
/// Purely presentational — tapping the *inactive* side calls [onChanged]
/// so the parent screen can decide how to navigate (wired up later).
class AuthTabToggle extends StatelessWidget {
  const AuthTabToggle({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final AuthTab selected;
  final ValueChanged<AuthTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabSegment(
              label: 'Sign Up',
              isSelected: selected == AuthTab.signUp,
              onTap: () => onChanged(AuthTab.signUp),
            ),
          ),
          Expanded(
            child: _TabSegment(
              label: 'Log In',
              isSelected: selected == AuthTab.logIn,
              onTap: () => onChanged(AuthTab.logIn),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabSegment extends StatelessWidget {
  const _TabSegment({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTextTheme.textTheme.labelLarge?.copyWith(
            color: isSelected ? AppColors.textDark : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
