import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../core/constants.dart';
import '../core/navigation_service.dart';
import '../providers/community_providers.dart';
import '../providers/auth_providers.dart';
import '../services/storage_service.dart';

class CreateCommunityWidgets {
  static Widget buildHeader(BuildContext context) {
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

  static Widget buildNameField(
    BuildContext context,
    TextEditingController controller,
    Map<String, String> validation,
    WidgetRef ref,
  ) {
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

  static Widget buildDescriptionField(
    BuildContext context,
    TextEditingController controller,
    Map<String, String> validation,
    WidgetRef ref,
  ) {
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

  static Widget buildTagsField(BuildContext context, ValueNotifier<List<String>> tags) {
    final tagController = useTextEditingController();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.smallPadding),
        Text(
          'Add tags to help people discover your community. Separate tags with commas.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: AppConstants.smallPadding),
        TextField(
          controller: tagController,
          decoration: InputDecoration(
            hintText: 'e.g., technology, mobile, development',
            prefixIcon: const Icon(Icons.tag),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              final newTags = value.split(',').map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList();
              tags.value = [...tags.value, ...newTags];
              tagController.clear();
            }
          },
        ),
        if (tags.value.isNotEmpty) ...[
          const SizedBox(height: AppConstants.smallPadding),
          Wrap(
            spacing: 8,
            children: tags.value.map((tag) => Chip(
              label: Text(tag),
              deleteIcon: const Icon(Icons.close, size: 16),
              onDeleted: () {
                tags.value = tags.value.where((t) => t != tag).toList();
              },
            )).toList(),
          ),
        ],
      ],
    );
  }

