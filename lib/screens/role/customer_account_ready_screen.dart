import 'package:flutter/material.dart';
import 'package:nepal_care/screens/dashboard/user_dashboard.dart';

/// Confirmation shown after a customer selects the customer role.
class CustomerAccountReadyScreen extends StatelessWidget {
  const CustomerAccountReadyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5E5E5),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 6,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF4FA8E0),
                            Color(0xFFE05656),
                            Color(0xFFE8B84B),
                            Color(0xFF4CAF7D),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 36, 28, 32),
                      child: Column(
                        children: [
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              color: const Color(0xFF7EB6E8),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: const Icon(
                              Icons.home_outlined,
                              color: Colors.white,
                              size: 42,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'ACCOUNT READY',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Welcome!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Georgia',
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Your customer account is ready. Browse and book verified providers near you.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey.shade600,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDFF3E3),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: const Text(
                              'Customer account ready',
                              style: TextStyle(
                                color: Color(0xFF1F7A38),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (_) => const UserDashboard()),
                                (route) => false,
                              ),
                              icon: const Icon(Icons.arrow_forward, size: 18),
                              label: const Text('Go to dashboard'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF7EB6E8),
                                foregroundColor: Colors.black87,
                                elevation: 0,
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Change role'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
