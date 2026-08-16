import 'package:flutter/material.dart';
import 'package:nepal_care/features/auth/screens/auth_screen.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const CareNepalApp());
}

class CareNepalApp extends StatelessWidget {
  const CareNepalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Care-Nepal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthScreen(),
    );
  }
}