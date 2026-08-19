import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nepal_care/core/theme/app_colors.dart';
import 'package:nepal_care/core/theme/app_text_theme.dart';

/// A row of single-digit boxes for entering an OTP. Handles auto-advancing
/// to the next box, moving back on backspace, and spreading a pasted code
/// across all boxes at once (paste the whole code into any box).
///
/// This is display-only — it reports the current code via [onChanged] and
/// [onCompleted] but does not verify anything itself.
class OtpCodeField extends StatefulWidget {
  const OtpCodeField({
    super.key,
    this.length = 6,
    required this.onChanged,
    required this.onCompleted,
  });

  final int length;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onCompleted;

  @override
  State<OtpCodeField> createState() => _OtpCodeFieldState();
}

class _OtpCodeFieldState extends State<OtpCodeField> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _handleChanged(int index, String value) {
    if (value.length > 1) {
      // Whole code pasted into one box — spread the digits across the rest.
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (var i = 0; i < digits.length && (index + i) < widget.length; i++) {
        _controllers[index + i].text = digits[i];
      }
      final lastFilled = (index + digits.length - 1).clamp(0, widget.length - 1);
      _focusNodes[lastFilled].requestFocus();
    } else if (value.isNotEmpty && index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isNotEmpty) {
      _focusNodes[index].unfocus();
    }
    _emitChange();
  }

  void _handleBackspace(int index) {
    if (_controllers[index].text.isEmpty && index > 0) {
      _controllers[index - 1].clear();
      _focusNodes[index - 1].requestFocus();
      _emitChange();
    }
  }

  void _emitChange() {
    final code = _controllers.map((c) => c.text).join();
    widget.onChanged(code);
    if (code.length == widget.length) {
      widget.onCompleted(code);
    }
  }

  /// Clears every box — call from the parent (e.g. after a failed verify).
  void clear() {
    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes.first.requestFocus();
    _emitChange();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(widget.length, (index) {
        return SizedBox(
          width: 44,
          height: 52,
          child: KeyboardListener(
            focusNode: FocusNode(skipTraversal: true, canRequestFocus: false),
            onKeyEvent: (event) {
              if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
                _handleBackspace(index);
              }
            },
            child: TextField(
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              onChanged: (value) => _handleChanged(index, value),
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: AppTextTheme.textTheme.headlineSmall?.copyWith(
                fontFamily: AppTextTheme.fontFamilyBody,
                fontSize: 20,
              ),
              decoration: InputDecoration(
                counterText: '',
                contentPadding: EdgeInsets.zero,
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderGray),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderGray),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
