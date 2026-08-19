import 'package:flutter/material.dart';
import 'package:nepal_care/widgets/back_pill_button.dart';
import 'package:nepal_care/widgets/otp_code_field.dart';
import 'package:nepal_care/widgets/primary_button.dart';
import 'package:nepal_care/widgets/resend_coutdown.dart';
import 'package:nepal_care/widgets/status_icon_badge.dart';
import 'package:nepal_care/core/theme/app_colors.dart';
import 'package:nepal_care/core/theme/app_text_theme.dart';

import 'verified_screen.dart';

/// Shown right after Sign Up (email or phone). Dummy for now — any 6-digit
/// code "verifies" since there's no backend yet. Wire real OTP checking up
/// once the database/API is in place.
class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key, required this.contact, required verificationId, Object? resendToken});

  /// The email or phone number the code was "sent" to, shown in the subtitle.
  final String contact;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  String _code = '';

  bool get _isComplete => _code.length == 6;

  void _handleVerify() {
    if (!_isComplete) return;
    // TODO: replace with a real API call once the backend exists.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const VerifiedScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: BackPillButton(onPressed: () => Navigator.of(context).maybePop()),
              ),
              const SizedBox(height: 28),

              const Center(
                child: StatusIconBadge(
                  icon: Icons.sms_outlined,
                  backgroundColor: AppColors.statusPinkBg,
                ),
              ),
              const SizedBox(height: 20),

              Text('Enter the code', style: AppTextTheme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: AppTextTheme.textTheme.bodyLarge?.copyWith(color: AppColors.textMuted),
                  children: [
                    const TextSpan(text: 'We sent a 6-digit OTP to '),
                    TextSpan(
                      text: widget.contact,
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark),
                    ),
                    const TextSpan(text: '. Check your SMS inbox.'),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              OtpCodeField(
                onChanged: (code) => setState(() => _code = code),
                onCompleted: (code) => setState(() => _code = code),
              ),
              const SizedBox(height: 24),

              PrimaryButton(
                label: 'Verify code',
                showArrow: false,
                onPressed: _isComplete ? _handleVerify : null,
              ),
              const SizedBox(height: 20),

              const ResendCountdown(seconds: 30),
              const SizedBox(height: 28),

              Center(
                child: Text(
                  'Tip: paste your OTP directly — it auto-fills all boxes.',
                  textAlign: TextAlign.center,
                  style: AppTextTheme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
