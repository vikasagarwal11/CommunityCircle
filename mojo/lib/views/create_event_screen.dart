import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../core/constants.dart';
import '../core/logger.dart';
import '../core/navigation_service.dart';
import '../core/theme.dart';
import '../models/event_model.dart';
import '../models/user_model.dart';
import '../providers/auth_providers.dart';
import '../providers/database_providers.dart';
import '../services/storage_service.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';

class CreateEventScreen extends ConsumerStatefulWidget {
  final String communityId;

  const CreateEventScreen({
    super.key,
    required this.communityId,
  });

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen>
    with TickerProviderStateMixin {
  final Logger _logger = Logger('CreateEventScreen');
  
  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _maxSpotsController = TextEditingController();
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _progressController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _progressAnimation;
  
  // Form state
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 18, minute: 0);
  DateTime _selectedEndDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedEndTime = const TimeOfDay(hour: 20, minute: 0);
  String _visibility = 'public';
  bool _approvalRequired = false;
  bool _isBusinessEvent = false;
  bool _hasSpotsLimit = false;
  File? _posterImage;
  bool _isLoading = false;
  
  // Validation state
  bool _isTitleValid = false;
  bool _isDescriptionValid = false;
  bool _isLocationValid = false;
  bool _isDateValid = false;
  bool _isEndDateValid = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupValidation();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: _calculateProgress(),
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));

    _fadeController.forward();
    _slideController.forward();
    _progressController.forward();
  }

  void _setupValidation() {
    _titleController.addListener(() {
      setState(() {
        _isTitleValid = _titleController.text.trim().length >= 3;
      });
      _updateProgress();
    });
    
    _descriptionController.addListener(() {
      setState(() {
        _isDescriptionValid = _descriptionController.text.trim().length >= 10;
      });
      _updateProgress();
    });
    
    _locationController.addListener(() {
      setState(() {
        _isLocationValid = _locationController.text.trim().length >= 3;
      });
      _updateProgress();
    });
    
    _maxSpotsController.addListener(() {
      _updateProgress();
    });
  }

  void _updateProgress() {
    _progressController.animateTo(_calculateProgress());
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _progressController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _maxSpotsController.dispose();
    super.dispose();
  }

  bool get _isFormValid => 
    _isTitleValid && 
    _isDescriptionValid && 
    _isLocationValid && 
    _isDateValid &&
    _isEndDateValid;

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );
        _isDateValid = _selectedDate.isAfter(DateTime.now());
      });
      _updateProgress();
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedEndDate,
      firstDate: _selectedDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _selectedEndDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedEndTime.hour,
          _selectedEndTime.minute,
        );
        _isEndDateValid = _selectedEndDate.isAfter(_selectedDate);
      });
      _updateProgress();
    }
  }

  Future<void> _selectEndTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedEndTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _selectedEndTime = picked;
        _selectedEndDate = DateTime(
          _selectedEndDate.year,
          _selectedEndDate.month,
          _selectedEndDate.day,
          picked.hour,
          picked.minute,
        );
        _isEndDateValid = _selectedEndDate.isAfter(_selectedDate);
      });
      _updateProgress();
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _posterImage = File(image.path);
        });
        _logger.i('🎬 Event poster image selected');
      }
    } catch (e) {
      _logger.e('❌ Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting image: $e')),
      );
    }
  }

  Future<void> _createEvent() async {
    if (!_isFormValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = ref.read(currentUserProvider).value;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      _logger.i('🎬 Creating event for community: ${widget.communityId}');

      // Upload poster image if selected
      String? posterUrl;
      if (_posterImage != null) {
        _logger.i('🎬 Uploading event poster image');
        final storageService = StorageService();
        posterUrl = await storageService.uploadEventPoster(
          communityId: widget.communityId,
          imageFile: _posterImage!,
        );
        _logger.i('🎬 Event poster uploaded: $posterUrl');
      }

      // Create event model
      final event = EventModel(
        id: '',
        communityId: widget.communityId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        date: _selectedDate,
        endDate: _selectedEndDate,
        location: _locationController.text.trim(),
        creatorUid: user.id,
        posterUrl: posterUrl,
        visibility: _visibility,
        approvalRequired: _approvalRequired,
        maxSpots: _hasSpotsLimit && _maxSpotsController.text.isNotEmpty 
            ? int.tryParse(_maxSpotsController.text.trim())
            : null,
        createdAt: DateTime.now(),
        rsvps: {},
        checkIns: {},
        metadata: {
          'isBusinessEvent': _isBusinessEvent,
          'createdBy': user.displayName ?? user.phoneNumber,
        },
      );

      // Create event in database
      final eventNotifier = ref.read(eventNotifierProvider(widget.communityId).notifier);
      await eventNotifier.createEvent(event);

      _logger.i('🎬 Event created successfully: ${event.title}');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Event "${event.title}" created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        NavigationService.goBack();
      }
    } catch (e) {
      _logger.e('❌ Error creating event: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating event: $e'),
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

  double _calculateProgress() {
    int completedFields = 0;
    int totalFields = 5; // title, description, location, date, settings
    
    if (_isTitleValid) completedFields++;
    if (_isDescriptionValid) completedFields++;
    if (_isLocationValid) completedFields++;
    if (_isDateValid && _isEndDateValid) completedFields++;
    if (_hasSpotsLimit ? _maxSpotsController.text.isNotEmpty : true) completedFields++;
    
    return completedFields / totalFields;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildModernHeader(),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildContent(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => NavigationService.goBack(),
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const Expanded(
            child: Text(
              'Create Event',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                child: Center(
                  child: Text(
                    '${(_progressAnimation.value * 100).round()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCompactPosterSection(),
          const SizedBox(height: 16),
          _buildCompactEventDetails(),
          const SizedBox(height: 16),
          _buildCompactDateTimeSection(),
          const SizedBox(height: 16),
          _buildCompactSettings(),
          const SizedBox(height: 24),
          _buildModernCreateButton(),
        ],
      ),
    );
  }

  Widget _buildCompactPosterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.image,
                size: 16,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Event Poster',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
            const Spacer(),
            if (_posterImage != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check, color: Colors.white, size: 12),
                    SizedBox(width: 2),
                    Text(
                      'Added',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: double.infinity,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _posterImage != null
                    ? AppColors.primary
                    : AppColors.outlineVariant,
                width: 1.5,
              ),
            ),
            child: _posterImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10.5),
                    child: Stack(
                      children: [
                        Image.file(
                          _posterImage!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 20,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add Event Poster',
                        style: TextStyle(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactEventDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.event,
                size: 16,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Event Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        _buildCompactTextField(
          controller: _titleController,
          label: 'Event Title',
          hint: 'Enter event title',
          isValid: _isTitleValid,
          icon: Icons.title,
          required: true,
        ),
        
        const SizedBox(height: 12),
        
        _buildCompactTextField(
          controller: _descriptionController,
          label: 'Description',
          hint: 'Describe your event...',
          isValid: _isDescriptionValid,
          icon: Icons.description,
          maxLines: 3,
          required: true,
        ),
        
        const SizedBox(height: 12),
        
        _buildCompactTextField(
          controller: _locationController,
          label: 'Location',
          hint: 'Enter event location',
          isValid: _isLocationValid,
          icon: Icons.location_on,
          required: true,
        ),
      ],
    );
  }

  Widget _buildCompactTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isValid,
    required IconData icon,
    int maxLines = 1,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: isValid 
                  ? AppColors.primary
                  : AppColors.error,
            ),
            const SizedBox(width: 6),
            Text(
              '$label${required ? ' *' : ''}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isValid 
                    ? AppColors.onSurface
                    : AppColors.error,
              ),
            ),
            if (isValid) ...[
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 10,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isValid 
                  ? AppColors.primary
                  : AppColors.outlineVariant,
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(12),
              hintStyle: TextStyle(
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactDateTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.schedule,
                size: 16,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Date & Time',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Start Date & Time - Compact Row
        Row(
          children: [
            Expanded(
              child: _buildCompactDateTimeButton(
                icon: Icons.calendar_today,
                label: 'Start Date',
                value: '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                onTap: _selectDate,
                isValid: _isDateValid,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildCompactDateTimeButton(
                icon: Icons.access_time,
                label: 'Start Time',
                value: _selectedTime.format(context),
                onTap: _selectTime,
                isValid: _isDateValid,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // End Date & Time - Compact Row
        Row(
          children: [
            Expanded(
              child: _buildCompactDateTimeButton(
                icon: Icons.calendar_today,
                label: 'End Date',
                value: '${_selectedEndDate.day}/${_selectedEndDate.month}/${_selectedEndDate.year}',
                onTap: _selectEndDate,
                isValid: _isEndDateValid,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildCompactDateTimeButton(
                icon: Icons.access_time,
                label: 'End Time',
                value: _selectedEndTime.format(context),
                onTap: _selectEndTime,
                isValid: _isEndDateValid,
              ),
            ),
          ],
        ),
        
        if (!_isEndDateValid && _selectedEndDate.isBefore(_selectedDate))
          Container(
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.errorContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning,
                  color: AppColors.error,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'End time must be after start time',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCompactDateTimeButton({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
    required bool isValid,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isValid 
                ? AppColors.primary
                : AppColors.outlineVariant,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 12,
                  color: isValid 
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.settings,
                size: 16,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Event Settings',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Compact Settings List
        Column(
          children: [
            _buildCompactToggle(
              title: 'Event Visibility',
              subtitle: 'Who can see this event',
              value: _visibility == 'public',
              onChanged: (value) {
                setState(() {
                  _visibility = value ? 'public' : 'private';
                });
              },
              icon: Icons.visibility,
            ),
            
            const SizedBox(height: 8),
            
            _buildCompactToggle(
              title: 'Require Approval',
              subtitle: 'Manually approve RSVPs',
              value: _approvalRequired,
              onChanged: (value) {
                setState(() {
                  _approvalRequired = value;
                });
              },
              icon: Icons.approval,
            ),
            
            const SizedBox(height: 8),
            
            _buildCompactToggle(
              title: 'Limit Spots',
              subtitle: 'Set maximum number of attendees',
              value: _hasSpotsLimit,
              onChanged: (value) {
                setState(() {
                  _hasSpotsLimit = value;
                  if (!value) {
                    _maxSpotsController.clear();
                  }
                });
              },
              icon: Icons.people,
            ),
            
            if (_hasSpotsLimit) ...[
              const SizedBox(height: 8),
              _buildCompactTextField(
                controller: _maxSpotsController,
                label: 'Maximum Spots',
                hint: 'Enter maximum number of attendees',
                isValid: _maxSpotsController.text.isNotEmpty,
                icon: Icons.numbers,
                required: false,
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildCompactToggle({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.outlineVariant,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              icon,
              size: 14,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  Widget _buildModernCreateButton() {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: _isFormValid
              ? [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)]
              : [AppColors.outlineVariant, AppColors.outlineVariant],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isFormValid ? _createEvent : null,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Create Event',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
} 