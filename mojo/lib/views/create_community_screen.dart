import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/community_providers.dart';
import '../providers/auth_providers.dart';
import '../core/constants.dart';
import '../core/navigation_service.dart';
import '../services/storage_service.dart';
import 'create_community_screen_widgets.dart';
import 'create_community_screen_logic.dart';

class CreateCommunityScreen extends HookConsumerWidget {
  final Map<String, dynamic>? eventTemplate;
  
  const CreateCommunityScreen({
    super.key,
    this.eventTemplate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    print('🔍 CreateCommunityScreen: build() called');
    print('🔍 CreateCommunityScreen: eventTemplate = $eventTemplate');
    
    // Check if user is authenticated
    final userAsync = ref.watch(authNotifierProvider);
    
    return userAsync.when(
      data: (user) {
        print('🔍 CreateCommunityScreen: User data received: ${user?.displayName}');
        if (user == null) {
          print('🔍 CreateCommunityScreen: User is null, showing error');
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
            body: const Center(
              child: Text('User not authenticated'),
            ),
          );
        }
        
        print('🔍 CreateCommunityScreen: User authenticated, building content');
        return _buildCreateCommunityContent(context, ref);
      },
      loading: () {
        print('🔍 CreateCommunityScreen: Loading user data');
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
      error: (error, stack) {
        print('🔍 CreateCommunityScreen: Error loading user: $error');
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
          body: Center(
            child: Text('Error: $error'),
          ),
        );
      },
    );
  }

