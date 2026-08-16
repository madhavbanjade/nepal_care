import 'package:flutter/material.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SafeArea(
          child: Column(
            children: [
              const Icon(Icons.heart_broken, size: 32),
              const Text(
                "Care-Nepal",
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              const Text(
                "भरपर्दो हेरचाह — तपाईंको नजिकै",
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 20),
            ],
          ),
          
        ),
      ),
    );
  }
}
