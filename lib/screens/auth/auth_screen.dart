import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:nepal_care/widgets/app_logo.dart';
import 'package:nepal_care/widgets/auth_tab.dart';
import 'package:nepal_care/widgets/contact_method_toogle.dart';
import 'package:nepal_care/widgets/labeled_divider.dart';
import 'package:nepal_care/widgets/primary_button.dart';
import 'package:nepal_care/widgets/social_login_button.dart';
import 'package:nepal_care/core/theme/app_colors.dart';
import 'package:nepal_care/core/theme/app_text_theme.dart';
import 'otp_verification_screen.dart';

/// The single auth screen. The logo, brand text, and Sign Up/Log In toggle
/// stay fixed on screen — only the section below (heading, fields, button,
/// footer) swaps when the tab changes.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  AuthTab _tab = AuthTab.signUp;

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
              const Center(child: AppLogoMark()),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Care-Nepal',
                  style: AppTextTheme.textTheme.displaySmall,
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  'मन-देखि साथ · तपाईंको स्वास्थ्य पोर्टल',
                  textAlign: TextAlign.center,
                  style: AppTextTheme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 24),
              AuthTabToggle(
                selected: _tab,
                onChanged: (tab) => setState(() => _tab = tab),
              ),
              const SizedBox(height: 24),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: _tab == AuthTab.signUp
                    ? _SignupBody(
                        key: const ValueKey('signup'),
                        onSwitchToLogIn: () =>
                            setState(() => _tab = AuthTab.logIn),
                      )
                    : _LoginBody(
                        key: const ValueKey('login'),
                        onSwitchToSignUp: () =>
                            setState(() => _tab = AuthTab.signUp),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SIGN UP
// ============================================================

class _SignupBody extends StatefulWidget {
  const _SignupBody({super.key, required this.onSwitchToLogIn});

  final VoidCallback onSwitchToLogIn;

  @override
  State<_SignupBody> createState() => _SignupBodyState();
}

class _SignupBodyState extends State<_SignupBody> {
  ContactMethod _contactMethod = ContactMethod.email;
  bool _obscurePassword = true;
  bool _isLoading = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String _friendlyError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'That email address looks invalid.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'invalid-phone-number':
        return 'That phone number looks invalid.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return e.message ?? 'Something went wrong. Please try again.';
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade600),
    );
  }

  Future<void> _handleCreateAccount() async {
    if (_isLoading) return;

    if (_contactMethod == ContactMethod.email) {
      await _signUpWithEmail();
    } else {
      await _signUpWithPhone();
    }
  }

  Future<void> _signUpWithEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Please fill in both email and password.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

    } on FirebaseAuthException catch (e) {
      _showError(_friendlyError(e));
    } catch (e) {
      _showError('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signUpWithPhone() async {
    final rawNumber = _phoneController.text.trim();
    if (rawNumber.isEmpty) {
      _showError('Please enter your phone number.');
      return;
    }
    final phoneNumber = '+977$rawNumber';

    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Android-only auto-retrieval. Sign the user in directly.
          await FirebaseAuth.instance.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          if (mounted) setState(() => _isLoading = false);
          _showError(_friendlyError(e));
        },
        codeSent: (String verificationId, int? resendToken) {
          if (mounted) setState(() => _isLoading = false);
          if (!mounted) return;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => OtpVerificationScreen(
                contact: phoneNumber,
                verificationId: verificationId,
                resendToken: resendToken,
              ),
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Called if auto-retrieval times out; verificationId is still
          // valid for manual code entry if the user is already on the OTP screen.
        },
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _isLoading = false);
      _showError(_friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Create your account',
          style: AppTextTheme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(
          'Join thousands of families across Nepal',
          style: AppTextTheme.textTheme.bodyLarge?.copyWith(
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 20),
        ContactMethodToggle(
          selected: _contactMethod,
          onChanged: (method) => setState(() => _contactMethod = method),
        ),
        const SizedBox(height: 16),
        if (_contactMethod == ContactMethod.email) ...[
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(hintText: 'you@example.com'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              hintText: 'Password',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.textMuted,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
        ] else
          _PhoneField(controller: _phoneController),
        const SizedBox(height: 20),
        PrimaryButton(
          label: _isLoading ? 'Creating account...' : 'Create my account',
          onPressed: _isLoading ? null : _handleCreateAccount,
          showArrow: false,
        ),
        const SizedBox(height: 20),
        const LabeledDivider(label: 'or continue with'),
        const SizedBox(height: 16),
        _SocialRow(
          onGooglePressed: () {
            _signInWithGoogle(context);
          },
        ),
        const SizedBox(height: 20),
        Center(
          child: Text(
            'Already have an account?',
            style: AppTextTheme.textTheme.bodyMedium,
          ),
        ),
        Center(
          child: TextButton(
            onPressed: widget.onSwitchToLogIn,
            child: const Text('Log in instead'),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'By signing up you agree to our Terms of Service\nand Privacy Policy',
            textAlign: TextAlign.center,
            style: AppTextTheme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// LOG IN
// ============================================================

class _LoginBody extends StatefulWidget {
  const _LoginBody({super.key, required this.onSwitchToSignUp});

  final VoidCallback onSwitchToSignUp;

  @override
  State<_LoginBody> createState() => _LoginBodyState();
}

class _LoginBodyState extends State<_LoginBody> {
  ContactMethod _contactMethod = ContactMethod.email;
  bool _obscurePassword = true;
  bool _isLoading = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String _friendlyError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'invalid-email':
        return 'That email address looks invalid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return e.message ?? 'Something went wrong. Please try again.';
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade600),
    );
  }

  Future<void> _handleLogIn() async {
    if (_isLoading) return;
    if (_contactMethod == ContactMethod.email) {
      await _logInWithEmail();
    } else {
      await _logInWithPhone();
    }
  }

  Future<void> _logInWithEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Please fill in both email and password.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      _showError(_friendlyError(e));
    } catch (e) {
      _showError('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logInWithPhone() async {
    final rawNumber = _phoneController.text.trim();
    if (rawNumber.isEmpty) {
      _showError('Please enter your phone number.');
      return;
    }
    final phoneNumber = '+977$rawNumber';

    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          if (mounted) setState(() => _isLoading = false);
          _showError(_friendlyError(e));
        },
        codeSent: (String verificationId, int? resendToken) {
          if (mounted) setState(() => _isLoading = false);
          if (!mounted) return;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => OtpVerificationScreen(
                contact: phoneNumber,
                verificationId: verificationId,
                resendToken: resendToken,
              ),
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _isLoading = false);
      _showError(_friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Welcome back', style: AppTextTheme.textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(
          'Log in to manage your bookings',
          style: AppTextTheme.textTheme.bodyLarge?.copyWith(
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 20),
        ContactMethodToggle(
          selected: _contactMethod,
          onChanged: (method) => setState(() => _contactMethod = method),
        ),
        const SizedBox(height: 16),
        if (_contactMethod == ContactMethod.email) ...[
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(hintText: 'you@example.com'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              hintText: 'Password',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.textMuted,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
        ] else
          _PhoneField(controller: _phoneController),
        const SizedBox(height: 8),
        if (_contactMethod == ContactMethod.email)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _handleForgotPassword(context),
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: const Text('Forgot password?'),
            ),
          ),
        const SizedBox(height: 12),
        PrimaryButton(
          label: _isLoading ? 'Logging in...' : 'Log in to Care-Nepal',
          onPressed: _isLoading ? null : _handleLogIn,
          showArrow: false,
        ),
        const SizedBox(height: 20),
        const LabeledDivider(label: 'or continue with'),
        const SizedBox(height: 16),
        _SocialRow(
          onGooglePressed: () {
            _signInWithGoogle(context);
          },
        ),
        const SizedBox(height: 20),
        Center(
          child: Text(
            "Don't have an account?",
            style: AppTextTheme.textTheme.bodyMedium,
          ),
        ),
        Center(
          child: TextButton(
            onPressed: widget.onSwitchToSignUp,
            child: const Text('Sign up free'),
          ),
        ),
      ],
    );
  }

  Future<void> _handleForgotPassword(BuildContext context) async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showError('Enter your email above first, then tap "Forgot password?".');
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset link sent to $email')),
      );
    } on FirebaseAuthException catch (e) {
      _showError(_friendlyError(e));
    }
  }
}

