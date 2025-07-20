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
import '../services/event_service.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';

class RsvpManagementScreen extends ConsumerStatefulWidget {
  final String eventId;
  final String? communityId;

  const RsvpManagementScreen({
    super.key,
    required this.eventId,
    this.communityId,
  });

  @override
  ConsumerState<RsvpManagementScreen> createState() => _RsvpManagementScreenState();
}

class _RsvpManagementScreenState extends ConsumerState<RsvpManagementScreen>
    with TickerProviderStateMixin {
  final Logger _logger = Logger('RsvpManagementScreen');
  
  late TabController _tabController;
  Map<String, dynamic>? _attendanceStats;
  bool _isLoading = true;
  Set<String> _selectedUserIds = {};
  String _searchQuery = '';
  String _filterStatus = 'all';
  bool _showReminderSettings = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAttendanceStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAttendanceStats() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final eventService = EventService();
      final stats = await eventService.getEventAttendanceStats(widget.eventId);
      
      setState(() {
        _attendanceStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      _logger.e('Error loading attendance stats: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('RSVP Management'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => NavigationService.goBack(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAttendanceStats,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => _showReminderSettings = !_showReminderSettings,
            tooltip: 'Reminder Settings',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Attendees'),
            Tab(text: 'Waitlist'),
            Tab(text: 'Analytics'),
          ],
        ),
      ),
      body: _isLoading
          ? const LoadingWidget()
          : _attendanceStats == null
              ? const CustomErrorWidget(message: 'Failed to load attendance data')
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(),
                    _buildAttendeesTab(),
                    _buildWaitlistTab(),
                    _buildAnalyticsTab(),
                  ],
                ),
    );
  }

  Widget _buildOverviewTab() {
    final event = _attendanceStats!['event'] as EventModel;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(event.date),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Quick Stats
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Going',
                  _attendanceStats!['goingCount'].toString(),
                  Colors.green,
                  Icons.check_circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Waitlist',
                  _attendanceStats!['waitlistCount'].toString(),
                  Colors.orange,
                  Icons.schedule,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Checked In',
                  _attendanceStats!['checkInCount'].toString(),
                  AppColors.primary,
                  Icons.qr_code_scanner,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Capacity',
                  event.hasSpotsLimit 
                      ? '${_attendanceStats!['goingCount']}/${event.maxSpots}'
                      : 'Unlimited',
                  Colors.blue,
                  Icons.people,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Quick Actions
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _sendEventReminders(),
                  icon: const Icon(Icons.notifications),
                  label: const Text('Send Reminders'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _promoteFromWaitlist(),
                  icon: const Icon(Icons.arrow_upward),
                  label: const Text('Promote Waitlist'),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _exportAttendanceData(),
                  icon: const Icon(Icons.download),
                  label: const Text('Export Data'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showAttendanceSettings(),
                  icon: const Icon(Icons.settings),
                  label: const Text('Settings'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendeesTab() {
    final attendeeDetails = _attendanceStats!['attendeeDetails'] as List<Map<String, dynamic>>;
    final filteredAttendees = attendeeDetails.where((attendee) {
      final matchesSearch = attendee['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesFilter = _filterStatus == 'all' || attendee['rsvpStatus'] == _filterStatus;
      return matchesSearch && matchesFilter;
    }).toList();

    return Column(
      children: [
        // Search and Filter Bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search attendees...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              PopupMenuButton<String>(
                onSelected: (value) {
                  setState(() {
                    _filterStatus = value;
                  });
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'all', child: Text('All')),
                  const PopupMenuItem(value: EventModel.rsvpGoing, child: Text('Going')),
                  const PopupMenuItem(value: EventModel.rsvpInterested, child: Text('Interested')),
                  const PopupMenuItem(value: EventModel.rsvpNotGoing, child: Text('Not Going')),
                ],
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).colorScheme.outline),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_getFilterLabel(_filterStatus)),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Selection Actions
        if (_selectedUserIds.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.primary.withValues(alpha: 0.1),
            child: Row(
              children: [
                Text(
                  '${_selectedUserIds.length} selected',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _performBulkOperation('check_in_all'),
                  child: const Text('Check In All'),
                ),
                TextButton(
                  onPressed: () => _performBulkOperation('remove_all'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Remove All'),
                ),
              ],
            ),
          ),
        
        // Attendees List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filteredAttendees.length,
            itemBuilder: (context, index) {
              final attendee = filteredAttendees[index];
              final userId = attendee['userId'] as String;
              final isSelected = _selectedUserIds.contains(userId);

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Checkbox(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedUserIds.add(userId);
                        } else {
                          _selectedUserIds.remove(userId);
                        }
                      });
                    },
                  ),
                  title: Text(attendee['name'] as String),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(attendee['email'] as String),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildStatusChip(attendee['rsvpStatus'] as String),
                          if (attendee['isCheckedIn'] == true) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 16,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (action) => _performAttendeeAction(action, userId),
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'check_in', child: Text('Check In')),
                      const PopupMenuItem(value: 'message', child: Text('Send Message')),
                      const PopupMenuItem(value: 'remove', child: Text('Remove RSVP')),
                    ],
                  ),
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedUserIds.remove(userId);
                      } else {
                        _selectedUserIds.add(userId);
                      }
                    });
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWaitlistTab() {
    final attendeeDetails = _attendanceStats!['attendeeDetails'] as List<Map<String, dynamic>>;
    final waitlistAttendees = attendeeDetails.where((attendee) {
      return attendee['rsvpStatus'] == EventModel.rsvpWaitlist;
    }).toList();

    return Column(
      children: [
        // Waitlist Info
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.schedule, color: Colors.orange),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${waitlistAttendees.length} people on waitlist',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Promote people from waitlist when spots become available',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Waitlist Actions
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _promoteFromWaitlist(),
                  icon: const Icon(Icons.arrow_upward),
                  label: const Text('Promote All Available'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showWaitlistSettings(),
                  icon: const Icon(Icons.settings),
                  label: const Text('Settings'),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Waitlist Members
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: waitlistAttendees.length,
            itemBuilder: (context, index) {
              final attendee = waitlistAttendees[index];
              final userId = attendee['userId'] as String;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Text(
                      (index + 1).toString(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(attendee['name'] as String),
                  subtitle: Text(attendee['email'] as String),
                  trailing: ElevatedButton(
                    onPressed: () => _promoteSpecificUser(userId),
                    child: const Text('Promote'),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsTab() {
    final event = _attendanceStats!['event'] as EventModel;
    final totalRsvps = _attendanceStats!['totalRsvps'] as int;
    final goingCount = _attendanceStats!['goingCount'] as int;
    final waitlistCount = _attendanceStats!['waitlistCount'] as int;
    final checkInCount = _attendanceStats!['checkInCount'] as int;
    
    final rsvpRate = totalRsvps > 0 ? (goingCount / totalRsvps * 100) : 0.0;
    final checkInRate = goingCount > 0 ? (checkInCount / goingCount * 100) : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // RSVP Rate
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'RSVP Rate',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: rsvpRate / 100,
                    backgroundColor: Colors.grey.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${rsvpRate.toStringAsFixed(1)}% of RSVPs are "Going"',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Check-in Rate
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Check-in Rate',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: checkInRate / 100,
                    backgroundColor: Colors.grey.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${checkInRate.toStringAsFixed(1)}% of attendees checked in',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Time-based Analytics
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'RSVP Timeline',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTimelineItem('Event Created', event.createdAt),
                  _buildTimelineItem('First RSVP', _getFirstRsvpTime()),
                  _buildTimelineItem('Peak RSVP Day', _getPeakRsvpDay()),
                  _buildTimelineItem('Event Date', event.date),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status) {
      case EventModel.rsvpGoing:
        color = Colors.green;
        label = 'Going';
        break;
      case EventModel.rsvpInterested:
        color = Colors.orange;
        label = 'Interested';
        break;
      case EventModel.rsvpNotGoing:
        color = Colors.red;
        label = 'Not Going';
        break;
      case EventModel.rsvpWaitlist:
        color = Colors.purple;
        label = 'Waitlist';
        break;
      default:
        color = Colors.grey;
        label = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _getFilterLabel(String filter) {
    switch (filter) {
      case 'all':
        return 'All';
      case EventModel.rsvpGoing:
        return 'Going';
      case EventModel.rsvpInterested:
        return 'Interested';
      case EventModel.rsvpNotGoing:
        return 'Not Going';
      default:
        return 'All';
    }
  }

  Widget _buildTimelineItem(String title, DateTime? date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title),
          ),
          if (date != null)
            Text(
              _formatDate(date),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  DateTime? _getFirstRsvpTime() {
    // This would be implemented based on your data structure
    return null;
  }

  DateTime? _getPeakRsvpDay() {
    // This would be implemented based on your data structure
    return null;
  }

  // Action Methods
  Future<void> _sendEventReminders() async {
    try {
      final eventService = EventService();
      await eventService.sendEventReminders();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reminders sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _logger.e('Error sending reminders: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending reminders: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _promoteFromWaitlist() async {
    try {
      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser == null) return;

      final eventService = EventService();
      final event = _attendanceStats!['event'] as EventModel;
      
      // Get waitlist users
      final waitlistUserIds = event.waitlistUserIds;
      
      if (waitlistUserIds.isNotEmpty) {
        await eventService.bulkRsvpOperation(
          widget.eventId,
          waitlistUserIds,
          'confirm_all',
          currentUser,
        );
        
        await _loadAttendanceStats();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Waitlist users promoted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      _logger.e('Error promoting from waitlist: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error promoting from waitlist: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _promoteSpecificUser(String userId) async {
    try {
      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser == null) return;

      final eventService = EventService();
      await eventService.promoteFromWaitlist(widget.eventId, userId, currentUser);
      
      await _loadAttendanceStats();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User promoted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _logger.e('Error promoting user: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error promoting user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _performBulkOperation(String operation) async {
    try {
      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser == null) return;

      final eventService = EventService();
      await eventService.bulkRsvpOperation(
        widget.eventId,
        _selectedUserIds.toList(),
        operation,
        currentUser,
      );

      await _loadAttendanceStats();
      
      setState(() {
        _selectedUserIds.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bulk operation completed: $operation'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _logger.e('Error performing bulk operation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error performing operation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _performAttendeeAction(String action, String userId) async {
    try {
      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser == null) return;

      final eventService = EventService();
      
      switch (action) {
        case 'check_in':
          await eventService.checkInToEvent(widget.eventId, UserModel(
            id: userId,
            displayName: '',
            email: '',
            role: 'user',
            createdAt: DateTime.now(),
            phoneNumber: '',
            lastSeen: DateTime.now(),
          ));
          break;
        case 'remove':
          await eventService.rsvpToEvent(widget.eventId, 'remove', UserModel(
            id: userId,
            displayName: '',
            email: '',
            role: 'user',
            createdAt: DateTime.now(),
            phoneNumber: '',
            lastSeen: DateTime.now(),
          ));
          break;
        case 'message':
          // Implement messaging functionality
          break;
      }

      await _loadAttendanceStats();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Action completed: $action'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _logger.e('Error performing attendee action: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error performing action: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _exportAttendanceData() {
    // Implement export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export functionality coming soon!')),
    );
  }

  void _showAttendanceSettings() {
    // Implement settings functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings functionality coming soon!')),
    );
  }

  void _showWaitlistSettings() {
    // Implement waitlist settings functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Waitlist settings coming soon!')),
    );
  }
} 