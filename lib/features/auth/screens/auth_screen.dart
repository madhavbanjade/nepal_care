import 'package:flutter/material.dart';
import 'package:nepal_care/features/widget/app_logo.dart';
import 'package:nepal_care/features/widget/auth_tab.dart';
import 'package:nepal_care/features/widget/contact_method_toogle.dart';
import 'package:nepal_care/features/widget/labeled_divider.dart';
import 'package:nepal_care/features/widget/primary_button.dart';
import 'package:nepal_care/features/widget/social_login_button.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_theme.dart';
import 'otp_verification_screen.dart';

/// The single auth screen. The logo, brand text, and Sign Up/Log In toggle
/// stay fixed on screen — only the section below (heading, fields, button,
/// footer) swaps when the tab changes. Same pattern as the Email/Phone
/// toggle, just one level up: state lives here, content below reacts to it.
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
              // --- Fixed: logo + brand ---
              const Center(child: AppLogoMark()),
              const SizedBox(height: 12),
              Center(
                child: Text('Care-Nepal', style: AppTextTheme.textTheme.displaySmall),
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

              // --- Fixed: Sign Up / Log In toggle ---
              AuthTabToggle(
                selected: _tab,
                onChanged: (tab) => setState(() => _tab = tab),
              ),
              const SizedBox(height: 24),

              // --- Swappable: everything below the toggle ---
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: _tab == AuthTab.signUp
                    ? _SignupBody(
                        key: const ValueKey('signup'),
                        onSwitchToLogIn: () => setState(() => _tab = AuthTab.logIn),
                      )
                    : _LoginBody(
                        key: const ValueKey('login'),
                        onSwitchToSignUp: () => setState(() => _tab = AuthTab.signUp),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignupBody extends StatefulWidget {
  const _SignupBody({super.key, required this.onSwitchToLogIn});

  final VoidCallback onSwitchToLogIn;

  @override
  State<_SignupBody> createState() => _SignupBodyState();
}

class _SignupBodyState extends State<_SignupBody> {
  ContactMethod _contactMethod = ContactMethod.email;
  bool _obscurePassword = true;
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleCreateAccount() {
    final contact = _contactMethod == ContactMethod.email
        ? _emailController.text.trim()
        : '+977 ${_phoneController.text.trim()}';

    // TODO: replace with a real sign-up call once the backend exists.
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OtpVerificationScreen(
          contact: contact.isEmpty ? 'your contact' : contact,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Create your account', style: AppTextTheme.textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(
          'Join thousands of families across Nepal',
          style: AppTextTheme.textTheme.bodyLarge?.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: 20),

        ContactMethodToggle(
          selected: _contactMethod,
          onChanged: (method) => setState(() => _contactMethod = method),
        ),
        const SizedBox(height: 16),

        if (_contactMethod == ContactMethod.email)
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(hintText: 'you@example.com'),
          )
        else
          _PhoneField(controller: _phoneController),
        const SizedBox(height: 12),

        TextField(
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            hintText: 'Password',
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: AppColors.textMuted,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        const SizedBox(height: 20),

        PrimaryButton(label: 'Create my account', onPressed: _handleCreateAccount, showArrow: false,),
        const SizedBox(height: 20),

        const LabeledDivider(label: 'or continue with'),
        const SizedBox(height: 16),

        const _SocialRow(),
        const SizedBox(height: 20),

        Center(
          child: Text('Already have an account?', style: AppTextTheme.textTheme.bodyMedium),
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

class _LoginBody extends StatefulWidget {
  const _LoginBody({super.key, required this.onSwitchToSignUp});

  final VoidCallback onSwitchToSignUp;

  @override
  State<_LoginBody> createState() => _LoginBodyState();
}

class _LoginBodyState extends State<_LoginBody> {
  ContactMethod _contactMethod = ContactMethod.email;
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Welcome back', style: AppTextTheme.textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(
          'Log in to manage your bookings',
          style: AppTextTheme.textTheme.bodyLarge?.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: 20),

        ContactMethodToggle(
          selected: _contactMethod,
          onChanged: (method) => setState(() => _contactMethod = method),
        ),
        const SizedBox(height: 16),

        if (_contactMethod == ContactMethod.email)
          TextField(
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(hintText: 'you@example.com'),
          )
        else
          _PhoneField(),
        const SizedBox(height: 12),

        TextField(
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            hintText: 'Password',
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: AppColors.textMuted,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        const SizedBox(height: 8),

        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: const Text('Forgot password?'),
          ),
        ),
        const SizedBox(height: 12),

        PrimaryButton(label: 'Log in to Care-Nepal', onPressed: () {}, showArrow: false,),
        const SizedBox(height: 20),

        const LabeledDivider(label: 'or continue with'),
        const SizedBox(height: 16),

        const _SocialRow(),
        const SizedBox(height: 20),

        Center(
          child: Text("Don't have an account?", style: AppTextTheme.textTheme.bodyMedium),
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

/// Google / Apple ID row, shared by both forms.
class _SocialRow extends StatelessWidget {
  const _SocialRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SocialLoginButton(
            label: 'Google',
            icon: Icons.g_mobiledata,
            onPressed: () {},
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