import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../domain/services/voice_recognition_service.dart';

/// Language selector widget for voice input
class VoiceLanguageSelector extends StatelessWidget {
  final String selectedLanguage;
  final Function(String) onLanguageChanged;

  const VoiceLanguageSelector({
    super.key,
    required this.selectedLanguage,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMD,
        vertical: AppDimensions.paddingSM,
      ),
      color: AppColors.lightSurface,
      child: Row(
        children: [
          Icon(
            Icons.language,
            color: AppColors.primaryBlue,
            size: AppDimensions.iconMD,
          ),
          const SizedBox(width: AppDimensions.spacingSM),
          Text(
            'Language:',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: AppDimensions.spacingSM),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: VoiceRecognitionService.availableLanguages.entries
                    .map(
                      (entry) =>
                          _buildLanguageChip(context, entry.key, entry.value),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageChip(BuildContext context, String code, String name) {
    final isSelected = selectedLanguage == code;

    return Padding(
      padding: const EdgeInsets.only(right: AppDimensions.spacingSM),
      child: FilterChip(
        label: Text(name),
        selected: isSelected,
        onSelected: (_) => onLanguageChanged(code),
        backgroundColor: AppColors.lightBackground,
        selectedColor: AppColors.primaryBlue.withOpacity(0.1),
        checkmarkColor: AppColors.primaryBlue,
        labelStyle: TextStyle(
          color: isSelected
              ? AppColors.primaryBlue
              : AppColors.lightTextPrimary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.chipRadius),
          side: BorderSide(
            color: isSelected ? AppColors.primaryBlue : AppColors.lightBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingSM,
          vertical: 4,
        ),
      ),
    );
  }
}
