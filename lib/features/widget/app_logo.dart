import 'package:flutter/material.dart';

/// The app logo shown at the top of every auth screen. Pull this out once
/// so it never gets sized/placed slightly differently on each screen.
class AppLogoMark extends StatelessWidget {
  const AppLogoMark({super.key, this.size = 70});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        'assets/images/logo.png',
        fit: BoxFit.contain,
      ),
    );
  }
}