  static Widget buildWelcomeMessageField(BuildContext context, TextEditingController controller) {
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

  static Widget buildVisibilitySection(BuildContext context, ValueNotifier<String> visibility) {
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
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildVisibilityOption(
                  context,
                  'public',
                  'Public',
                  'Anyone can find and join your community',
                  Icons.public,
                  visibility,
                ),
                const SizedBox(height: 8),
                _buildVisibilityOption(
                  context,
                  'private',
                  'Private',
                  'Only invited members can join',
                  Icons.lock,
                  visibility,
                ),
                const SizedBox(height: 8),
                _buildVisibilityOption(
                  context,
                  'secret',
                  'Secret',
                  'Hidden from search, invite only',
                  Icons.visibility_off,
                  visibility,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Widget _buildVisibilityOption(
    BuildContext context,
    String value,
    String title,
    String subtitle,
    IconData icon,
    ValueNotifier<String> visibility,
  ) {
    final isSelected = visibility.value == value;
    return InkWell(
      onTap: () => visibility.value = value,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  static Widget buildCommunityTypeSection(BuildContext context, ValueNotifier<bool> isBusiness) {
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
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.business,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Business Community',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Enable business features and analytics',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isBusiness.value,
                  onChanged: (value) => isBusiness.value = value,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Widget buildApprovalSection(BuildContext context, ValueNotifier<bool> approvalRequired) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Approval Settings',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.smallPadding),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.approval,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Require Approval',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Manually approve new member requests',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: approvalRequired.value,
                  onChanged: (value) => approvalRequired.value = value,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Widget buildAdvancedOptionsToggle(BuildContext context, ValueNotifier<bool> showAdvancedOptions) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        initiallyExpanded: showAdvancedOptions.value,
        onExpansionChanged: (expanded) {
          showAdvancedOptions.value = expanded;
        },
        title: const Text('Advanced Options'),
        subtitle: const Text('Customize theme, images, and settings'),
        leading: const Icon(Icons.settings),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customize your community with advanced settings',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.palette,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Theme & Branding',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.photo_library,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Images & Media',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.security,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Privacy & Security',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.people,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Member Management',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildThemeSection(BuildContext context, ValueNotifier<String> selectedColor) {
    final colors = ['#2196F3', '#4CAF50', '#FF9800', '#9C27B0', '#F44336', '#00BCD4'];
    
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
          spacing: 8,
          children: colors.map((color) {
            final isSelected = selectedColor.value == color;
            return GestureDetector(
              onTap: () => selectedColor.value = color,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Color(int.parse(color.replaceAll('#', '0xFF'))),
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: Theme.of(context).colorScheme.primary, width: 3)
                      : null,
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 20,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  static Widget buildPrivacySettingsSection(
    BuildContext context,
    ValueNotifier<String> visibility,
    ValueNotifier<bool> approvalRequired,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Privacy Settings',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.smallPadding),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Visibility Settings
                Row(
                  children: [
                    Icon(
                      Icons.visibility,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Community Visibility',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Control who can find and join your community',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    DropdownButton<String>(
                      value: visibility.value,
                      onChanged: (value) {
                        if (value != null) visibility.value = value;
                      },
                      items: [
                        DropdownMenuItem(
                          value: 'public',
                          child: Row(
                            children: [
                              const Icon(Icons.public, size: 16),
                              const SizedBox(width: 8),
                              const Text('Public'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'private',
                          child: Row(
                            children: [
                              const Icon(Icons.lock, size: 16),
                              const SizedBox(width: 8),
                              const Text('Private'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'secret',
                          child: Row(
                            children: [
                              const Icon(Icons.visibility_off, size: 16),
                              const SizedBox(width: 8),
                              const Text('Secret'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Approval Settings
                Row(
                  children: [
                    Icon(
                      Icons.approval,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Approval Required',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Manually approve new member requests',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: approvalRequired.value,
                      onChanged: (value) => approvalRequired.value = value,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Widget buildMemberManagementSection(
    BuildContext context,
    ValueNotifier<List<String>> joinQuestions,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Member Management',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.smallPadding),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Join Questions
                Row(
                  children: [
                    Icon(
                      Icons.question_answer,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Join Questions',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Ask potential members questions before they join',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        // Show dialog to add join question
                        _showAddJoinQuestionDialog(context, joinQuestions);
                      },
                    ),
                  ],
                ),
                if (joinQuestions.value.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...joinQuestions.value.asMap().entries.map((entry) {
                    final index = entry.key;
                    final question = entry.value;
                    return Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              question,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 16),
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
                ],
                const SizedBox(height: 16),
                // Member Roles
                Row(
                  children: [
                    Icon(
                      Icons.admin_panel_settings,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Admin Roles',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Assign moderators and admins',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings),
                      onPressed: () {
                        // Show admin management dialog
                        _showAdminManagementDialog(context);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Widget buildCommunityFeaturesSection(BuildContext context) {
    final enabledFeatures = useState(<String, bool>{
      'chat': true,
      'events': true,
      'photos': true,
      'polls': true,
      'moments': true,
      'challenges': false,
      'live_streaming': false,
      'file_sharing': false,
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Community Features',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.smallPadding),
        Text(
          'Choose which features to enable in your community',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: AppConstants.smallPadding),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildFeatureToggle(
                  context,
                  'chat',
                  'Group Chat',
                  'Enable community-wide discussions',
                  Icons.chat,
                  enabledFeatures,
                ),
                const SizedBox(height: 8),
                _buildFeatureToggle(
                  context,
                  'events',
                  'Events',
                  'Create and manage community events',
                  Icons.event,
                  enabledFeatures,
                ),
                const SizedBox(height: 8),
                _buildFeatureToggle(
                  context,
                  'photos',
                  'Photo Sharing',
                  'Share photos and memories',
                  Icons.photo_library,
                  enabledFeatures,
                ),
                const SizedBox(height: 8),
                _buildFeatureToggle(
                  context,
                  'polls',
                  'Polls & Surveys',
                  'Get member feedback and opinions',
                  Icons.poll,
                  enabledFeatures,
                ),
                const SizedBox(height: 8),
                _buildFeatureToggle(
                  context,
                  'moments',
                  'Moments',
                  'Share quick updates and highlights',
                  Icons.flash_on,
                  enabledFeatures,
                ),
                const SizedBox(height: 8),
                _buildFeatureToggle(
                  context,
                  'challenges',
                  'Challenges',
                  'Create engaging community challenges',
                  Icons.emoji_events,
                  enabledFeatures,
                ),
                const SizedBox(height: 8),
                _buildFeatureToggle(
                  context,
                  'live_streaming',
                  'Live Streaming',
                  'Host live video sessions',
                  Icons.live_tv,
                  enabledFeatures,
                ),
                const SizedBox(height: 8),
                _buildFeatureToggle(
                  context,
                  'file_sharing',
                  'File Sharing',
                  'Share documents and files',
                  Icons.attach_file,
                  enabledFeatures,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Widget _buildFeatureToggle(
    BuildContext context,
    String key,
    String title,
    String subtitle,
    IconData icon,
    ValueNotifier<Map<String, bool>> enabledFeatures,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: enabledFeatures.value[key] ?? false,
          onChanged: (value) {
            final newFeatures = Map<String, bool>.from(enabledFeatures.value);
            newFeatures[key] = value;
            enabledFeatures.value = newFeatures;
          },
        ),
      ],
    );
  }

  static Widget buildBadgeIconSection(
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
          'Community Badge/Icon',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.smallPadding),
        Text(
          'Upload a custom icon or badge for your community.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: AppConstants.smallPadding),
        Container(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              if (selectedBadgeFile.value != null) ...[
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    image: DecorationImage(
                      image: FileImage(selectedBadgeFile.value!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.smallPadding),
                Text(
                  'Badge selected: ${selectedBadgeFile.value!.path.split('/').last}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: AppConstants.smallPadding),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final File? pickedFile = await _pickImage(context);
                    if (pickedFile != null) {
                      selectedBadgeFile.value = pickedFile;
                    }
                  },
                  icon: const Icon(Icons.upload),
                  label: const Text('Upload Badge/Icon'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget buildCoverImageSection(BuildContext context, ValueNotifier<String?> coverImage) {
    final selectedCoverFile = useState<File?>(null);
    
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
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: selectedCoverFile.value != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      Image.file(
                        selectedCoverFile.value!,
                        width: double.infinity,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Cover selected',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_photo_alternate,
                        size: 28,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Add Cover Image',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 32,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final File? pickedFile = await _pickImage(context);
                            if (pickedFile != null) {
                              selectedCoverFile.value = pickedFile;
                            }
                          },
                          icon: const Icon(Icons.upload, size: 14),
                          label: const Text('Upload', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  static Widget buildAdditionalFeatures(BuildContext context) {
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
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildFeatureItem(context, Icons.chat, 'Group Chat', 'Enable community-wide discussions'),
                const SizedBox(height: 8),
                _buildFeatureItem(context, Icons.event, 'Events', 'Create and manage community events'),
                const SizedBox(height: 8),
                _buildFeatureItem(context, Icons.photo_library, 'Photo Sharing', 'Share photos and memories'),
                const SizedBox(height: 8),
                _buildFeatureItem(context, Icons.poll, 'Polls & Surveys', 'Get member feedback and opinions'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Widget _buildFeatureItem(BuildContext context, IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: true,
          onChanged: (value) {
            // TODO: Implement feature toggle
          },
        ),
      ],
    );
  }

  static Widget buildCreateButton(
    BuildContext context,
    TextEditingController nameController,
    TextEditingController descriptionController,
    TextEditingController welcomeMessageController,
    ValueNotifier<String> visibility,
    ValueNotifier<bool> isBusiness,
    ValueNotifier<bool> approvalRequired,
    ValueNotifier<String> selectedColor,
    ValueNotifier<String?> coverImage,
    ValueNotifier<String?> badgeIcon,
    ValueNotifier<bool> isLoading,
    ValueNotifier<File?> selectedBadgeFile,
    ValueNotifier<File?> selectedCoverFile,
    ValueNotifier<List<String>> joinQuestions,
    ValueNotifier<List<String>> rules,
    ValueNotifier<List<String>> tags,
    Map<String, String> formValidation,
    bool isFormValid,
    StorageService storageService,
    WidgetRef ref,
    Map<String, dynamic>? eventTemplate,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        children: [
          // Show event template info if provided
          if (eventTemplate != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.event_rounded,
                    color: Theme.of(context).colorScheme.secondary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Event Will Be Created',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${eventTemplate['templateType']} - ${eventTemplate['title']}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.7),
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
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isFormValid && !isLoading.value ? () async {
                await _handleCreateCommunity(
                  context,
                  nameController,
                  descriptionController,
                  welcomeMessageController,
                  visibility,
                  isBusiness,
                  approvalRequired,
                  selectedColor,
                  coverImage,
                  badgeIcon,
                  isLoading,
                  selectedBadgeFile,
                  selectedCoverFile,
                  joinQuestions,
                  rules,
                  tags,
                  formValidation,
                  storageService,
                  ref,
                  eventTemplate,
                );
              } : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
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
                  : Text(
                      eventTemplate != null ? 'Create Community & Event' : 'Create Community',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _handleCreateCommunity(
    BuildContext context,
    TextEditingController nameController,
    TextEditingController descriptionController,
    TextEditingController welcomeMessageController,
    ValueNotifier<String> visibility,
    ValueNotifier<bool> isBusiness,
    ValueNotifier<bool> approvalRequired,
    ValueNotifier<String> selectedColor,
    ValueNotifier<String?> coverImage,
    ValueNotifier<String?> badgeIcon,
    ValueNotifier<bool> isLoading,
    ValueNotifier<File?> selectedBadgeFile,
    ValueNotifier<File?> selectedCoverFile,
    ValueNotifier<List<String>> joinQuestions,
    ValueNotifier<List<String>> rules,
    ValueNotifier<List<String>> tags,
    Map<String, String> formValidation,
    StorageService storageService,
    WidgetRef ref,
    Map<String, dynamic>? eventTemplate,
  ) async {
    isLoading.value = true;

    try {
      final communityService = ref.read(communityServiceProvider);
      final currentUser = ref.read(currentUserProvider).value;

      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Create community
      final newCommunity = await communityService.createCommunity(
        name: nameController.text.trim(),
        description: descriptionController.text.trim(),
        welcomeMessage: welcomeMessageController.text.trim(),
        visibility: visibility.value,
        isBusiness: isBusiness.value,
        approvalRequired: approvalRequired.value,
        coverImage: coverImage.value,
        badgeUrl: badgeIcon.value,
        joinQuestions: joinQuestions.value,
        rules: rules.value,
        tags: tags.value,
        theme: {'color': selectedColor.value, 'banner_url': ''},
      );

      if (newCommunity != null) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              eventTemplate != null 
                  ? 'Community created! Creating event...' 
                  : 'Community created successfully!',
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );

        // If event template is provided, create event after community creation
        if (eventTemplate != null) {
          // Navigate to create event with the new community and template
          NavigationService.navigateToCreateEvent(
            communityId: newCommunity.id,
            templateData: eventTemplate,
          );
        } else {
          // Navigate to community details
          NavigationService.navigateToCommunityDetails(newCommunity.id);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating community: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      isLoading.value = false;
    }
  }

  static void _showAddJoinQuestionDialog(BuildContext context, ValueNotifier<List<String>> joinQuestions) {
    final TextEditingController questionController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Join Question'),
          content: TextField(
            controller: questionController,
            decoration: const InputDecoration(
              hintText: 'Enter a question for potential members...',
              labelText: 'Join Question',
            ),
            maxLines: 3,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                final newQuestion = questionController.text.trim();
                if (newQuestion.isNotEmpty) {
                  joinQuestions.value = [...joinQuestions.value, newQuestion];
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  static void _showAdminManagementDialog(BuildContext context) {
    final adminRoles = useState(<String>['Owner', 'Admin', 'Moderator']);
    final selectedRole = useState('Admin');
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Admin Management'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Configure admin roles and permissions for your community',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Available Roles:',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                ...adminRoles.value.map((role) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        role == 'Owner' ? Icons.person : 
                        role == 'Admin' ? Icons.admin_panel_settings : 
                        Icons.security,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          role,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      if (role == 'Owner')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'You',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                )),
                const SizedBox(height: 16),
                Text(
                  'Permissions:',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                _buildPermissionItem(context, 'Manage Members', true),
                _buildPermissionItem(context, 'Create Events', true),
                _buildPermissionItem(context, 'Moderate Content', true),
                _buildPermissionItem(context, 'Delete Messages', false),
                _buildPermissionItem(context, 'Ban Users', false),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Add Admin'),
              onPressed: () {
                // TODO: Implement add admin functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Add admin functionality coming soon'),
                    duration: Duration(seconds: 2),
                  ),
                );
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  static Widget _buildPermissionItem(BuildContext context, String permission, bool enabled) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            enabled ? Icons.check_circle : Icons.cancel,
            color: enabled ? Colors.green : Colors.grey,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            permission,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: enabled ? null : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  static Future<File?> _pickImage(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    
    return showDialog<File?>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final XFile? pickedFile = await picker.pickImage(source: ImageSource.camera);
                  if (pickedFile != null) {
                    Navigator.of(context).pop(File(pickedFile.path));
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    Navigator.of(context).pop(File(pickedFile.path));
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }
} 