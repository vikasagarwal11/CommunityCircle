import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';
import '../providers/event_providers.dart';
import '../core/theme.dart';
import '../core/logger.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import '../core/navigation_service.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsProvider);
    final selectedEvents = ref.watch(selectedDayEventsProvider(_selectedDay ?? DateTime.now()));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildCompactHeader(),
            _buildCompactCalendar(eventsAsync),
            Expanded(
              child: _buildCompactEventList(selectedEvents),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildCompactFAB(),
    );
  }

  Widget _buildCompactHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const Expanded(
            child: Text(
              'Calendar',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = DateTime.now();
              });
            },
            icon: const Icon(Icons.today, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactCalendar(AsyncValue<List<EventModel>> eventsAsync) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: TableCalendar<EventModel>(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onFormatChanged: (format) {
            setState(() {
              _calendarFormat = format;
            });
          },
          onPageChanged: (focusedDay) {
            setState(() {
              _focusedDay = focusedDay;
            });
          },
          calendarStyle: const CalendarStyle(
            outsideDaysVisible: false,
            weekendTextStyle: TextStyle(color: Colors.red),
            holidayTextStyle: TextStyle(color: Colors.red),
            cellMargin: EdgeInsets.all(2),
            cellPadding: EdgeInsets.all(4),
            defaultTextStyle: TextStyle(fontSize: 12),
            selectedTextStyle: TextStyle(fontSize: 12, color: Colors.white),
            todayTextStyle: TextStyle(fontSize: 12, color: AppColors.primary),
          ),
          headerStyle: const HeaderStyle(
            formatButtonVisible: true,
            titleCentered: true,
            formatButtonShowsNext: false,
            formatButtonDecoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
            ),
            formatButtonTextStyle: TextStyle(color: Colors.white, fontSize: 12),
            titleTextStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
            leftChevronIcon: Icon(Icons.chevron_left, size: 20),
            rightChevronIcon: Icon(Icons.chevron_right, size: 20),
            headerMargin: EdgeInsets.all(8),
            headerPadding: EdgeInsets.all(8),
          ),
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, date, events) {
              if (events.isNotEmpty) {
                return Positioned(
                  bottom: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                    ),
                    width: 6,
                    height: 6,
                  ),
                );
              }
              return null;
            },
            selectedBuilder: (context, date, _) {
              return Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                ),
                child: Center(
                  child: Text(
                    '${date.day}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              );
            },
            todayBuilder: (context, date, _) {
              return Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    '${date.day}',
                    style: const TextStyle(color: AppColors.primary, fontSize: 12),
                  ),
                ),
              );
            },
          ),
          eventLoader: (day) {
            return eventsAsync.when(
              data: (events) {
                return events.where((event) {
                  final eventDate = DateTime(
                    event.date.year,
                    event.date.month,
                    event.date.day,
                  );
                  final dayDate = DateTime(day.year, day.month, day.day);
                  return eventDate.isAtSameMomentAs(dayDate);
                }).toList();
              },
              loading: () => [],
              error: (_, __) => [],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCompactEventList(AsyncValue<List<EventModel>> selectedEvents) {
    return selectedEvents.when(
      data: (events) {
        if (events.isEmpty) {
          return _buildCompactEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            return _buildCompactEventCard(event);
          },
        );
      },
      loading: () => const Center(child: LoadingWidget()),
      error: (error, stack) => CustomErrorWidget(
        message: 'Failed to load events',
        onRetry: () => ref.refresh(selectedDayEventsProvider(_selectedDay ?? DateTime.now())),
      ),
    );
  }

  Widget _buildCompactEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 48,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No events on ${DateFormat('MMM dd').format(_selectedDay ?? DateTime.now())}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to create an event',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactEventCard(EventModel event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                // Time indicator
                Container(
                  width: 50,
                  child: Column(
                    children: [
                      Text(
                        DateFormat('HH:mm').format(event.date),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        width: 2,
                        height: 30,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Event details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Location
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 12,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event.location,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Quick stats
                      Row(
                        children: [
                          if (event.goingCount > 0) ...[
                            Icon(Icons.people, size: 12, color: Colors.green),
                            const SizedBox(width: 2),
                            Text(
                              '${event.goingCount}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (event.hasSpotsLimit && !event.isFull) ...[
                            Icon(Icons.event_seat, size: 12, color: Colors.orange),
                            const SizedBox(width: 2),
                            Text(
                              '${event.availableSpots}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          if (event.hasSpotsLimit && event.isFull) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'FULL',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Status indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: event.isPast 
                        ? Colors.grey.withValues(alpha: 0.2)
                        : Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    event.isPast ? 'PAST' : 'UPCOMING',
                    style: TextStyle(
                      fontSize: 9,
                      color: event.isPast ? Colors.grey : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactFAB() {
    return FloatingActionButton(
      heroTag: 'calendar_fab',
      onPressed: () => _showCreateEventOptions(context),
      child: const Icon(Icons.add),
      tooltip: 'Create Event',
    );
  }

  void _navigateToEventDetails(EventModel event) {
    NavigationService.navigateToEventDetails(event.id, communityId: event.communityId);
  }

  void _showCreateEventOptions(BuildContext context) {
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
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.event),
              title: const Text('Create New Event'),
              subtitle: const Text('Start from scratch'),
              onTap: () {
                Navigator.pop(context);
                NavigationService.navigateToCreateEvent();
              },
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Use Template'),
              subtitle: const Text('Quick setup with templates'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Show event templates
              },
            ),
          ],
        ),
      ),
    );
  }
} 