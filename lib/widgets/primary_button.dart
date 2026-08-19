import 'package:flutter/material.dart';

/// The full-width blue CTA button ("Create my account", "Log in to Care-Nepal").
/// Takes an [onPressed] so it's ready for real logic later — pass null for now
/// to leave it visually enabled but inert, or a no-op for a working tap ripple.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed, required bool showArrow,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward, size: 18),
        ],
      ),
    );
  }
}