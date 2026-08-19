import 'package:flutter/material.dart';
import 'package:nepal_care/core/theme/app_colors.dart';
import 'package:nepal_care/core/theme/app_text_theme.dart';
import 'package:nepal_care/screens/dashboard/provider_dashboard.dart';
import 'package:nepal_care/widgets/back_pill_button.dart';
import 'package:nepal_care/widgets/primary_button.dart';
import 'package:nepal_care/widgets/status_icon_badge.dart';

/// Confirmation shown after a provider submits their verification profile.
class ProviderProfileSubmittedScreen extends StatelessWidget {
  const ProviderProfileSubmittedScreen({super.key});

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
                  icon: Icons.hourglass_top_outlined,
                  backgroundColor: AppColors.statusGreenBg,
                ),
              ),
              const SizedBox(height: 20),
              Center(child: Text('Profile submitted!', style: AppTextTheme.textTheme.headlineSmall)),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  "We're reviewing your documents.\nThis usually takes 24–48 hours.",
                  textAlign: TextAlign.center,
                  style: AppTextTheme.textTheme.bodyLarge?.copyWith(color: AppColors.textMuted),
                ),
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                label: 'Continue to provider dashboard',
                onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const ProviderDashboard()),
                  (route) => false,
                ),
                showArrow: false,
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
