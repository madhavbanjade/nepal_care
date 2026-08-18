import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_theme.dart';

/// One line in the "Profile completeness" checklist — a check circle that
/// fills in once that piece of the form is valid.
class ChecklistItem extends StatelessWidget {
  const ChecklistItem({super.key, required this.label, required this.isComplete});

  final String label;
  final bool isComplete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isComplete ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: isComplete ? const Color(0xFF2E9E5B) : AppColors.textMuted,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTextTheme.textTheme.bodyMedium?.copyWith(
              color: isComplete ? AppColors.textDark : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}