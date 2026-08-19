import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nepal_care/core/theme/app_colors.dart';
import 'package:nepal_care/core/theme/app_text_theme.dart';

/// The "00:28 · Resend available in Resend code" block under the OTP button.
/// Counts down from [seconds]; once it hits 0, "Resend code" becomes tappable
/// and calling it (dummy for now) just restarts the countdown.
class ResendCountdown extends StatefulWidget {
  const ResendCountdown({super.key, this.seconds = 30, this.onResend});

  final int seconds;
  final VoidCallback? onResend;

  @override
  State<ResendCountdown> createState() => _ResendCountdownState();
}

class _ResendCountdownState extends State<ResendCountdown> {
  late int _secondsLeft = widget.seconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft -= 1);
      }
    });
  }

  void _handleResend() {
    widget.onResend?.call();
    setState(() => _secondsLeft = widget.seconds);
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _formatted {
    final minutes = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final canResend = _secondsLeft == 0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timer_outlined, size: 16, color: AppColors.accentRed),
            const SizedBox(width: 6),
            Text(_formatted, style: AppTextTheme.textTheme.labelLarge?.copyWith(fontSize: 14)),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            Text(
              canResend ? "Didn't get it? " : 'Resend available in ',
              style: AppTextTheme.textTheme.bodyMedium,
            ),
            GestureDetector(
              onTap: canResend ? _handleResend : null,
              child: Text(
                'Resend code',
                style: AppTextTheme.textTheme.bodyMedium?.copyWith(
                  color: canResend ? AppColors.accentRed : AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                  decoration: canResend ? TextDecoration.underline : null,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
