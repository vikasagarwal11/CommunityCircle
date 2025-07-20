import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/event_model.dart';
import '../models/community_model.dart';
import '../services/event_service.dart';
import '../core/constants.dart';
import '../core/logger.dart';
import '../core/navigation_service.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import '../providers/auth_providers.dart';

class EditEventScreen extends ConsumerStatefulWidget {
  final EventModel event;
  final CommunityModel community;

  const EditEventScreen({
    super.key,
    required this.event,
    required this.community,
  });

  @override
  ConsumerState<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends ConsumerState<EditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _maxSpotsController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  DateTime _selectedEndDate = DateTime.now().add(const Duration(hours: 1));
  String _visibility = 'public';
  bool _approvalRequired = false;
  bool _hasSpotsLimit = false;
  bool _isBusinessEvent = false;
  String? _selectedCategory;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    _titleController.text = widget.event.title;
    _descriptionController.text = widget.event.description;
    _locationController.text = widget.event.location;
    _selectedDate = widget.event.date;
    _selectedEndDate = widget.event.endDate ?? widget.event.date.add(const Duration(hours: 1));
    _visibility = widget.event.visibility;
    _approvalRequired = widget.event.approvalRequired;
    _selectedCategory = widget.event.category;
    _hasSpotsLimit = widget.event.maxSpots != null;
    _maxSpotsController.text = widget.event.maxSpots?.toString() ?? '';
    _isBusinessEvent = widget.event.metadata?['isBusinessEvent'] ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _maxSpotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Event'),
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
                    _buildTitleField(),
                    const SizedBox(height: 16),
                    _buildDescriptionField(),
                    const SizedBox(height: 16),
                    _buildCategoryPicker(),
                    const SizedBox(height: 16),
                    _buildDatePicker(),
                    const SizedBox(height: 16),
                    _buildEndDatePicker(),
                    const SizedBox(height: 16),
                    _buildLocationField(),
                    const SizedBox(height: 16),
                    _buildVisibilityToggle(),
                    const SizedBox(height: 16),
                    _buildApprovalToggle(),
                    const SizedBox(height: 16),
                    _buildSpotsLimitToggle(),
                    const SizedBox(height: 16),
                    _buildBusinessEventToggle(),
                    const SizedBox(height: 32),
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      decoration: const InputDecoration(
        labelText: 'Event Title',
        hintText: 'Enter event title',
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter an event title';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: const InputDecoration(
        labelText: 'Description',
        hintText: 'Enter event description',
        border: OutlineInputBorder(),
      ),
      maxLines: 3,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter an event description';
        }
        return null;
      },
    );
  }

  Widget _buildCategoryPicker() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: const InputDecoration(
        labelText: 'Category',
        border: OutlineInputBorder(),
      ),
      items: EventModel.availableCategories.map((category) {
        return DropdownMenuItem(
          value: category,
          child: Row(
            children: [
              Icon(
                EventModel.getCategoryIcon(category),
                color: EventModel.getCategoryColor(category),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(EventModel.getCategoryDisplayName(category)),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCategory = value;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a category';
        }
        return null;
      },
    );
  }

  Widget _buildDatePicker() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Event Date'),
      subtitle: Text(
        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      trailing: const Icon(Icons.calendar_today),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) {
          setState(() {
            _selectedDate = DateTime(
              date.year,
              date.month,
              date.day,
              _selectedDate.hour,
              _selectedDate.minute,
            );
          });
        }
      },
    );
  }

  Widget _buildEndDatePicker() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('End Date'),
      subtitle: Text(
        '${_selectedEndDate.day}/${_selectedEndDate.month}/${_selectedEndDate.year}',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      trailing: const Icon(Icons.calendar_today),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedEndDate,
          firstDate: _selectedDate,
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) {
          setState(() {
            _selectedEndDate = DateTime(
              date.year,
              date.month,
              date.day,
              _selectedEndDate.hour,
              _selectedEndDate.minute,
            );
          });
        }
      },
    );
  }

  Widget _buildLocationField() {
    return TextFormField(
      controller: _locationController,
      decoration: const InputDecoration(
        labelText: 'Location',
        hintText: 'Enter event location',
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a location';
        }
        return null;
      },
    );
  }

  Widget _buildVisibilityToggle() {
    return SwitchListTile(
      title: const Text('Public Event'),
      subtitle: const Text('Anyone can see and join this event'),
      value: _visibility == 'public',
      onChanged: (value) {
        setState(() {
          _visibility = value ? 'public' : 'private';
        });
      },
    );
  }

  Widget _buildApprovalToggle() {
    return SwitchListTile(
      title: const Text('Require Approval'),
      subtitle: const Text('Admin must approve RSVPs'),
      value: _approvalRequired,
      onChanged: (value) {
        setState(() {
          _approvalRequired = value;
        });
      },
    );
  }

  Widget _buildSpotsLimitToggle() {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Limit Spots'),
          subtitle: const Text('Set maximum number of participants'),
          value: _hasSpotsLimit,
          onChanged: (value) {
            setState(() {
              _hasSpotsLimit = value;
              if (!value) {
                _maxSpotsController.clear();
              }
            });
          },
        ),
        if (_hasSpotsLimit) ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: _maxSpotsController,
            decoration: const InputDecoration(
              labelText: 'Maximum Spots',
              hintText: 'Enter maximum number of participants',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (_hasSpotsLimit && (value == null || value.isEmpty)) {
                return 'Please enter maximum spots';
              }
              if (_hasSpotsLimit && int.tryParse(value!) == null) {
                return 'Please enter a valid number';
              }
              return null;
            },
          ),
        ],
      ],
    );
  }

  Widget _buildBusinessEventToggle() {
    return SwitchListTile(
      title: const Text('Business Event'),
      subtitle: const Text('This is a business-related event'),
      value: _isBusinessEvent,
      onChanged: (value) {
        setState(() {
          _isBusinessEvent = value;
        });
      },
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveChanges,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Save Changes'),
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
      // Create updated event model
      final updatedEvent = widget.event.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        date: _selectedDate,
        endDate: _selectedEndDate,
        location: _locationController.text.trim(),
        visibility: _visibility,
        approvalRequired: _approvalRequired,
        maxSpots: _hasSpotsLimit && _maxSpotsController.text.isNotEmpty
            ? int.tryParse(_maxSpotsController.text.trim())
            : null,
        category: _selectedCategory,
        metadata: {
          ...widget.event.metadata ?? {},
          'isBusinessEvent': _isBusinessEvent,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );

      // Get current user
      final userAsync = ref.read(authNotifierProvider);
      final user = userAsync.value;
      if (user == null) {
        NavigationService.showSnackBar(
          message: 'Please log in to edit events.',
          backgroundColor: Colors.red,
        );
        return;
      }

      // Update event in database
      await EventService().updateEvent(updatedEvent, user);

      if (mounted) {
        NavigationService.showSnackBar(
          message: 'Event updated successfully!',
          backgroundColor: Colors.green,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      Logger('EditEventScreen').e('Error updating event: $e');
      if (mounted) {
        NavigationService.showSnackBar(
          message: 'Failed to update event. Please try again.',
          backgroundColor: Colors.red,
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