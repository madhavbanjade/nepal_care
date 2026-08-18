import 'package:flutter/material.dart';
import 'package:nepal_care/features/widget/back_pill_button.dart';
import 'package:nepal_care/features/widget/primary_button.dart';
import 'package:nepal_care/role/data/provider_prrofile.dart';
import 'package:nepal_care/role/data/user_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_theme.dart';
import '../widgets/checklist_item.dart';
import '../widgets/document_upload_field.dart';
import '../widgets/onboarding_progress_bar.dart';
import 'profile_submitted_screen.dart';

const _serviceCategories = [
  'Baby care',
  'Senior care',
  'Pet care',
  'Special needs care',
  'Housekeeping',
];

const _experienceLevels = [
  'Less than 1 year',
  '1–2 years',
  '3–5 years',
  '5+ years',
];

/// Step 2 of onboarding — providers fill this out before their account is
/// submitted for verification.
///
/// NOTE on ID/Certificate upload: intentionally disabled for now. Storing
/// files (Cloudflare R2 / Firebase Storage) needs a paid plan we're not on
/// yet, so this field is decorative — it never touches file_picker or any
/// storage bucket, and it does not affect submit eligibility. To re-enable:
/// bring back file_picker, wire DocumentUploadField's onTap to a picker
/// method, and add the upload call before submitProviderProfile.
///
/// [uid] is the signed-in user's Firebase Auth uid — same as
/// RoleSelectionScreen, wire it up from wherever you navigate here.
class ProviderProfileScreen extends StatefulWidget {
  const ProviderProfileScreen({super.key, required this.uid});

  final String uid;

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  final _userRepository = UserRepository();

  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();

  String? _serviceCategory;
  String? _experienceLevel;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    for (final controller in [_fullNameController, _phoneController, _bioController]) {
      controller.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  bool get _hasFullName => _fullNameController.text.trim().isNotEmpty;
  bool get _hasPhone => _phoneController.text.trim().length >= 7;
  bool get _hasCategory => _serviceCategory != null;
  bool get _hasExperience => _experienceLevel != null;
  bool get _hasBio => _bioController.text.trim().length >= 20;

  // ID upload is optional and currently disabled entirely — it's excluded
  // from both completeness and the checklist below.
  bool get _isComplete =>
      _hasFullName && _hasPhone && _hasCategory && _hasExperience && _hasBio;

  Future<void> _handleSubmit() async {
    if (!_isComplete || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      final profile = ProviderProfile(
        fullName: _fullNameController.text.trim(),
        phone: '+977 ${_phoneController.text.trim()}',
        serviceCategory: _serviceCategory!,
        yearsOfExperience: _experienceLevel!,
        bio: _bioController.text.trim(),
        // idDocumentUrl intentionally omitted — no file storage for now.
      );
      await _userRepository.submitProviderProfile(widget.uid, profile);

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ProfileSubmittedScreen()),
      );
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
              const OnboardingProgressBar(step: 2, totalSteps: 3),
              const SizedBox(height: 24),

              Text('Professional profile', style: AppTextTheme.textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text(
                'Tell families about yourself. All fields help build trust with clients.',
                style: AppTextTheme.textTheme.bodyLarge?.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 20),

              const _FieldLabel('Full name'),
              TextField(
                controller: _fullNameController,
                decoration: const InputDecoration(hintText: 'e.g. Maddhab Shrestha'),
              ),
              const SizedBox(height: 14),

              const _FieldLabel('Phone number'),
              Row(
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
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(hintText: '98XXXXXXXX'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('Clients will contact you on this number.', style: AppTextTheme.textTheme.bodySmall),
              const SizedBox(height: 14),

              const _FieldLabel('Service category'),
              DropdownButtonFormField<String>(
                initialValue: _serviceCategory,
                decoration: const InputDecoration(hintText: 'Select your service category'),
                items: _serviceCategories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (value) => setState(() => _serviceCategory = value),
              ),
              const SizedBox(height: 14),

              const _FieldLabel('Years of experience'),
              DropdownButtonFormField<String>(
                initialValue: _experienceLevel,
                decoration: const InputDecoration(hintText: 'Select your experience level'),
                items: _experienceLevels
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) => setState(() => _experienceLevel = value),
              ),
              const SizedBox(height: 14),

              const _FieldLabel('Short bio'),
              TextField(
                controller: _bioController,
                maxLines: 4,
                maxLength: 280,
                decoration: const InputDecoration(
                  hintText: 'Describe your experience, approach, and what makes you a great caregiver...',
                  alignLabelWithHint: true,
                ),
              ),
              Text('Minimum 20 characters', style: AppTextTheme.textTheme.bodySmall),
              const SizedBox(height: 6),

              const _FieldLabel('ID / Certificate (Optional)'),
              Opacity(
                opacity: 0.5,
                child: IgnorePointer(
                  child: DocumentUploadField(fileName: null, onTap: () {}),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Document upload isn\'t available yet — you can skip this and submit without it.',
                style: AppTextTheme.textTheme.bodySmall,
              ),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profile completeness',
                      style: AppTextTheme.textTheme.labelLarge?.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    ChecklistItem(label: 'Full name', isComplete: _hasFullName),
                    ChecklistItem(label: 'Phone', isComplete: _hasPhone),
                    ChecklistItem(label: 'Category', isComplete: _hasCategory),
                    ChecklistItem(label: 'Experience', isComplete: _hasExperience),
                    ChecklistItem(label: 'Bio (20+ chars)', isComplete: _hasBio),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              PrimaryButton(
                label: _isSubmitting ? 'Submitting...' : 'Submit for verification',
                onPressed: _isComplete && !_isSubmitting ? _handleSubmit : null,
                showArrow: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: AppTextTheme.textTheme.bodyMedium?.copyWith(
          color: AppColors.textDark,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}