import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../core/constants.dart';
import '../core/logger.dart';
import '../core/navigation_service.dart';
import '../core/theme.dart';
import '../models/event_model.dart';
import '../models/user_model.dart';
import '../providers/auth_providers.dart';
import '../providers/database_providers.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import '../services/event_service.dart';

class EventDetailsScreen extends ConsumerStatefulWidget {
  final String eventId;
  final String? communityId;

  const EventDetailsScreen({
    super.key,
    required this.eventId,
    this.communityId,
  });

  @override
  ConsumerState<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends ConsumerState<EventDetailsScreen> {
  final Logger _logger = Logger('EventDetailsScreen');
  
  // RSVP state
  String? _userRsvpStatus;
  bool _isRsvpLoading = false;
  bool _isCheckInLoading = false;
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    _loadUserRsvpStatus();
  }

  void _loadUserRsvpStatus() {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser != null) {
      final eventAsync = ref.read(eventProvider(widget.eventId));
      eventAsync.when(
        data: (event) {
          if (event != null) {
            setState(() {
              _userRsvpStatus = event.rsvpStatus(currentUser.id);
            });
          }
        },
        loading: () => null,
        error: (_, __) => null,
      );
    }
  }

  Future<void> _rsvpToEvent(String status) async {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to RSVP')),
      );
      return;
    }

    setState(() {
      _isRsvpLoading = true;
    });

    try {
      _logger.i('🎬 User ${currentUser.id} RSVPing to event ${widget.eventId} with status: $status');
      
      // Use EventService for enhanced RSVP logic
      final eventService = EventService();
      await eventService.rsvpToEvent(widget.eventId, status, currentUser);
      
      // Update local state
      setState(() {
        _userRsvpStatus = status == 'remove' ? null : status;
      });
      
      _logger.i('🎬 RSVP updated successfully');
      
      if (mounted) {
        String message;
        if (status == 'remove') {
          message = 'RSVP removed';
        } else if (status == EventModel.rsvpWaitlist) {
          message = 'Added to waitlist';
        } else {
          message = 'RSVP updated to ${_getRsvpStatusText(status)}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _logger.e('❌ Error updating RSVP: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating RSVP: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRsvpLoading = false;
        });
      }
    }
  }

  Future<void> _checkInToEvent() async {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to check in')),
      );
      return;
    }

    setState(() {
      _isCheckInLoading = true;
    });

    try {
      _logger.i('🎬 User ${currentUser.id} checking in to event ${widget.eventId}');
      
      final eventAsync = ref.read(eventProvider(widget.eventId));
      await eventAsync.when(
        data: (event) async {
          if (event == null) throw Exception('Event not found');
          
          // Update check-ins
          final updatedCheckIns = Map<String, DateTime>.from(event.checkIns);
          updatedCheckIns[currentUser.id] = DateTime.now();
          
          final updatedEvent = event.copyWith(checkIns: updatedCheckIns);
          
          // Update in database
          final databaseService = ref.read(databaseServiceProvider);
          await databaseService.updateEvent(updatedEvent);
          
          _logger.i('🎬 Check-in successful');
          
          // Show confetti animation
          setState(() {
            _showConfetti = true;
          });
          
          // Hide confetti after 3 seconds
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              setState(() {
                _showConfetti = false;
              });
            }
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🎉 Checked in successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        loading: () => throw Exception('Event loading'),
        error: (error, _) => throw error,
      );
    } catch (e) {
      _logger.e('❌ Error checking in: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking in: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckInLoading = false;
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference == 0) {
      return 'Today at ${_formatTime(date)}';
    } else if (difference == 1) {
      return 'Tomorrow at ${_formatTime(date)}';
    } else if (difference > 1) {
      return '${date.day}/${date.month}/${date.year} at ${_formatTime(date)}';
    } else {
      return '${date.day}/${date.month}/${date.year} at ${_formatTime(date)}';
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    final eventAsync = ref.watch(eventProvider(widget.eventId));
    
    return eventAsync.when(
      data: (event) {
        if (event == null) {
          return _buildErrorWidget('Event not found');
        }
        return _buildEventDetails(event);
      },
      loading: () => const LoadingWidget(),
      error: (error, stack) => _buildErrorWidget('Error loading event: $error'),
    );
  }

  Widget _buildEventDetails(EventModel event) {
    return CustomScrollView(
      slivers: [
        // App Bar with Event Poster
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          backgroundColor: Theme.of(context).colorScheme.surface,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => NavigationService.goBack(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.chat),
              onPressed: () => NavigationService.navigateToEventCommunication(
                widget.eventId,
                communityId: widget.communityId,
              ),
              tooltip: 'Event Communication',
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: _buildEventPoster(event),
            title: Text(
              event.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    offset: Offset(0, 1),
                    blurRadius: 3,
                    color: Colors.black54,
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Event Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event Info
                _buildEventInfo(event),
                
                const SizedBox(height: 24),
                
                // RSVP Section
                _buildRsvpSection(event),
                
                const SizedBox(height: 24),
                
                // Check-in Section
                _buildCheckInSection(event),
                
                const SizedBox(height: 24),
                
                // Attendees Section
                _buildAttendeesSection(event),
                
                const SizedBox(height: 24),
                
                // Event Description
                _buildDescriptionSection(event),
                
                const SizedBox(height: 24),
                
                // Communication Section
                _buildCommunicationSection(event),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEventPoster(EventModel event) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.7),
            Colors.black.withValues(alpha: 0.3),
            Colors.transparent,
          ],
        ),
      ),
      child: event.posterUrl != null
          ? Image.network(
              event.posterUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildDefaultPoster();
              },
            )
          : _buildDefaultPoster(),
    );
  }

  Widget _buildDefaultPoster() {
    return Container(
                      color: AppColors.primary.withValues(alpha: 0.1),
      child: Center(
        child: Icon(
          Icons.event,
          size: 80,
                          color: AppColors.primary.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildEventInfo(EventModel event) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _formatDate(event.date),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  event.location,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.people,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '${event.rsvpCount} attending',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRsvpSection(EventModel event) {
    final currentUser = ref.watch(currentUserProvider).value;
    if (currentUser == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'RSVP',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        // RSVP Status Display
        if (_userRsvpStatus != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getRsvpStatusColor(_userRsvpStatus!).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _getRsvpStatusColor(_userRsvpStatus!).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getRsvpStatusIcon(_userRsvpStatus!),
                  color: _getRsvpStatusColor(_userRsvpStatus!),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getRsvpStatusText(_userRsvpStatus!),
                    style: TextStyle(
                      color: _getRsvpStatusColor(_userRsvpStatus!),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (_userRsvpStatus == EventModel.rsvpWaitlist) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${event.waitlistCount} on waitlist',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        
        // RSVP Buttons
        Row(
          children: [
            Expanded(
              child: _buildRsvpButton(
                'Going',
                Icons.check_circle,
                Colors.green,
                _userRsvpStatus == EventModel.rsvpGoing,
                () => _rsvpToEvent(EventModel.rsvpGoing),
                event.isFull && _userRsvpStatus != EventModel.rsvpGoing,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildRsvpButton(
                'Interested',
                Icons.help_outline,
                Colors.orange,
                _userRsvpStatus == EventModel.rsvpInterested,
                () => _rsvpToEvent(EventModel.rsvpInterested),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildRsvpButton(
                'Not Going',
                Icons.cancel,
                Colors.red,
                _userRsvpStatus == EventModel.rsvpNotGoing,
                () => _rsvpToEvent(EventModel.rsvpNotGoing),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildRsvpButton(
                'Waitlist',
                Icons.schedule,
                Colors.purple,
                _userRsvpStatus == EventModel.rsvpWaitlist,
                () => _rsvpToEvent(EventModel.rsvpWaitlist),
                event.hasAvailableSpots,
              ),
            ),
          ],
        ),
        
        // Remove RSVP Button
        if (_userRsvpStatus != null) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _isRsvpLoading ? null : () => _rsvpToEvent('remove'),
              child: const Text('Remove RSVP'),
            ),
          ),
        ],
        
        // Event Capacity Info
        if (event.hasSpotsLimit) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.people,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Event Capacity',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildCapacityItem(
                        'Going',
                        event.goingCount,
                        event.maxSpots ?? 0,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildCapacityItem(
                        'Waitlist',
                        event.waitlistCount,
                        null,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
                if (event.isFull) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Event is full',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRsvpButton(
    String text,
    IconData icon,
    Color color,
    bool isSelected,
    VoidCallback onPressed, [
    bool disabled = false,
  ]) {
    return ElevatedButton(
      onPressed: (_isRsvpLoading || disabled) ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? color : color.withValues(alpha: 0.1),
        foregroundColor: isSelected ? Colors.white : color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: isSelected ? 2 : 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(text),
        ],
      ),
    );
  }

  Widget _buildCapacityItem(String label, int count, int? max, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (max != null) ...[
              Text(
                '/$max',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Color _getRsvpStatusColor(String status) {
    switch (status) {
      case EventModel.rsvpGoing:
        return Colors.green;
      case EventModel.rsvpInterested:
        return Colors.orange;
      case EventModel.rsvpNotGoing:
        return Colors.red;
      case EventModel.rsvpWaitlist:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getRsvpStatusIcon(String status) {
    switch (status) {
      case EventModel.rsvpGoing:
        return Icons.check_circle;
      case EventModel.rsvpInterested:
        return Icons.help_outline;
      case EventModel.rsvpNotGoing:
        return Icons.cancel;
      case EventModel.rsvpWaitlist:
        return Icons.schedule;
      default:
        return Icons.help;
    }
  }

  String _getRsvpStatusText(String status) {
    switch (status) {
      case EventModel.rsvpGoing:
        return 'You are going to this event';
      case EventModel.rsvpInterested:
        return 'You are interested in this event';
      case EventModel.rsvpNotGoing:
        return 'You are not going to this event';
      case EventModel.rsvpWaitlist:
        return 'You are on the waitlist';
      default:
        return 'Unknown status';
    }
  }

  Widget _buildCheckInSection(EventModel event) {
    final currentUser = ref.watch(currentUserProvider).value;
    if (currentUser == null) return const SizedBox.shrink();

    final isCheckedIn = event.isCheckedIn(currentUser.id);
    final hasRsvped = event.isRsvped(currentUser.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Check In',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (isCheckedIn)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Checked in!',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )
        else if (hasRsvped)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isCheckInLoading ? null : _checkInToEvent,
              icon: _isCheckInLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.qr_code_scanner),
              label: Text(_isCheckInLoading ? 'Checking in...' : 'Check In'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey),
                const SizedBox(width: 8),
                const Text(
                  'RSVP first to check in',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAttendeesSection(EventModel event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Attendees',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildAttendeeRow('Yes', event.rsvps.values.where((s) => s == 'yes').length, Colors.green),
              const SizedBox(height: 8),
              _buildAttendeeRow('Maybe', event.rsvps.values.where((s) => s == 'maybe').length, Colors.orange),
              const SizedBox(height: 8),
              _buildAttendeeRow('No', event.rsvps.values.where((s) => s == 'no').length, Colors.red),
              const SizedBox(height: 8),
              _buildAttendeeRow('Checked In', event.checkIns.length, AppColors.primary),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttendeeRow(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(label),
        const Spacer(),
        Text(
          count.toString(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection(EventModel event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            event.description,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCommunicationSection(EventModel event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Communication',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildCommunicationOption(
                icon: Icons.chat,
                title: 'Event Chat',
                subtitle: 'Chat with other attendees',
                onTap: () => NavigationService.navigateToEventCommunication(
                  widget.eventId,
                  communityId: widget.communityId,
                ),
              ),
              const SizedBox(height: 12),
              _buildCommunicationOption(
                icon: Icons.question_answer,
                title: 'Q&A',
                subtitle: 'Ask questions about the event',
                onTap: () => NavigationService.navigateToEventCommunication(
                  widget.eventId,
                  communityId: widget.communityId,
                ),
              ),
              const SizedBox(height: 12),
              _buildCommunicationOption(
                icon: Icons.qr_code,
                title: 'Check-in QR',
                subtitle: 'View QR code for check-in',
                onTap: () => NavigationService.navigateToEventCommunication(
                  widget.eventId,
                  communityId: widget.communityId,
                ),
              ),
              const SizedBox(height: 12),
              _buildCommunicationOption(
                icon: Icons.share,
                title: 'Share Event',
                subtitle: 'Share this event with others',
                onTap: () => NavigationService.navigateToEventCommunication(
                  widget.eventId,
                  communityId: widget.communityId,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommunicationOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
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
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => NavigationService.goBack(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => NavigationService.goBack(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
} 