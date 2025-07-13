import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/community_providers.dart';
import '../providers/auth_providers.dart';
import '../core/constants.dart';

import '../core/navigation_service.dart';
import '../services/storage_service.dart'; // Added import for StorageService

class CreateCommunityScreen extends HookConsumerWidget {
  const CreateCommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check user authentication and role
    final userAsync = ref.watch(authNotifierProvider);
    final userRoleAsync = ref.watch(canCreateCommunityProvider);
    
    return userAsync.when(
      data: (user) {
        if (user == null) {
          // Redirect to auth screen if no user
          WidgetsBinding.instance.addPostFrameCallback((_) {
            NavigationService.navigateToPhoneAuth();
          });
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        return userRoleAsync.when(
          data: (canCreate) {
            if (!canCreate) {
              // Show access denied screen for anonymous users
                      return Scaffold(
          appBar: AppBar(
            title: const Text('Access Denied'),
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => NavigationService.goBack(),
            ),
          ),
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.defaultPadding),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 64,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: AppConstants.defaultPadding),
                        Text(
                          'Access Denied',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppConstants.smallPadding),
                        Text(
                          'Anonymous users cannot create communities. Please sign in with your phone number to continue.',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppConstants.largePadding),
                        ElevatedButton(
                          onPressed: () => NavigationService.navigateToPhoneAuth(),
                          child: const Text('Sign In'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            
            // User is authenticated and not anonymous, show create community screen
            return _buildCreateCommunityContent(context, ref);
          },
          loading: () => const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          ),
          error: (_, __) => Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  const Text('Error loading user data'),
                  const SizedBox(height: AppConstants.smallPadding),
                  ElevatedButton(
                    onPressed: () => NavigationService.goBack(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (_, __) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              const Text('Error loading user data'),
              const SizedBox(height: AppConstants.smallPadding),
              ElevatedButton(
                onPressed: () => NavigationService.goBack(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreateCommunityContent(BuildContext context, WidgetRef ref) {
    final nameController = useTextEditingController();
    final descriptionController = useTextEditingController();
    final welcomeMessageController = useTextEditingController(); // NEW: welcome message
    final visibility = useState('public');
    final isBusiness = useState(false);
    final approvalRequired = useState(false);
    final selectedColor = useState('#2196F3');
    final coverImage = useState<String?>(null);
    final badgeIcon = useState<String?>(null); // NEW: badge/icon url
    final isLoading = useState(false);
    final showAdvancedOptions = useState(false);
    final selectedBadgeFile = useState<File?>(null); // NEW: badge/icon file
    final selectedCoverFile = useState<File?>(null); // for cover image
    final joinQuestions = useState<List<String>>([]); // NEW: join questions
    final rules = useState<List<String>>([]); // NEW: community rules

    final formValidation = ref.watch(communityFormValidationProvider);
    final isFormValid = ref.watch(communityFormIsValidProvider);
    final storageService = ref.watch(storageServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Community'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => NavigationService.goBack(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 16),
              _buildNameField(context, nameController, formValidation, ref),
              const SizedBox(height: 16),
              _buildDescriptionField(context, descriptionController, formValidation, ref),
              const SizedBox(height: 16),
              // NEW: Welcome Message field
              _buildWelcomeMessageField(context, welcomeMessageController),
              const SizedBox(height: 16),
              _buildVisibilitySection(context, visibility),
              const SizedBox(height: 16),
              _buildCommunityTypeSection(context, isBusiness),
              const SizedBox(height: 16),
              _buildApprovalSection(context, approvalRequired),
              const SizedBox(height: 16),
              _buildAdvancedOptionsToggle(context, showAdvancedOptions),
              if (showAdvancedOptions.value) ...[
                const SizedBox(height: 16),
                _buildThemeSection(context, selectedColor),
                const SizedBox(height: 16),
                // NEW: Badge/Icon upload section
                _buildBadgeIconSection(context, badgeIcon, selectedBadgeFile, storageService, isLoading),
                const SizedBox(height: 16),
                // NEW: Join Questions section
                _buildJoinQuestionsSection(context, joinQuestions),
                const SizedBox(height: 16),
                // NEW: Community Rules section
                _buildCommunityRulesSection(context, rules),
                const SizedBox(height: 16),
                _buildCoverImageSection(context, coverImage),
              ],
              const SizedBox(height: 16),
              _buildAdditionalFeatures(context),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildCreateButton(
          context,
          ref,
          nameController,
          descriptionController,
          welcomeMessageController, // NEW
          visibility,
          isBusiness,
          approvalRequired,
          selectedColor,
          coverImage,
          badgeIcon, // NEW
          joinQuestions, // NEW
          rules, // NEW
          isFormValid,
          isLoading,
          selectedBadgeFile,
          selectedCoverFile,
        ),
      ),
    );
  }

  // NEW: Welcome Message field
  Widget _buildWelcomeMessageField(BuildContext context, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome Message',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.smallPadding),
        Text(
          'Optional message shown to new members when they join your community.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: AppConstants.smallPadding),
        TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Welcome new members with a friendly message...',
            prefixIcon: const Icon(Icons.waving_hand),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.add_business,
            size: 48,
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
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildNameField(BuildContext context, TextEditingController controller, Map<String, String> validation, WidgetRef ref) {
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
            ref.read(communityFormProvider.notifier).update((state) => {
              ...state,
              'name': value,
            });
          },
        ),
      ],
    );
  }

  Widget _buildDescriptionField(BuildContext context, TextEditingController controller, Map<String, String> validation, WidgetRef ref) {
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
          onChanged: (value) {
            ref.read(communityFormProvider.notifier).update((state) => {
              ...state,
              'description': value,
            });
          },
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
    return Semantics(
      label: title,
      selected: isSelected,
      child: Card(
        elevation: isSelected ? 2 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isSelected
              ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: () => visibility.value = value,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              children: [
                Icon(
                  icon,
                  color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
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
    return Semantics(
      label: title,
      selected: isSelected,
      child: Card(
        elevation: isSelected ? 2 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isSelected
              ? BorderSide(color: Theme.of(context).colorScheme.secondary, width: 2)
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: () => isBusiness.value = value,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              children: [
                Icon(
                  icon,
                  color: isSelected ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
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
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                approvalRequired.value ? Icons.approval : Icons.person_add,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
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
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: approvalRequired.value,
                onChanged: (value) => approvalRequired.value = value,
                activeColor: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildThemeSection(BuildContext context, ValueNotifier<String> selectedColor) {
    final colorScheme = Theme.of(context).colorScheme;
    final colors = [
      colorScheme.primary.toARGB32().toRadixString(16),
      colorScheme.secondary.toARGB32().toRadixString(16),
      colorScheme.tertiary.toARGB32().toRadixString(16),
      colorScheme.error.toARGB32().toRadixString(16),
      colorScheme.surface.toARGB32().toRadixString(16),
      colorScheme.surface.toARGB32().toRadixString(16), // Changed from background to surface
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
            // Robust color parsing
            String normalized = color.replaceAll('#', '');
            if (normalized.length == 6) {
              normalized = 'FF$normalized'; // Add alpha if missing
            }
            final colorValue = int.parse(normalized, radix: 16);
            return GestureDetector(
              onTap: () => selectedColor.value = color,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Color(colorValue),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Color(colorValue).withValues(alpha: 0.3),
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
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                coverImage.value!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.broken_image,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurface,
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
              icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
              label: Text(
                'Remove Image',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
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
    TextEditingController welcomeMessageController, // NEW
    ValueNotifier<String> visibility,
    ValueNotifier<bool> isBusiness,
    ValueNotifier<bool> approvalRequired,
    ValueNotifier<String> selectedColor,
    ValueNotifier<String?> coverImage,
    ValueNotifier<String?> badgeIcon, // NEW
    ValueNotifier<List<String>> joinQuestions, // NEW
    ValueNotifier<List<String>> rules, // NEW
    bool isFormValid,
    ValueNotifier<bool> isLoading,
    ValueNotifier<File?> selectedBadgeFile, // NEW
    ValueNotifier<File?> selectedCoverFile, // for cover image
  ) {
    final storageService = ref.watch(storageServiceProvider);
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isFormValid && !isLoading.value
            ? () async {
                isLoading.value = true;
                final overlay = Overlay.of(context);
                final overlayEntry = OverlayEntry(
                  builder: (context) => Positioned.fill(
                    child: Container(
                      color: Colors.black54,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
                );
                overlay.insert(overlayEntry);
                try {
                  String? finalCoverImageUrl = coverImage.value;
                  String? finalBadgeIconUrl = badgeIcon.value;
                  if (selectedCoverFile.value != null) {
                    final tempCommunityId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
                    final uploadedUrl = await storageService.uploadCommunityCoverImage(
                      communityId: tempCommunityId,
                      imageFile: selectedCoverFile.value!,
                    );
                    finalCoverImageUrl = uploadedUrl ?? finalCoverImageUrl;
                  }
                  if (selectedBadgeFile.value != null) {
                    final tempCommunityId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
                    final uploadedBadgeUrl = await storageService.uploadCommunityBadgeIcon(
                      communityId: tempCommunityId,
                      imageFile: selectedBadgeFile.value!,
                    );
                    finalBadgeIconUrl = uploadedBadgeUrl ?? finalBadgeIconUrl;
                  }
                  final createdCommunity = await ref.read(communityActionsProvider.notifier).createCommunity(
                    name: nameController.text.trim(),
                    description: descriptionController.text.trim(),
                    welcomeMessage: welcomeMessageController.text.trim(), // NEW
                    coverImage: finalCoverImageUrl,
                    badgeUrl: finalBadgeIconUrl, // NEW
                    visibility: visibility.value,
                    approvalRequired: approvalRequired.value,
                    isBusiness: isBusiness.value,
                    joinQuestions: joinQuestions.value, // NEW
                    rules: rules.value, // NEW
                    theme: {
                      'color': selectedColor.value,
                      'banner_url': finalCoverImageUrl ?? '',
                    },
                  );
                  overlayEntry.remove();
                  if (!context.mounted) return;
                  
                  // Show success dialog and navigate to community
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => AlertDialog(
                      title: Row(
                        children: [
                          const Icon(Icons.celebration, color: Colors.orange),
                          const SizedBox(width: 8),
                          const Text('🎉 Success!'),
                        ],
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Your community has been created successfully!'),
                          const SizedBox(height: 8),
                          Text(
                            'Name: ${createdCommunity?.name ?? 'Unknown'}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text('You\'ll be redirected to your community page where you can start inviting members and creating content.'),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context); // Close dialog
                            // Navigate to the newly created community
                            if (createdCommunity != null) {
                              NavigationService.navigateToCommunityDetails(createdCommunity.id);
                            } else {
                              // Fallback: go back to home
                              Navigator.pop(context);
                            }
                          },
                          child: const Text('View Community'),
                        ),
                      ],
                    ),
                  );
                } catch (e) {
                  overlayEntry.remove();
                  if (!context.mounted) return;
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Error'),
                      content: Text('Failed to create community: $e'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                } finally {
                  isLoading.value = false;
                }
              }
            : null,
        style: Theme.of(context).elevatedButtonTheme.style,
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
                ),
              ),
      ),
    );
  }

  Widget _buildAdvancedOptionsToggle(BuildContext context, ValueNotifier<bool> showAdvancedOptions) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.tune,
            color: Theme.of(context).colorScheme.primary,
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
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Customize theme and cover image',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: showAdvancedOptions.value,
            onChanged: (value) => showAdvancedOptions.value = value,
            activeColor: Theme.of(context).colorScheme.primary,
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
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
            color: isEnabled ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1) : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isEnabled ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
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
                  color: isEnabled ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isEnabled ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            isEnabled ? 'Included' : 'Coming Soon',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isEnabled ? Colors.white : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
      ],
    );
  }

  // NEW: Badge/Icon upload section
  Widget _buildBadgeIconSection(
    BuildContext context,
    ValueNotifier<String?> badgeIcon,
    ValueNotifier<File?> selectedBadgeFile,
    StorageService storageService,
    ValueNotifier<bool> isLoading,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Community Icon/Logo',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (badgeIcon.value != null && badgeIcon.value!.isNotEmpty)
              CircleAvatar(
                radius: 32,
                backgroundImage: NetworkImage(badgeIcon.value!),
              )
            else if (selectedBadgeFile.value != null)
              CircleAvatar(
                radius: 32,
                backgroundImage: FileImage(selectedBadgeFile.value!),
              )
            else
              CircleAvatar(
                radius: 32,
                backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                child: Icon(Icons.image, size: 32, color: Theme.of(context).colorScheme.primary),
              ),
            const SizedBox(width: 16),
            Flexible(
              child: ElevatedButton.icon(
                onPressed: isLoading.value
                    ? null
                    : () async {
                        final picked = await storageService.pickImageFromGallery();
                        if (picked != null) {
                          selectedBadgeFile.value = picked;
                          badgeIcon.value = null; // Will upload on create
                        }
                      },
                icon: const Icon(Icons.photo_library),
                label: const Text('Choose Icon'),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: ElevatedButton.icon(
                onPressed: isLoading.value
                    ? null
                    : () async {
                        final picked = await storageService.pickImageFromGallery();
                        if (picked != null) {
                          selectedBadgeFile.value = picked;
                          badgeIcon.value = null; // Will upload on create
                        }
                      },
                icon: const Icon(Icons.camera_alt),
                label: const Text('Take Photo'),
              ),
            ),
            if (selectedBadgeFile.value != null || (badgeIcon.value != null && badgeIcon.value!.isNotEmpty))
              IconButton(
                icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                onPressed: isLoading.value
                    ? null
                    : () {
                        selectedBadgeFile.value = null;
                        badgeIcon.value = null;
                      },
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Upload a square image for your community icon/logo. This will be shown in lists and headers.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
        ),
      ],
    );
  }

  // NEW: Join Questions section
  Widget _buildJoinQuestionsSection(
    BuildContext context,
    ValueNotifier<List<String>> joinQuestions,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Join Questions',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Add questions that new members must answer when joining your community.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // Display existing questions
              ...joinQuestions.value.asMap().entries.map((entry) {
                final index = entry.key;
                final question = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: AppConstants.smallPadding),
                  padding: const EdgeInsets.all(AppConstants.smallPadding),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${index + 1}. $question',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                        onPressed: () {
                          final newQuestions = List<String>.from(joinQuestions.value);
                          newQuestions.removeAt(index);
                          joinQuestions.value = newQuestions;
                        },
                      ),
                    ],
                  ),
                );
              }),
              
              // Add new question button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showAddQuestionDialog(context, joinQuestions),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Question'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper method to show add question dialog
  void _showAddQuestionDialog(BuildContext context, ValueNotifier<List<String>> joinQuestions) {
    final questionController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Join Question'),
        content: TextField(
          controller: questionController,
          decoration: const InputDecoration(
            hintText: 'Enter your question...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final question = questionController.text.trim();
              if (question.isNotEmpty) {
                final newQuestions = List<String>.from(joinQuestions.value);
                newQuestions.add(question);
                joinQuestions.value = newQuestions;
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // NEW: Community Rules section
  Widget _buildCommunityRulesSection(
    BuildContext context,
    ValueNotifier<List<String>> rules,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Community Rules',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Set guidelines that all members must follow in your community.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // Display existing rules
              ...rules.value.asMap().entries.map((entry) {
                final index = entry.key;
                final rule = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: AppConstants.smallPadding),
                  padding: const EdgeInsets.all(AppConstants.smallPadding),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.error,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          rule,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                        onPressed: () {
                          final newRules = List<String>.from(rules.value);
                          newRules.removeAt(index);
                          rules.value = newRules;
                        },
                      ),
                    ],
                  ),
                );
              }),
              
              // Add new rule button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showAddRuleDialog(context, rules),
                  icon: const Icon(Icons.gavel),
                  label: const Text('Add Rule'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper method to show add rule dialog
  void _showAddRuleDialog(BuildContext context, ValueNotifier<List<String>> rules) {
    final ruleController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Community Rule'),
        content: TextField(
          controller: ruleController,
          decoration: const InputDecoration(
            hintText: 'Enter your rule/guideline...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final rule = ruleController.text.trim();
              if (rule.isNotEmpty) {
                final newRules = List<String>.from(rules.value);
                newRules.add(rule);
                rules.value = newRules;
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
} 