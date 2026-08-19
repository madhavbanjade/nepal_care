import 'package:flutter/material.dart';
import 'package:nepal_care/core/theme/app_colors.dart';
import 'package:nepal_care/core/theme/app_text_theme.dart';

enum ContactMethod { email, phone }

/// The small dark "Email | Phone" segmented control that decides which
/// input field shows below it. State lives in the parent screen so the
/// screen can swap the field that follows it.
class ContactMethodToggle extends StatelessWidget {
  const ContactMethodToggle({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final ContactMethod selected;
  final ValueChanged<ContactMethod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderGray),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Segment(
              icon: Icons.email_outlined,
              label: 'Email',
              isSelected: selected == ContactMethod.email,
              onTap: () => onChanged(ContactMethod.email),
            ),
          ),
          Expanded(
            child: _Segment(
              icon: Icons.phone_outlined,
              label: 'Phone',
              isSelected: selected == ContactMethod.phone,
              onTap: () => onChanged(ContactMethod.phone),
            ),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
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
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.textDark : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextTheme.textTheme.bodyMedium?.copyWith(
                color: isSelected ? Colors.white : AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
