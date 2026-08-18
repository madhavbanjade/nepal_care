import 'package:flutter/material.dart';
import 'package:nepal_care/features/widget/back_pill_button.dart';
import 'package:nepal_care/features/widget/primary_button.dart';
import 'package:nepal_care/role/data/user_repository.dart';
import 'package:nepal_care/role/data/user_role.dart';
import 'package:nepal_care/role/screens/provider_profile_screen.dart';
import 'package:nepal_care/role/screens/user_dashboard.dart';
import 'package:nepal_care/role/widgets/onboarding_progress_bar.dart';
import 'package:nepal_care/role/widgets/role_option_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';


/// Step 1 of onboarding: pick Customer or Provider.
///
/// [uid] is the signed-in user's Firebase Auth uid — wire it up from
/// wherever you call this screen, e.g.:
///   RoleSelectionScreen(uid: FirebaseAuth.instance.currentUser!.uid)
/// or pass it through from your own AuthRepository/VerifiedScreen flow.
class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key, required this.uid});

  final String uid;

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  final _userRepository = UserRepository();

  UserRole? _selectedRole = UserRole.customer;
  bool _isSubmitting = false;

  Future<void> _handleContinue() async {
    final role = _selectedRole;
    if (role == null || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      await _userRepository.setRole(widget.uid, role);
      if (!mounted) return;

      if (role == UserRole.customer) {
        // TODO: replace with your real customer dashboard/home screen.
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => UserDashboard()));
      } else {
        // Navigator.of(context).push(
        //   MaterialPageRoute(builder: (_) => ProviderProfileScreen(uid: widget.uid)),
        // );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Something went wrong: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

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
              Align(
                alignment: Alignment.centerLeft,
                child: BackPillButton(onPressed: () => Navigator.of(context).maybePop()),
              ),
              const SizedBox(height: 20),
              const OnboardingProgressBar(step: 1, totalSteps: 3),
              const SizedBox(height: 24),

              Text('How will you use Care-Nepal?', style: AppTextTheme.textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text(
                'Choose your role — you can always switch later.',
                style: AppTextTheme.textTheme.bodyLarge?.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 20),

              RoleOptionCard(
                icon: Icons.home_outlined,
                title: 'I need care services',
                description:
                    'Book verified caregivers for your family — baby care, senior care, pet care, and more.',
                tags: const ['Baby care', 'Senior care', 'Pet care'],
                isSelected: _selectedRole == UserRole.customer,
                onTap: () => setState(() => _selectedRole = UserRole.customer),
              ),
              const SizedBox(height: 14),
              RoleOptionCard(
                icon: Icons.badge_outlined,
                title: 'I provide care services',
                description:
                    'List your skills, set your schedule, and earn by helping families across Nepal.',
                tags: const ['Verified badge', 'Flexible hours', 'Quick payments'],
                isSelected: _selectedRole == UserRole.provider,
                onTap: () => setState(() => _selectedRole = UserRole.provider),
              ),
              const SizedBox(height: 24),

              PrimaryButton(
                label: _isSubmitting
                    ? 'Please wait...'
                    : _selectedRole == UserRole.provider
                        ? 'Continue as Provider'
                        : 'Continue as Customer',
                onPressed: _selectedRole == null || _isSubmitting ? null : _handleContinue, showArrow: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}