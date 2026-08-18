import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_theme.dart';

/// The ID/Certificate upload box. Shows an empty dropzone prompt, or a
/// green "file selected" card once something's been picked.
class DocumentUploadField extends StatelessWidget {
  const DocumentUploadField({
    super.key,
    required this.fileName,
    required this.onTap,
  });

  final String? fileName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasFile = fileName != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: hasFile ? const Color(0xFFE9F9EE) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasFile ? const Color(0xFF9AD9B4) : AppColors.borderGray,
          ),
        ),
        child: hasFile
            ? Row(
                children: [
                  const Icon(Icons.description_outlined, color: Color(0xFF2E9E5B)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fileName!,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextTheme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text('Tap to replace', style: AppTextTheme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  const Icon(Icons.check_circle, color: Color(0xFF2E9E5B)),
                ],
              )
            : Column(
                children: [
                  const Icon(Icons.upload_file_outlined, color: AppColors.textMuted),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to upload your ID or certificate',
                    style: AppTextTheme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Accepted: JPG, PNG, PDF · max 4 MB',
                    style: AppTextTheme.textTheme.bodySmall,
                  ),
                ],
              ),
      ),
    );
  }
}