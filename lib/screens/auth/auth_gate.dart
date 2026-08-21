import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nepal_care/core/enum/user_role.dart';
import 'package:nepal_care/repositories/user_repository.dart';
import 'package:nepal_care/screens/auth/auth_screen.dart';
import 'package:nepal_care/screens/dashboard/provider_dashboard.dart';
import 'package:nepal_care/screens/dashboard/user_dashboard.dart';
import 'package:nepal_care/screens/role/role_selection_screen.dart';

/// The only app entry point after Firebase has restored a session.
/// A saved role is read from Firestore, never selected again at sign-in.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }
        final user = authSnapshot.data;
        if (user == null) return const AuthScreen();

        return FutureBuilder<UserRole?>(
          future: UserRepository().getRole(user.uid),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState != ConnectionState.done) {
              return const _LoadingScreen();
            }
            if (roleSnapshot.hasError) {
              return _RoleLoadError(error: roleSnapshot.error);
            }
            return switch (roleSnapshot.data) {
              UserRole.customer => const UserDashboard(),
              UserRole.provider => const ProviderDashboard(),
              null => RoleSelectionScreen(uid: user.uid),
            };
          },
        );
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();
  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
}

class _RoleLoadError extends StatelessWidget {
  const _RoleLoadError({this.error});
  final Object? error;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'We could not load your account. Please check your connection and restart the app.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      );
}