  Widget _buildCreateCommunityContent(BuildContext context, WidgetRef ref) {
    print('🔍 CreateCommunityScreen: _buildCreateCommunityContent() called');
    
    final nameController = useTextEditingController();
    final descriptionController = useTextEditingController();
    final welcomeMessageController = useTextEditingController();
    final visibility = useState('public');
    final isBusiness = useState(false);
    final approvalRequired = useState(false);
    final selectedColor = useState('#2196F3');
    final coverImage = useState<String?>(null);
    final badgeIcon = useState<String?>(null);
    final isLoading = useState(false);
    final showAdvancedOptions = useState(false);
    final selectedBadgeFile = useState<File?>(null);
    final selectedCoverFile = useState<File?>(null);
    final joinQuestions = useState<List<String>>([]);
    final rules = useState<List<String>>([]);
    final tags = useState<List<String>>([]);
    final enhancedPrivacy = useState(false);
    final selectedTheme = useState('default');
    final customTheme = useState<Map<String, dynamic>>({
      'primaryColor': '#2196F3',
      'secondaryColor': '#FFC107',
      'backgroundColor': '#FFFFFF',
    });

    print('🔍 CreateCommunityScreen: Controllers and state initialized');

    // Add debug logging
    print('🔍 CreateCommunityScreen: Building feature-rich form content');
    print('🔍 CreateCommunityScreen: User is authenticated');

    // Pre-fill form if event template is provided
    useEffect(() {
      if (eventTemplate != null) {
        print('🔍 CreateCommunityScreen: Event template provided: $eventTemplate');
        final template = eventTemplate!;
        nameController.text = template['title']?.toString().replaceAll('Community', '').trim() ?? '';
        descriptionController.text = template['description']?.toString() ?? '';
        
        // Set appropriate tags based on template type
        final templateType = template['templateType']?.toString() ?? '';
        switch (templateType) {
          case 'Meeting':
            tags.value = ['meeting', 'community', 'discussion'];
            break;
          case 'Workshop':
            tags.value = ['workshop', 'education', 'learning'];
            break;
          case 'Social':
            tags.value = ['social', 'networking', 'gathering'];
            break;
          case 'Webinar':
            tags.value = ['webinar', 'online', 'presentation'];
            break;
          case 'Hackathon':
            tags.value = ['hackathon', 'coding', 'technology'];
            break;
        }
      }
      return null;
    }, [eventTemplate]);

    // Use original providers with error handling
    final formValidationAsync = ref.watch(communityFormValidationProvider);
    final isFormValidAsync = ref.watch(communityFormIsValidProvider);
    final storageService = ref.watch(storageServiceProvider);

    print('🔍 CreateCommunityScreen: Providers watched');

    // Handle provider states with fallbacks
    final formValidation = formValidationAsync ?? <String, String>{};
    final isFormValid = isFormValidAsync ?? false;

    print('🔍 CreateCommunityScreen: Form validation: $formValidation');
    print('🔍 CreateCommunityScreen: Is form valid: $isFormValid');
    print('🔍 CreateCommunityScreen: Building widgets...');

    return Scaffold(
      appBar: AppBar(
        title: Text(eventTemplate != null ? 'Create Community & Event' : 'Create Community'),
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
              // Header section
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.group_add_rounded,
                          size: 32,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Create Community',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Build a vibrant community for your interests',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Show event template info if provided
              if (eventTemplate != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.event_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Event Template Selected',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${eventTemplate!['templateType']} - ${eventTemplate!['title']}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Feature-rich form sections
              const SizedBox(height: 16),
              
              // ===== RESTORE ALL ORIGINAL FEATURES =====
              
              // Name Field - Simple test
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Community Name *',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: 'Enter community name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        errorText: formValidation['name'],
                      ),
                      onChanged: (value) {
                        // Update validation when text changes
                        ref.read(communityFormProvider.notifier).update((state) => {
                          ...state,
                          'name': value,
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Description Field - Simple test
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Description *',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Enter community description',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        errorText: formValidation['description'],
                      ),
                      onChanged: (value) {
                        // Update validation when text changes
                        ref.read(communityFormProvider.notifier).update((state) => {
                          ...state,
                          'description': value,
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Tags Field - Restore actual functionality
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tags',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add tags to help people discover your community. Separate tags with commas.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'e.g., technology, mobile, development',
                        prefixIcon: Icon(Icons.tag),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onSubmitted: (value) {
                        if (value.trim().isNotEmpty) {
                          final newTags = value.split(',').map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList();
                          tags.value = [...tags.value, ...newTags];
                        }
                      },
                    ),
                    if (tags.value.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: tags.value.map((tag) => Chip(
                          label: Text(tag),
                          deleteIcon: Icon(Icons.close, size: 16),
                          onDeleted: () {
                            tags.value = tags.value.where((t) => t != tag).toList();
                          },
                        )).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Welcome Message Field - Restore actual functionality
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome Message (Optional)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Optional message shown to new members when they join your community.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: welcomeMessageController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Welcome new members with a friendly message...',
                        prefixIcon: Icon(Icons.waving_hand),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Visibility Section - Restore actual functionality
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Visibility',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose who can see and join your community.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Radio<String>(
                          value: 'public',
                          groupValue: visibility.value,
                          onChanged: (value) {
                            visibility.value = value ?? 'public';
                          },
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Public'),
                              Text(
                                'Anyone can find and join',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Radio<String>(
                          value: 'private',
                          groupValue: visibility.value,
                          onChanged: (value) {
                            visibility.value = value ?? 'public';
                          },
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Private'),
                              Text(
                                'Only invited members can join',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Community Type Section - Restore actual functionality
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Community Type',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Checkbox(
                          value: isBusiness.value,
                          onChanged: (value) {
                            isBusiness.value = value ?? false;
                          },
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Business Community'),
                              Text(
                                'For professional networking and business discussions',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Checkbox(
                          value: approvalRequired.value,
                          onChanged: (value) {
                            approvalRequired.value = value ?? false;
                          },
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Require Approval'),
                              Text(
                                'Manually approve new member requests',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Advanced Options Toggle - Restore actual functionality
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Advanced Options',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                        Switch(
                          value: showAdvancedOptions.value,
                          onChanged: (value) {
                            showAdvancedOptions.value = value;
                          },
                        ),
                      ],
                    ),
                    if (showAdvancedOptions.value) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Customize your community with advanced settings',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Theme & Branding Section
                      Row(
                        children: [
                          Icon(Icons.palette, color: Colors.blue, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Theme & Branding',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Theme Color Picker
                      Text(
                        'Theme Color',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: ['#2196F3', '#4CAF50', '#FF9800', '#9C27B0', '#F44336', '#00BCD4'].map((color) {
                          return GestureDetector(
                            onTap: () {
                              selectedColor.value = color;
                              print('🔍 Selected theme color: $color');
                            },
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Color(int.parse(color.replaceAll('#', '0xFF'))),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selectedColor.value == color ? Colors.blue : Colors.grey.shade300,
                                  width: selectedColor.value == color ? 2 : 1,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      
                      // Images & Media Section
                      Row(
                        children: [
                          Icon(Icons.photo_library, color: Colors.blue, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Images & Media',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Cover Image Upload
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.image, color: Colors.grey.shade600, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Upload Cover Image',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  if (selectedCoverFile.value != null)
                                    Text(
                                      'Image selected',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.green.shade600,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                print('🔍 Upload cover image pressed');
                                try {
                                  final result = await ref.read(storageServiceProvider).pickImage();
                                  if (result != null) {
                                    selectedCoverFile.value = result;
                                    print('🔍 Cover image selected: ${result.path}');
                                  }
                                } catch (e) {
                                  print('🔍 Error picking cover image: $e');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to select image: ${e.toString()}'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                              child: Text(
                                selectedCoverFile.value != null ? 'Change' : 'Choose',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Badge Icon Upload
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.badge, color: Colors.grey.shade600, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Upload Badge Icon',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  if (selectedBadgeFile.value != null)
                                    Text(
                                      'Badge selected',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.green.shade600,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                print('🔍 Upload badge icon pressed');
                                try {
                                  final result = await ref.read(storageServiceProvider).pickImage();
                                  if (result != null) {
                                    selectedBadgeFile.value = result;
                                    print('🔍 Badge icon selected: ${result.path}');
                                  }
                                } catch (e) {
                                  print('🔍 Error picking badge icon: $e');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to select badge: ${e.toString()}'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                              child: Text(
                                selectedBadgeFile.value != null ? 'Change' : 'Choose',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Privacy & Security Section
                      Row(
                        children: [
                          Icon(Icons.security, color: Colors.blue, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Privacy & Security',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Enhanced Privacy Settings
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(Icons.visibility, color: Colors.grey.shade600, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Enhanced Privacy',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                                Switch(
                                  value: enhancedPrivacy.value,
                                  onChanged: (value) {
                                    enhancedPrivacy.value = value;
                                  },
                                ),
                              ],
                            ),
                            Text(
                              'Additional privacy controls for sensitive communities',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Member Management Section
                      Row(
                        children: [
                          Icon(Icons.people, color: Colors.blue, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Member Management',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Join Questions
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.question_answer, color: Colors.grey.shade600, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Join Questions',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  if (joinQuestions.value.isNotEmpty)
                                    Text(
                                      '${joinQuestions.value.length} question${joinQuestions.value.length == 1 ? '' : 's'} added',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.green.shade600,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.add, size: 16),
                              onPressed: () {
                                print('🔍 Add join question pressed');
                                _showJoinQuestionDialog(context, joinQuestions);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Community Rules
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.rule, color: Colors.grey.shade600, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Community Rules',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  if (rules.value.isNotEmpty)
                                    Text(
                                      '${rules.value.length} rule${rules.value.length == 1 ? '' : 's'} added',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.orange.shade600,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.add, size: 16),
                              onPressed: () {
                                print('🔍 Add community rules pressed');
                                _showCommunityRulesDialog(context, rules);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              

            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoading.value ? null : () async {
              print('🔍 Create Community button pressed');
              print('🔍 Form data:');
              print('  - Name: ${nameController.text}');
              print('  - Description: ${descriptionController.text}');
              print('  - Welcome Message: ${welcomeMessageController.text}');
              print('  - Visibility: ${visibility.value}');
              print('  - Is Business: ${isBusiness.value}');
              print('  - Approval Required: ${approvalRequired.value}');
              print('  - Tags: ${tags.value}');
              print('  - Selected Color: ${selectedColor.value}');
              print('  - Cover Image: ${coverImage.value}');
              print('  - Badge Icon: ${badgeIcon.value}');
              print('  - Join Questions: ${joinQuestions.value}');
              print('  - Community Rules: ${rules.value}');
              print('  - Enhanced Privacy: ${enhancedPrivacy.value}');
              print('  - Selected Theme: ${selectedTheme.value}');
              print('  - Custom Theme: ${customTheme.value}');
              print('  - Is Form Valid: $isFormValid');
              
              if (isFormValid) {
                print('🔍 Form is valid, creating community...');
                
                try {
                  // Set loading state
                  isLoading.value = true;
                  
                  // Upload images if selected
                  String? uploadedCoverImage;
                  String? uploadedBadgeIcon;
                  
                  if (selectedCoverFile.value != null) {
                    print('🔍 Uploading cover image...');
                    uploadedCoverImage = await ref.read(storageServiceProvider).uploadImage(
                      selectedCoverFile.value!,
                      'community_covers',
                    );
                    print('🔍 Cover image uploaded: $uploadedCoverImage');
                  }
                  
                  if (selectedBadgeFile.value != null) {
                    print('🔍 Uploading badge icon...');
                    uploadedBadgeIcon = await ref.read(storageServiceProvider).uploadImage(
                      selectedBadgeFile.value!,
                      'community_badges',
                    );
                    print('🔍 Badge icon uploaded: $uploadedBadgeIcon');
                  }
                  
                  // Prepare theme data
                  final themeData = {
                    'primaryColor': selectedColor.value,
                    'coverImage': uploadedCoverImage ?? coverImage.value,
                    'badgeIcon': uploadedBadgeIcon ?? badgeIcon.value,
                    'theme': selectedTheme.value,
                    'customTheme': customTheme.value,
                  };
                  
                  // Create community using the service
                  final community = await ref.read(communityServiceProvider).createCommunity(
                    name: nameController.text.trim(),
                    description: descriptionController.text.trim(),
                    welcomeMessage: welcomeMessageController.text.trim().isEmpty 
                        ? null 
                        : welcomeMessageController.text.trim(),
                    visibility: visibility.value,
                    approvalRequired: approvalRequired.value,
                    isBusiness: isBusiness.value,
                    tags: tags.value.isNotEmpty ? tags.value : null,
                    theme: themeData,
                    joinQuestions: joinQuestions.value.isNotEmpty ? joinQuestions.value : null,
                    communityRules: rules.value.isNotEmpty ? rules.value : null,
                    enhancedPrivacy: enhancedPrivacy.value,
                  );
                  
                  if (community != null) {
                    print('🔍 Community created successfully: ${community.id}');
                    
                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Community "${community.name}" created successfully!'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 3),
                      ),
                    );
                    
                    // Navigate back to previous screen
                    Navigator.of(context).pop();
                  } else {
                    throw Exception('Failed to create community');
                  }
                } catch (e) {
                  print('🔍 Error creating community: $e');
                  
                  // Show error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to create community: ${e.toString()}'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 5),
                    ),
                  );
                } finally {
                  // Reset loading state
                  isLoading.value = false;
                }
              } else {
                print('🔍 Form is invalid, cannot create community');
                
                // Show validation error
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please complete all required fields'),
                    backgroundColor: Colors.orange,
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isFormValid ? Colors.blue : Colors.grey,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: isLoading.value
                ? CircularProgressIndicator(color: Colors.white)
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_business),
                      const SizedBox(width: 8),
                      Text(
                        isFormValid ? 'Create Community' : 'Complete Required Fields',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  void _showJoinQuestionDialog(BuildContext context, ValueNotifier<List<String>> joinQuestions) {
    final TextEditingController questionController = TextEditingController();
    final List<String> tempQuestions = [...joinQuestions.value];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.question_answer, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Text('Join Questions'),
                ],
              ),
              content: Container(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Add questions that new members must answer when joining your community.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 16),
                    
                    // Input row with Add button
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: questionController,
                            decoration: const InputDecoration(
                              hintText: 'Enter a question for new members',
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: (value) {
                              if (value.isNotEmpty) {
                                setState(() {
                                  tempQuestions.add(value);
                                });
                                questionController.clear();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            if (questionController.text.isNotEmpty) {
                              setState(() {
                                tempQuestions.add(questionController.text);
                              });
                              questionController.clear();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    if (tempQuestions.isNotEmpty) ...[
                      Text(
                        'Current Questions:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 120,
                        child: ListView.builder(
                          itemCount: tempQuestions.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              dense: true,
                              leading: Icon(Icons.question_mark, size: 16, color: Colors.blue),
                              title: Text('Q${index + 1}: ${tempQuestions[index]}'),
                              trailing: IconButton(
                                icon: Icon(Icons.delete, size: 16, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    tempQuestions.removeAt(index);
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    joinQuestions.value = tempQuestions;
                    print('🔍 Updated join questions: ${joinQuestions.value}');
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCommunityRulesDialog(BuildContext context, ValueNotifier<List<String>> rules) {
    final TextEditingController ruleController = TextEditingController();
    final List<String> tempRules = [...rules.value];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.rule, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Text('Community Rules'),
                ],
              ),
              content: Container(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Add rules that members must follow in your community.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 16),
                    
                    // Input row with Add button
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: ruleController,
                            decoration: const InputDecoration(
                              hintText: 'Enter a community rule',
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: (value) {
                              if (value.isNotEmpty) {
                                setState(() {
                                  tempRules.add(value);
                                });
                                ruleController.clear();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            if (ruleController.text.isNotEmpty) {
                              setState(() {
                                tempRules.add(ruleController.text);
                              });
                              ruleController.clear();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    if (tempRules.isNotEmpty) ...[
                      Text(
                        'Current Rules:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 120,
                        child: ListView.builder(
                          itemCount: tempRules.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              dense: true,
                              leading: Icon(Icons.rule, size: 16, color: Colors.orange),
                              title: Text('Rule ${index + 1}: ${tempRules[index]}'),
                              trailing: IconButton(
                                icon: Icon(Icons.delete, size: 16, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    tempRules.removeAt(index);
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    rules.value = tempRules;
                    print('🔍 Updated community rules: ${rules.value}');
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
} 