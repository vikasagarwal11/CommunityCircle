import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/community_providers.dart';
import '../services/storage_service.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../core/navigation_service.dart';
import '../models/community_model.dart';

class CreateCommunityScreen extends HookConsumerWidget {
  const CreateCommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameController = useTextEditingController();
    final descriptionController = useTextEditingController();
    final visibility = useState('public');
    final isBusiness = useState(false);
    final approvalRequired = useState(false);
    final selectedColor = useState('#2196F3');
    final coverImage = useState<String?>(null);
    final isLoading = useState(false);
    final showAdvancedOptions = useState(false);

    final formValidation = ref.watch(communityFormValidationProvider);
    final isFormValid = ref.watch(communityFormIsValidProvider);
    final communityActionsAsync = ref.watch(communityActionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Community'),
        backgroundColor: AppTheme.neutralWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => NavigationService.goBack(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(context),
            const SizedBox(height: AppConstants.largePadding),
            
            // Community Name
            _buildNameField(context, nameController, formValidation),
            const SizedBox(height: AppConstants.defaultPadding),
            
            // Description
            _buildDescriptionField(context, descriptionController, formValidation),
            const SizedBox(height: AppConstants.defaultPadding),
            
            // Visibility Settings
            _buildVisibilitySection(context, visibility),
            const SizedBox(height: AppConstants.defaultPadding),
            
            // Community Type
            _buildCommunityTypeSection(context, isBusiness),
            const SizedBox(height: AppConstants.defaultPadding),
            
            // Approval Settings
            _buildApprovalSection(context, approvalRequired),
            const SizedBox(height: AppConstants.defaultPadding),
            
            // Advanced Options Toggle
            _buildAdvancedOptionsToggle(context, showAdvancedOptions),
            
            // Advanced Options (Conditional)
            if (showAdvancedOptions.value) ...[
              const SizedBox(height: AppConstants.defaultPadding),
              _buildThemeSection(context, selectedColor),
              const SizedBox(height: AppConstants.defaultPadding),
              _buildCoverImageSection(context, coverImage),
            ],
            const SizedBox(height: AppConstants.largePadding),
            
            // Create Button
            _buildCreateButton(
              context,
              ref,
              nameController,
              descriptionController,
              visibility,
              isBusiness,
              approvalRequired,
              selectedColor,
              coverImage,
              isFormValid,
              isLoading,
            ),
            
            // Additional Features Section
            const SizedBox(height: AppConstants.largePadding),
            _buildAdditionalFeatures(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.add_business,
            size: 48,
            color: AppTheme.primaryBlue,
          ),
        ),
        const SizedBox(height: AppConstants.defaultPadding),
        Text(
          'Create Your Community',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.smallPadding),
        Text(
          'Build a space where people can connect, share, and grow together.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppTheme.onSurfaceColor.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildNameField(BuildContext context, TextEditingController controller, Map<String, String> validation) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Community Name *',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.smallPadding),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Enter community name',
            prefixIcon: const Icon(Icons.group),
            errorText: validation['name'],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onChanged: (value) {
            // Form validation will be handled by the provider
          },
        ),
      ],
    );
  }

  Widget _buildDescriptionField(BuildContext context, TextEditingController controller, Map<String, String> validation) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description *',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.smallPadding),
        TextField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Describe your community...',
            prefixIcon: const Icon(Icons.description),
            errorText: validation['description'],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVisibilitySection(BuildContext context, ValueNotifier<String> visibility) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Visibility',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.smallPadding),
        Row(
          children: [
            Expanded(
              child: _buildVisibilityOption(
                context,
                'Public',
                'Anyone can find and join',
                Icons.public,
                'public',
                visibility,
              ),
            ),
            const SizedBox(width: AppConstants.smallPadding),
            Expanded(
              child: _buildVisibilityOption(
                context,
                'Private',
                'Invite-only access',
                Icons.lock,
                'private',
                visibility,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVisibilityOption(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    String value,
    ValueNotifier<String> visibility,
  ) {
    final isSelected = visibility.value == value;
    return GestureDetector(
      onTap: () => visibility.value = value,
      child: Container(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue.withOpacity(0.1) : AppTheme.neutralLightGray,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryBlue : AppTheme.onSurfaceColor.withOpacity(0.7),
              size: 24,
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? AppTheme.primaryBlue : AppTheme.onSurfaceColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.onSurfaceColor.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunityTypeSection(BuildContext context, ValueNotifier<bool> isBusiness) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Community Type',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.smallPadding),
        Row(
          children: [
            Expanded(
              child: _buildTypeOption(
                context,
                'Community',
                'For general communities',
                Icons.people,
                false,
                isBusiness,
              ),
            ),
            const SizedBox(width: AppConstants.smallPadding),
            Expanded(
              child: _buildTypeOption(
                context,
                'Business',
                'For business communities',
                Icons.business,
                true,
                isBusiness,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeOption(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueNotifier<bool> isBusiness,
  ) {
    final isSelected = isBusiness.value == value;
    return GestureDetector(
      onTap: () => isBusiness.value = value,
      child: Container(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGreen.withOpacity(0.1) : AppTheme.neutralLightGray,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryGreen : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryGreen : AppTheme.onSurfaceColor.withOpacity(0.7),
              size: 24,
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? AppTheme.primaryGreen : AppTheme.onSurfaceColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.onSurfaceColor.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovalSection(BuildContext context, ValueNotifier<bool> approvalRequired) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Join Requests',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.smallPadding),
        Container(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          decoration: BoxDecoration(
            color: AppTheme.neutralLightGray,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                approvalRequired.value ? Icons.approval : Icons.person_add,
                color: AppTheme.onSurfaceColor.withOpacity(0.7),
              ),
              const SizedBox(width: AppConstants.smallPadding),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      approvalRequired.value ? 'Approval Required' : 'Open to Join',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      approvalRequired.value
                          ? 'You\'ll approve each join request'
                          : 'Anyone can join directly',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.onSurfaceColor.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: approvalRequired.value,
                onChanged: (value) => approvalRequired.value = value,
                activeColor: AppTheme.primaryBlue,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildThemeSection(BuildContext context, ValueNotifier<String> selectedColor) {
    final colors = [
      '#2196F3', // Blue
      '#4CAF50', // Green
      '#FF9800', // Orange
      '#9C27B0', // Purple
      '#F44336', // Red
      '#00BCD4', // Cyan
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Theme Color',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.smallPadding),
        Wrap(
          spacing: AppConstants.smallPadding,
          runSpacing: AppConstants.smallPadding,
          children: colors.map((color) {
            final isSelected = selectedColor.value == color;
            return GestureDetector(
              onTap: () => selectedColor.value = color,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Color(int.parse(color.replaceAll('#', '0xFF'))),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Color(int.parse(color.replaceAll('#', '0xFF'))).withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 24,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCoverImageSection(BuildContext context, ValueNotifier<String?> coverImage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cover Image',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.smallPadding),
        
        // Image preview
        if (coverImage.value != null) ...[
          Container(
            width: double.infinity,
            height: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.onSurfaceColor.withOpacity(0.2),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                coverImage.value!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppTheme.neutralLightGray,
                  child: const Icon(
                    Icons.broken_image,
                    size: 48,
                    color: AppTheme.onSurfaceColor,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppConstants.smallPadding),
        ],
        
        // Upload buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  // TODO: Implement image picker
                  coverImage.value = 'https://via.placeholder.com/400x200';
                },
                icon: const Icon(Icons.photo_library),
                label: const Text('Choose from Gallery'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppConstants.smallPadding),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  // TODO: Implement camera
                  coverImage.value = 'https://via.placeholder.com/400x200';
                },
                icon: const Icon(Icons.camera_alt),
                label: const Text('Take Photo'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
        
        if (coverImage.value != null) ...[
          const SizedBox(height: AppConstants.smallPadding),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => coverImage.value = null,
              icon: const Icon(Icons.delete, color: AppTheme.errorColor),
              label: const Text(
                'Remove Image',
                style: TextStyle(color: AppTheme.errorColor),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCreateButton(
    BuildContext context,
    WidgetRef ref,
    TextEditingController nameController,
    TextEditingController descriptionController,
    ValueNotifier<String> visibility,
    ValueNotifier<bool> isBusiness,
    ValueNotifier<bool> approvalRequired,
    ValueNotifier<String> selectedColor,
    ValueNotifier<String?> coverImage,
    bool isFormValid,
    ValueNotifier<bool> isLoading,
  ) {
    final storageService = ref.watch(storageServiceProvider);
    final selectedImageFile = useState<File?>(null);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isFormValid && !isLoading.value
            ? () async {
                isLoading.value = true;
                
                try {
                  String? finalCoverImageUrl = coverImage.value;
                  
                  // Upload image if selected
                  if (selectedImageFile.value != null) {
                    NavigationService.showSnackBar(
                      message: 'Uploading image...',
                      backgroundColor: AppTheme.primaryBlue,
                    );
                    
                    // Create a temporary community ID for upload
                    final tempCommunityId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
                    final uploadedUrl = await storageService.uploadCommunityCoverImage(
                      communityId: tempCommunityId,
                      imageFile: selectedImageFile.value!,
                    );
                    
                    if (uploadedUrl != null) {
                      finalCoverImageUrl = uploadedUrl;
                    } else {
                      throw Exception('Failed to upload image');
                    }
                  }
                  
                  // Create community
                  await ref.read(communityActionsProvider.notifier).createCommunity(
                    name: nameController.text.trim(),
                    description: descriptionController.text.trim(),
                    coverImage: finalCoverImageUrl,
                    visibility: visibility.value,
                    approvalRequired: approvalRequired.value,
                    isBusiness: isBusiness.value,
                    theme: {
                      'color': selectedColor.value,
                      'banner_url': finalCoverImageUrl ?? '',
                    },
                  );
                } catch (e) {
                  NavigationService.showSnackBar(
                    message: 'Failed to create community: $e',
                    backgroundColor: AppTheme.errorColor,
                  );
                } finally {
                  isLoading.value = false;
                }
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryBlue,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading.value
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Create Community',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildAdvancedOptionsToggle(BuildContext context, ValueNotifier<bool> showAdvancedOptions) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: AppTheme.neutralLightGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.tune,
            color: AppTheme.primaryBlue,
            size: 20,
          ),
          const SizedBox(width: AppConstants.smallPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Advanced Options',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.onSurfaceColor,
                  ),
                ),
                Text(
                  'Customize theme and cover image',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.onSurfaceColor.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: showAdvancedOptions.value,
            onChanged: (value) => showAdvancedOptions.value = value,
            activeColor: AppTheme.primaryBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalFeatures(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Features',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.smallPadding),
        Container(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          decoration: BoxDecoration(
            color: AppTheme.neutralLightGray,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildFeatureItem(
                context,
                Icons.emoji_events,
                'Gamification',
                'Enable points, badges, and leaderboards',
                true,
              ),
              const SizedBox(height: AppConstants.smallPadding),
              _buildFeatureItem(
                context,
                Icons.analytics,
                'Analytics',
                'Track community engagement and growth',
                true,
              ),
              const SizedBox(height: AppConstants.smallPadding),
              _buildFeatureItem(
                context,
                Icons.notifications,
                'Smart Notifications',
                'Intelligent alerts for important updates',
                true,
              ),
              const SizedBox(height: AppConstants.smallPadding),
              _buildFeatureItem(
                context,
                Icons.security,
                'Content Moderation',
                'AI-powered inappropriate content detection',
                true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(
    BuildContext context,
    IconData icon,
    String title,
    String description,
    bool isEnabled,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isEnabled ? AppTheme.primaryGreen.withOpacity(0.1) : AppTheme.neutralLightGray,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isEnabled ? AppTheme.primaryGreen : AppTheme.onSurfaceColor.withOpacity(0.5),
            size: 20,
          ),
        ),
        const SizedBox(width: AppConstants.smallPadding),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isEnabled ? AppTheme.onSurfaceColor : AppTheme.onSurfaceColor.withOpacity(0.5),
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.onSurfaceColor.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isEnabled ? AppTheme.primaryGreen : AppTheme.neutralLightGray,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            isEnabled ? 'Included' : 'Coming Soon',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isEnabled ? Colors.white : AppTheme.onSurfaceColor.withOpacity(0.5),
            ),
          ),
        ),
      ],
    );
  }
} 