import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/community_model.dart';
import '../services/community_service.dart';
import '../core/constants.dart';
import '../core/logger.dart';
import '../core/navigation_service.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';

class EditCommunityScreen extends ConsumerStatefulWidget {
  final CommunityModel community;

  const EditCommunityScreen({
    super.key,
    required this.community,
  });

  @override
  ConsumerState<EditCommunityScreen> createState() => _EditCommunityScreenState();
}

class _EditCommunityScreenState extends ConsumerState<EditCommunityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _rulesController = TextEditingController();
  final _welcomeMessageController = TextEditingController();
  
  String _visibility = 'public';
  bool _approvalRequired = false;
  bool _isBusiness = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    _nameController.text = widget.community.name;
    _descriptionController.text = widget.community.description;
    _rulesController.text = widget.community.rules.join('\n');
    _welcomeMessageController.text = widget.community.welcomeMessage;
    _visibility = widget.community.visibility;
    _approvalRequired = widget.community.approvalRequired;
    _isBusiness = widget.community.isBusiness;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _rulesController.dispose();
    _welcomeMessageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Community'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveChanges,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Community Name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Community Name',
                        hintText: 'Enter community name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Community name is required';
                        }
                        if (value.trim().length < 3) {
                          return 'Community name must be at least 3 characters';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Describe your community',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Description is required';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Visibility
                    DropdownButtonFormField<String>(
                      value: _visibility,
                      decoration: const InputDecoration(
                        labelText: 'Visibility',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'public',
                          child: Text('Public'),
                        ),
                        DropdownMenuItem(
                          value: 'private',
                          child: Text('Private'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _visibility = value!;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Settings
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Settings',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            // Approval Required
                            SwitchListTile(
                              title: const Text('Require Approval'),
                              subtitle: const Text('New members must be approved'),
                              value: _approvalRequired,
                              onChanged: (value) {
                                setState(() {
                                  _approvalRequired = value;
                                });
                              },
                            ),
                            
                            // Business Community
                            SwitchListTile(
                              title: const Text('Business Community'),
                              subtitle: const Text('This is a business/professional community'),
                              value: _isBusiness,
                              onChanged: (value) {
                                setState(() {
                                  _isBusiness = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Rules
                    TextFormField(
                      controller: _rulesController,
                      decoration: const InputDecoration(
                        labelText: 'Community Rules',
                        hintText: 'Enter community rules (one per line)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 5,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Welcome Message
                    TextFormField(
                      controller: _welcomeMessageController,
                      decoration: const InputDecoration(
                        labelText: 'Welcome Message',
                        hintText: 'Message shown to new members',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Parse rules from text
      final rules = _rulesController.text
          .split('\n')
          .where((rule) => rule.trim().isNotEmpty)
          .map((rule) => rule.trim())
          .toList();

      // Create updated community model
      final updatedCommunity = CommunityModel(
        id: widget.community.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        adminUid: widget.community.adminUid,
        members: widget.community.members,
        visibility: _visibility,
        approvalRequired: _approvalRequired,
        isBusiness: _isBusiness,
        createdAt: widget.community.createdAt,
        badgeUrl: widget.community.badgeUrl,
        bannedUsers: widget.community.bannedUsers,
        coverImage: widget.community.coverImage,
        joinQuestions: widget.community.joinQuestions,
        metadata: widget.community.metadata,
        pinnedItems: widget.community.pinnedItems,
        rules: rules,
        tags: widget.community.tags,
        theme: widget.community.theme,
        welcomeMessage: _welcomeMessageController.text.trim(),
      );

      // Update community in database
      await CommunityService().updateCommunity(
        communityId: widget.community.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        visibility: _visibility,
        approvalRequired: _approvalRequired,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Community updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      Logger('EditCommunityScreen').e('Error updating community: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating community: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
} 