/// +977 prefix + number field, shared by both forms.
class _PhoneField extends StatelessWidget {
  const _PhoneField({this.controller});

  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderGray),
          ),
          child: Text('+977', style: AppTextTheme.textTheme.bodyLarge),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(hintText: '98XXXXXXXX'),
          ),
        ),
      ],
    );
  }
}

/// Signs the user in with Google, then routes them into role selection —
/// same destination as email/phone signup, just a different entry point.
Future<void> _signInWithGoogle(BuildContext context) async {
  try {
    final GoogleSignInAccount googleUser =
        await GoogleSignIn.instance.authenticate();

    final GoogleSignInAuthentication googleAuth = googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    await FirebaseAuth.instance.signInWithCredential(credential);

    // AuthGate listens to Firebase Auth and routes to the saved role.
  } on FirebaseAuthException catch (e) {
    debugPrint('Firebase Auth Error: ${e.code} — ${e.message}');
  } catch (e) {
    debugPrint('Google Sign-In Error: $e');
  }
}

/// Google / Apple ID row, shared by both forms.
/// NOTE: Apple ID isn't wired to a real provider yet.
class _SocialRow extends StatelessWidget {
  final VoidCallback onGooglePressed;
  const _SocialRow({required this.onGooglePressed});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SocialLoginButton(
            label: 'Google',
            icon: Icons.g_mobiledata,
            onPressed: onGooglePressed,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SocialLoginButton(
            label: 'Apple ID',
            icon: Icons.apple,
            backgroundColor: const Color(0xFFDCF5E3),
            onPressed: () {},
          ),
        ),
      ],
    );
  }
}
