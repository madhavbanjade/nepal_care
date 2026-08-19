import 'package:flutter/material.dart';
import 'package:nepal_care/widgets/back_pill_button.dart';
import 'package:nepal_care/widgets/primary_button.dart';
import 'package:nepal_care/widgets/status_icon_badge.dart';
import 'package:nepal_care/core/theme/app_colors.dart';
import 'package:nepal_care/core/theme/app_text_theme.dart';


/// Shown once the OTP is "verified" (dummy — no backend yet).
class VerifiedScreen extends StatelessWidget {
  const VerifiedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: BackPillButton(onPressed: () => Navigator.of(context).maybePop()),
              ),
              const Spacer(),

              const Center(
                child: StatusIconBadge(
                  icon: Icons.verified_user_outlined,
                  backgroundColor: AppColors.statusGreenBg,
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text('Verified!', style: AppTextTheme.textTheme.headlineSmall),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Your number is confirmed.\nWelcome to Care-Nepal.',
                  textAlign: TextAlign.center,
                  style: AppTextTheme.textTheme.bodyLarge?.copyWith(color: AppColors.textMuted),
                ),
              ),
              const SizedBox(height: 32),

              PrimaryButton(
                label: 'Continue',
                onPressed: () {
                  // TODO: navigate to the home/dashboard screen once it exists.
                  // For now, drop back to the very first route in the stack.
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }, showArrow: false,
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
