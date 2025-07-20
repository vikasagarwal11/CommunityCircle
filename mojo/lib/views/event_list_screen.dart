import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';
import '../core/logger.dart';
import '../core/navigation_service.dart';
import '../core/theme.dart';
import '../models/event_model.dart';
import '../models/user_model.dart';
import '../models/community_model.dart';
import '../providers/auth_providers.dart';
import '../providers/database_providers.dart';
import '../providers/event_providers.dart';
import '../providers/community_providers.dart';
import '../services/event_service.dart';
import '../services/community_service.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import 'community_details_screen_logic.dart';

class EventListScreen extends ConsumerStatefulWidget {
  final String? communityId;
  final bool isTab;

  const EventListScreen({
    super.key,
    this.communityId,
    this.isTab = false,
  });

  @override
  ConsumerState<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends ConsumerState<EventListScreen> {
  final Logger _logger = Logger('EventListScreen');
  final EventService _eventService = EventService();
  final CommunityService _communityService = CommunityService();
  
  // Search and filter state
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedStatus = 'All';
  String _selectedRsvpStatus = 'All';
  String _selectedCommunity = 'All';
  DateTime? _selectedDate;
  bool _showFilters = false;
  
  // Available filter options
  final List<String> _categories = ['All', 'Meeting', 'Workshop', 'Social', 'Sports', 'Business', 'Education', 'Other'];
  final List<String> _statuses = ['All', 'Upcoming', 'Past', 'Today', 'This Week', 'This Month'];
  final List<String> _rsvpStatuses = ['All', 'Going', 'Interested', 'Not Going', 'Waitlist', 'Not RSVP\'d'];
  List<String> _communities = ['All'];
  
  @override
  void initState() {
    super.initState();
    _loadCommunities();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _loadCommunities() async {
    try {
      final user = ref.read(currentUserProvider).value;
      if (user != null) {
        // Get the first value from the stream
        final userCommunities = await _communityService.getUserCommunities(user.id).first;
        setState(() {
          _communities = ['All', ...userCommunities.map((c) => c.name)];
        });
      }
    } catch (e) {
      _logger.e('Error loading communities: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: widget.isTab ? null : _buildAppBar(),
      body: Column(
        children: [
          _buildSearchHeader(),
          if (_showFilters) _buildFilterPanel(),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
      floatingActionButton: widget.communityId == null ? _buildFloatingActionButton() : null,
    );
  }

  PreferredSizeWidget? _buildAppBar() {
    return AppBar(
      title: Text(
        widget.communityId != null ? 'Events' : 'All Events',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => NavigationService.goBack(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: () => NavigationService.navigateToCalendar(communityId: widget.communityId),
          tooltip: 'Calendar View',
        ),
        if (widget.communityId != null)
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateEventDialog,
          ),
      ],
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.all(12), // Reduced from 16
      child: Column(
        children: [
          // Search bar - more compact
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8), // Reduced from 12
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03), // Reduced from 0.05
                  blurRadius: 4, // Reduced from 8
                  offset: const Offset(0, 1), // Reduced from (0, 2)
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search events...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 18), // Reduced size
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey, size: 18), // Reduced size
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.calendar_today, color: Colors.grey, size: 18), // Reduced size
                            onPressed: () => NavigationService.navigateToCalendar(communityId: widget.communityId),
                            tooltip: 'Calendar View',
                          ),
                          IconButton(
                            icon: Icon(
                              _showFilters ? Icons.filter_list : Icons.filter_list_outlined,
                              color: _showFilters ? AppColors.primary : Colors.grey,
                              size: 18, // Reduced size
                            ),
                            onPressed: () {
                              setState(() {
                                _showFilters = !_showFilters;
                              });
                            },
                          ),
                        ],
                      ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Reduced padding
              ),
            ),
          ),
          
          // Active filters indicator - more compact
          if (_hasActiveFilters())
            Container(
              margin: const EdgeInsets.only(top: 6), // Reduced from 8
              child: Wrap(
                spacing: 6, // Reduced from 8
                runSpacing: 3, // Reduced from 4
                children: [
                  if (_selectedCategory != 'All')
                    _buildFilterChip('Category: $_selectedCategory', () {
                      setState(() {
                        _selectedCategory = 'All';
                      });
                    }),
                  if (_selectedStatus != 'All')
                    _buildFilterChip('Status: $_selectedStatus', () {
                      setState(() {
                        _selectedStatus = 'All';
                      });
                    }),
                  if (_selectedRsvpStatus != 'All')
                    _buildFilterChip('RSVP: $_selectedRsvpStatus', () {
                      setState(() {
                        _selectedRsvpStatus = 'All';
                      });
                    }),
                  if (_selectedCommunity != 'All')
                    _buildFilterChip('Community: $_selectedCommunity', () {
                      setState(() {
                        _selectedCommunity = 'All';
                      });
                    }),
                  if (_selectedDate != null)
                    _buildFilterChip('Date: ${DateFormat('MMM dd').format(_selectedDate!)}', () {
                      setState(() {
                        _selectedDate = null;
                      });
                    }),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.filter_list, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'Filters',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _clearAllFilters,
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Category filter
          _buildFilterSection(
            'Category',
            _categories,
            _selectedCategory,
            (value) => setState(() => _selectedCategory = value),
          ),
          
          const SizedBox(height: 12),
          
          // Status filter
          _buildFilterSection(
            'Status',
            _statuses,
            _selectedStatus,
            (value) => setState(() => _selectedStatus = value),
          ),
          
          const SizedBox(height: 12),
          
          // RSVP Status filter
          _buildFilterSection(
            'RSVP Status',
            _rsvpStatuses,
            _selectedRsvpStatus,
            (value) => setState(() => _selectedRsvpStatus = value),
          ),
          
          const SizedBox(height: 12),
          
          // Community filter
          _buildFilterSection(
            'Community',
            _communities,
            _selectedCommunity,
            (value) => setState(() => _selectedCommunity = value),
          ),
          
          const SizedBox(height: 12),
          
          // Date filter
          _buildDateFilter(),
        ],
      ),
    );
  }

  Widget _buildFilterSection(
    String title,
    List<String> options,
    String selectedValue,
    Function(String) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: options.map((option) {
            final isSelected = option == selectedValue;
            return GestureDetector(
              onTap: () => onChanged(option),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.grey.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? Colors.white : Colors.grey[700],
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate ?? DateTime.now(),
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() {
                      _selectedDate = date;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _selectedDate != null 
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _selectedDate != null 
                          ? AppColors.primary 
                          : Colors.grey.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: _selectedDate != null ? AppColors.primary : Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _selectedDate != null 
                            ? DateFormat('MMM dd, yyyy').format(_selectedDate!)
                            : 'Select date',
                        style: TextStyle(
                          fontSize: 12,
                          color: _selectedDate != null ? AppColors.primary : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_selectedDate != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = null;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.clear,
                    size: 16,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close,
              size: 12,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  bool _hasActiveFilters() {
    return _selectedCategory != 'All' ||
           _selectedStatus != 'All' ||
           _selectedRsvpStatus != 'All' ||
           _selectedCommunity != 'All' ||
           _selectedDate != null;
  }

  void _clearAllFilters() {
    setState(() {
      _selectedCategory = 'All';
      _selectedStatus = 'All';
      _selectedRsvpStatus = 'All';
      _selectedCommunity = 'All';
      _selectedDate = null;
    });
  }

  Widget _buildContent() {
    if (widget.communityId != null) {
      // Use stream-based provider for real-time updates
      final eventsAsync = ref.watch(communityEventsStreamProvider(widget.communityId!));
      
      return eventsAsync.when(
        data: (events) {
          final filteredEvents = _applyFilters(events);
          if (filteredEvents.isEmpty) {
            return _buildEmptyState();
          }
          
          return _buildOptimizedEventList(filteredEvents);
        },
        loading: () => const LoadingWidget(),
        error: (error, stack) => CustomErrorWidget(
          message: 'Error loading events: $error',
          onRetry: () => ref.refresh(communityEventsStreamProvider(widget.communityId!)),
        ),
      );
    } else {
      final currentUser = ref.watch(currentUserProvider).value;
      
      if (currentUser == null) {
        return _buildEmptyState();
      }
      
      // Use stream-based provider for real-time updates
      final accessibleEventsAsync = ref.watch(accessibleEventsStreamProvider);
      
      return accessibleEventsAsync.when(
        data: (events) {
          final filteredEvents = _applyFilters(events);
          if (filteredEvents.isEmpty) {
            return _buildEmptyState();
          }
          
          return _buildOptimizedEventList(filteredEvents);
        },
        loading: () => const LoadingWidget(),
        error: (error, stack) => CustomErrorWidget(
          message: 'Error loading events: $error',
          onRetry: () => ref.refresh(accessibleEventsStreamProvider),
        ),
      );
    }
  }

  List<EventModel> _applyFilters(List<EventModel> events) {
    List<EventModel> filtered = events;

    // Search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((event) {
        return event.title.toLowerCase().contains(query) ||
               event.description.toLowerCase().contains(query) ||
               event.location.toLowerCase().contains(query);
      }).toList();
    }

    // Category filter
    if (_selectedCategory != 'All') {
      filtered = filtered.where((event) {
        return event.category?.toLowerCase() == _selectedCategory.toLowerCase();
      }).toList();
    }

    // Status filter
    if (_selectedStatus != 'All') {
      final now = DateTime.now();
      filtered = filtered.where((event) {
        switch (_selectedStatus) {
          case 'Upcoming':
            return event.date.isAfter(now);
          case 'Past':
            return event.date.isBefore(now);
          case 'Today':
            final today = DateTime(now.year, now.month, now.day);
            final eventDay = DateTime(event.date.year, event.date.month, event.date.day);
            return eventDay.isAtSameMomentAs(today);
          case 'This Week':
            final weekStart = now.subtract(Duration(days: now.weekday - 1));
            final weekEnd = weekStart.add(const Duration(days: 7));
            return event.date.isAfter(weekStart) && event.date.isBefore(weekEnd);
          case 'This Month':
            final monthStart = DateTime(now.year, now.month, 1);
            final monthEnd = DateTime(now.year, now.month + 1, 1);
            return event.date.isAfter(monthStart) && event.date.isBefore(monthEnd);
          default:
            return true;
        }
      }).toList();
    }

    // RSVP Status filter
    if (_selectedRsvpStatus != 'All') {
      filtered = filtered.where((event) {
        final currentUser = ref.read(currentUserProvider).value;
        if (currentUser == null) return false;
        
        final userRsvpStatus = event.getUserRsvpStatus(currentUser.id);
        
        switch (_selectedRsvpStatus) {
          case 'Going':
            return userRsvpStatus == EventModel.rsvpGoing;
          case 'Interested':
            return userRsvpStatus == EventModel.rsvpInterested;
          case 'Not Going':
            return userRsvpStatus == EventModel.rsvpNotGoing;
          case 'Waitlist':
            return userRsvpStatus == EventModel.rsvpWaitlist;
          case 'Not RSVP\'d':
            return userRsvpStatus == null;
          default:
            return true;
        }
      }).toList();
    }

    // Community filter
    if (_selectedCommunity != 'All') {
      // This would need to be implemented based on your data structure
      // For now, we'll skip this filter
    }

    // Date filter
    if (_selectedDate != null) {
      final selectedDay = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
      );
      filtered = filtered.where((event) {
        final eventDay = DateTime(
          event.date.year,
          event.date.month,
          event.date.day,
        );
        return eventDay.isAtSameMomentAs(selectedDay);
      }).toList();
    }

    return filtered;
  }

  Widget _buildOptimizedEventList(List<EventModel> events) {
    // Group events by date
    final groupedEvents = _groupEventsByDate(events);
    final dateGroups = groupedEvents.entries.toList();
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: dateGroups.length,
      itemBuilder: (context, index) {
        final dateGroup = dateGroups[index];
        return _buildDateGroup(dateGroup);
      },
    );
  }

  Widget _buildDateGroup(MapEntry<DateTime, List<EventModel>> dateGroup) {
    final date = dateGroup.key;
    final events = dateGroup.value;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date header
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Text(
            _formatDateHeader(date),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ),
        // Events for this date
        ...events.map((event) => _buildOptimizedEventCard(event)),
      ],
    );
  }

  Widget _buildOptimizedEventCard(EventModel event) {
    // Watch the current user for real-time updates
    final currentUserAsync = ref.watch(currentUserProvider);
    final currentUser = currentUserAsync.value;
    
    // Get the user's RSVP status for this specific event
    final userRsvpStatus = currentUser != null ? event.getUserRsvpStatus(currentUser.id) : null;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToEventDetails(event),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Compact time column
                Container(
                  width: 50,
                  child: Column(
                    children: [
                      Text(
                        _formatCompactTime(event.date),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        width: 1.5,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(0.75),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 10),
                
                // Event details - more compact
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and status in one row
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              event.title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          _buildCompactStatusBadge(event),
                        ],
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Location and RSVP status in one row
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 12,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              event.location,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Compact RSVP indicator - only show if user has RSVP'd
                          if (userRsvpStatus != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: _getRsvpStatusColor(userRsvpStatus).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getRsvpStatusIcon(userRsvpStatus),
                                    size: 10,
                                    color: _getRsvpStatusColor(userRsvpStatus),
                                  ),
                                  const SizedBox(width: 1),
                                  Text(
                                    _getRsvpStatusText(userRsvpStatus),
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: _getRsvpStatusColor(userRsvpStatus),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      
                      const SizedBox(height: 6),
                      
                      // Bottom row: attendees, spots, quick actions
                      Row(
                        children: [
                          // Attendees count
                          if (event.goingCount > 0) ...[
                            Icon(Icons.people, size: 10, color: Colors.green),
                            const SizedBox(width: 2),
                            Text(
                              '${event.goingCount}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          
                          // Spots left
                          if (event.hasSpotsLimit && !event.isFull) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.event_seat, size: 10, color: Colors.orange),
                            const SizedBox(width: 2),
                            Text(
                              '${event.availableSpots}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          
                          // Full indicator
                          if (event.hasSpotsLimit && event.isFull) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: const Text(
                                'FULL',
                                style: TextStyle(
                                  fontSize: 8,
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                          
                          const Spacer(),
                          
                          // Quick RSVP actions (compact)
                          if (currentUser != null && !event.isPast)
                            Row(
                              children: [
                                _buildCompactRsvpButton(
                                  event,
                                  Icons.check_circle,
                                  Colors.green,
                                  EventModel.rsvpGoing,
                                  userRsvpStatus == EventModel.rsvpGoing,
                                ),
                                const SizedBox(width: 4),
                                _buildCompactRsvpButton(
                                  event,
                                  Icons.help_outline,
                                  Colors.orange,
                                  EventModel.rsvpInterested,
                                  userRsvpStatus == EventModel.rsvpInterested,
                                ),
                                const SizedBox(width: 4),
                                _buildCompactRsvpButton(
                                  event,
                                  Icons.cancel,
                                  Colors.red,
                                  EventModel.rsvpNotGoing,
                                  userRsvpStatus == EventModel.rsvpNotGoing,
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactStatusBadge(EventModel event) {
    if (event.isPast) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'PAST',
          style: TextStyle(
            fontSize: 9,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'UPCOMING',
        style: TextStyle(
          fontSize: 9,
          color: Colors.green,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final currentUserAsync = ref.watch(currentUserProvider);
    final currentUser = currentUserAsync.value;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            widget.communityId != null ? 'No events in this community' : 'No events available',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.communityId != null 
                ? 'Events created in this community will appear here'
                : 'Join communities to see their events or create your own!',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (currentUser == null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  const SizedBox(height: 8),
                  const Text(
                    'Not logged in',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'You need to log in to see and create events',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.withValues(alpha: 0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => NavigationService.navigateToSearch(),
              icon: const Icon(Icons.search, size: 16),
              label: const Text('Discover Communities'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => NavigationService.navigateToSearch(),
              icon: const Icon(Icons.search, size: 16),
              label: const Text('Discover Communities'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) {
      return null;
    }

    return FloatingActionButton(
      heroTag: 'event_list_fab',
      onPressed: _showCreateEventOptions,
      child: const Icon(Icons.add),
      tooltip: 'Create Event',
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference > 1) {
      return '${date.day}/${date.month}/${date.year}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Map<DateTime, List<EventModel>> _groupEventsByDate(List<EventModel> events) {
    final grouped = <DateTime, List<EventModel>>{};
    
    for (final event in events) {
      final date = DateTime(event.date.year, event.date.month, event.date.day);
      grouped.putIfAbsent(date, () => []).add(event);
    }
    
    // Sort by date and then by time within each date
    final sortedGroups = grouped.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    
    for (final entry in sortedGroups) {
      entry.value.sort((a, b) => a.date.compareTo(b.date));
    }
    
    return Map.fromEntries(sortedGroups);
  }

  String _getRsvpStatusText(String status) {
    switch (status) {
      case EventModel.rsvpGoing:
        return 'Going';
      case EventModel.rsvpInterested:
        return 'Interested';
      case EventModel.rsvpNotGoing:
        return 'Not Going';
      case EventModel.rsvpWaitlist:
        return 'Waitlist';
      default:
        return 'Unknown';
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
        return Icons.help_outline;
    }
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

  void _navigateToEventDetails(EventModel event) {
    NavigationService.navigateToEventDetails(event.id, communityId: event.communityId);
  }

  void _showCreateEventDialog() {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to create events')),
      );
      return;
    }

    // Use centralized logic for event creation
    if (widget.communityId != null) {
      // Create a temporary community model for the logic
      final tempCommunity = CommunityModel(
        id: widget.communityId!,
        name: 'Community', // This will be overridden by the actual community
        description: '',
        adminUid: '',
        members: [],
        visibility: 'public',
        approvalRequired: false,
        isBusiness: false,
        createdAt: DateTime.now(),
        badgeUrl: '',
        bannedUsers: [],
        coverImage: '',
        joinQuestions: [],
        metadata: <String, dynamic>{},
        pinnedItems: [],
        rules: <String>[],
        tags: <String>[],
        theme: <String, String>{},
        welcomeMessage: '',
      );
      CommunityDetailsLogic.handleCreateEvent(context, ref, tempCommunity);
    } else {
      // For global event list, show smart template picker
      _showSmartEventTemplates();
    }
  }

  void _showCreateEventOptions() {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to create events')),
      );
      return;
    }

    // Show smart template picker instead of basic options
    _showSmartEventTemplates();
  }

  void _showSmartEventTemplates() {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to create events')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.event_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Create Event',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Template Grid
            Text(
              'Choose Event Type',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
                children: [
                  _buildTemplateCard(
                    context,
                    'Meeting',
                    Icons.meeting_room_rounded,
                    'Regular community meeting',
                    Colors.blue,
                    () => _handleTemplateSelection('Meeting'),
                  ),
                  _buildTemplateCard(
                    context,
                    'Workshop',
                    Icons.workspace_premium_rounded,
                    'Educational workshop',
                    Colors.green,
                    () => _handleTemplateSelection('Workshop'),
                  ),
                  _buildTemplateCard(
                    context,
                    'Social',
                    Icons.people_rounded,
                    'Social gathering',
                    Colors.orange,
                    () => _handleTemplateSelection('Social'),
                  ),
                  _buildTemplateCard(
                    context,
                    'Webinar',
                    Icons.video_call_rounded,
                    'Online presentation',
                    Colors.purple,
                    () => _handleTemplateSelection('Webinar'),
                  ),
                  _buildTemplateCard(
                    context,
                    'Hackathon',
                    Icons.code_rounded,
                    'Coding event',
                    Colors.indigo,
                    () => _handleTemplateSelection('Hackathon'),
                  ),
                  _buildTemplateCard(
                    context,
                    'Custom',
                    Icons.edit_rounded,
                    'Create from scratch',
                    Colors.grey,
                    () => _handleTemplateSelection('Custom'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateCard(
    BuildContext context,
    String title,
    IconData icon,
    String description,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _handleTemplateSelection(String templateType) {
    Navigator.pop(context); // Close template picker
    
    // Get user's communities to determine next step
    final userCommunitiesAsync = ref.read(userCommunitiesProvider);
    
    userCommunitiesAsync.when(
      data: (communities) {
        if (communities.isEmpty) {
          // No communities - create community + event
          _createCommunityWithEvent(templateType);
        } else if (communities.length == 1) {
          // One community - create event directly
          _createEventForCommunity(communities.first, templateType);
        } else {
          // Multiple communities - show community picker
          _showCommunityPicker(communities, templateType);
        }
      },
      loading: () {
        // Show loading and retry
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Loading your communities...')),
        );
      },
      error: (error, stack) {
        // Show error and suggest community creation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading communities: $error'),
            action: SnackBarAction(
              label: 'Create Community',
              onPressed: () => _createCommunityWithEvent(templateType),
            ),
          ),
        );
      },
    );
  }

  void _createCommunityWithEvent(String templateType) {
    // Navigate to community creation with event template
    NavigationService.navigateToCreateCommunity(
      eventTemplate: _getTemplateData(templateType),
    );
  }

  void _createEventForCommunity(CommunityModel community, String templateType) {
    // Create event directly for the community
    final templateData = _getTemplateData(templateType);
    NavigationService.navigateToCreateEvent(
      communityId: community.id,
      templateData: templateData,
    );
  }

  void _showCommunityPicker(List<CommunityModel> communities, String templateType) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose Community',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Select a community to create your event in:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: communities.length + 1, // +1 for "Create New Community"
                itemBuilder: (context, index) {
                  if (index == communities.length) {
                    // "Create New Community" option
                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.add_business_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      title: const Text('Create New Community'),
                      subtitle: const Text('Start a new community with this event'),
                      onTap: () {
                        Navigator.pop(context);
                        _createCommunityWithEvent(templateType);
                      },
                    );
                  }
                  
                  final community = communities[index];
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.group_rounded,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    title: Text(community.name),
                    subtitle: Text('${community.members.length} members'),
                    onTap: () {
                      Navigator.pop(context);
                      _createEventForCommunity(community, templateType);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getTemplateData(String templateType) {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    
    switch (templateType) {
      case 'Meeting':
        return {
          'title': 'Community Meeting',
          'description': 'Regular community meeting to discuss updates and plan future activities.',
          'date': tomorrow,
          'location': 'Community Space',
          'templateType': 'Meeting',
          'category': 'meeting',
          'visibility': 'public',
          'approvalRequired': false,
          'isBusinessEvent': false,
        };
      case 'Workshop':
        return {
          'title': 'Educational Workshop',
          'description': 'Learn new skills and share knowledge with community members.',
          'date': tomorrow.add(const Duration(days: 2)),
          'location': 'Workshop Room',
          'templateType': 'Workshop',
          'category': 'workshop',
          'visibility': 'public',
          'approvalRequired': false,
          'isBusinessEvent': false,
        };
      case 'Social':
        return {
          'title': 'Social Gathering',
          'description': 'Casual meetup to connect and build relationships.',
          'date': tomorrow.add(const Duration(days: 3)),
          'location': 'Social Venue',
          'templateType': 'Social',
          'category': 'social',
          'visibility': 'public',
          'approvalRequired': false,
          'isBusinessEvent': false,
        };
      case 'Webinar':
        return {
          'title': 'Online Webinar',
          'description': 'Virtual presentation and discussion session.',
          'date': tomorrow.add(const Duration(days: 4)),
          'location': 'Online',
          'templateType': 'Webinar',
          'category': 'webinar',
          'visibility': 'public',
          'approvalRequired': false,
          'isBusinessEvent': false,
        };
      case 'Hackathon':
        return {
          'title': 'Coding Hackathon',
          'description': 'Collaborative coding session to build something amazing.',
          'date': tomorrow.add(const Duration(days: 7)),
          'location': 'Tech Hub',
          'templateType': 'Hackathon',
          'category': 'hackathon',
          'visibility': 'public',
          'approvalRequired': false,
          'isBusinessEvent': false,
        };
      case 'Custom':
      default:
        return {
          'title': '',
          'description': '',
          'date': tomorrow,
          'location': '',
          'templateType': 'Custom',
          'category': '',
          'visibility': 'public',
          'approvalRequired': false,
          'isBusinessEvent': false,
        };
    }
  }

  Widget _buildQuickRsvpButton(
    EventModel event,
    String label,
    IconData icon,
    Color color,
    String rsvpStatus,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () => _handleQuickRsvp(event, rsvpStatus),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? color : Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? color : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleQuickRsvp(EventModel event, String rsvpStatus) {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to RSVP')),
      );
      return;
    }

    // Get the event notifier for this community
    final eventNotifier = ref.read(eventNotifierProvider(event.communityId).notifier);
    
    // Update RSVP status
    eventNotifier.rsvpToEvent(event.id, currentUser.id, rsvpStatus);
    
    // Invalidate stream providers to trigger real-time updates
    if (widget.communityId != null) {
      ref.invalidate(communityEventsStreamProvider(widget.communityId!));
    } else {
      ref.invalidate(accessibleEventsStreamProvider);
    }
    
    // Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('RSVP updated: $rsvpStatus'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildCompactRsvpButton(
    EventModel event,
    IconData icon,
    Color color,
    String rsvpStatus,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () => _handleQuickRsvp(event, rsvpStatus),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Icon(
          icon,
          size: 12,
          color: isSelected ? color : Colors.grey[600],
        ),
      ),
    );
  }

  String _formatCompactTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }
} 