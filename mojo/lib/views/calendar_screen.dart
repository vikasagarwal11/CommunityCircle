import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import '../models/event_model.dart';
import '../providers/event_providers.dart';
import '../core/theme.dart';
import '../core/logger.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _selectedDay = _focusedDay;
  }

  void _initializeAnimations() {
    // Fade animation for smooth transitions
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

    // Slide animation for event cards
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

    // Pulse animation for quick actions
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _fadeController.forward();
    _slideController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
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
            _buildHeader(),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    _buildCalendar(eventsAsync),
                    Expanded(
                      child: _buildEventList(selectedEvents),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildQuickActions(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
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
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          ),
          const Expanded(
            child: Text(
              'Calendar',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          ScaleTransition(
            scale: _pulseAnimation,
            child: IconButton(
              onPressed: () {
                setState(() {
                  _focusedDay = DateTime.now();
                  _selectedDay = DateTime.now();
                });
              },
              icon: const Icon(Icons.today, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(AsyncValue<List<EventModel>> eventsAsync) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
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
            _slideController.reset();
            _slideController.forward();
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
          ),
          headerStyle: const HeaderStyle(
            formatButtonVisible: true,
            titleCentered: true,
            formatButtonShowsNext: false,
            formatButtonDecoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.all(Radius.circular(12.0)),
            ),
            formatButtonTextStyle: TextStyle(color: Colors.white),
            titleTextStyle: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurface,
            ),
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
                    width: 8,
                    height: 8,
                    child: const Center(
                      child: Icon(
                        Icons.circle,
                        size: 8,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              }
              return null;
            },
            selectedBuilder: (context, date, _) {
              return Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                ),
                child: Center(
                  child: Text(
                    '${date.day}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              );
            },
            todayBuilder: (context, date, _) {
              return Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: Center(
                  child: Text(
                    '${date.day}',
                    style: const TextStyle(color: AppColors.primary),
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

  Widget _buildEventList(AsyncValue<List<EventModel>> selectedEvents) {
    return selectedEvents.when(
      data: (events) {
        if (events.isEmpty) {
          return _buildEmptyState();
        }

        return SlideTransition(
          position: _slideAnimation,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return _buildEventCard(event, index);
            },
          ),
        );
      },
      loading: () => const Center(child: LoadingWidget()),
      error: (error, stack) => CustomErrorWidget(
        message: 'Failed to load events',
        onRetry: () => ref.refresh(selectedDayEventsProvider(_selectedDay ?? DateTime.now())),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/animations/empty_calendar.json',
            width: 200,
            height: 200,
            repeat: true,
          ),
          const SizedBox(height: 20),
          Text(
            'No events on ${DateFormat('MMM dd, yyyy').format(_selectedDay ?? DateTime.now())}',
            style: const TextStyle(
              fontSize: 18,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Tap the + button to create an event',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(EventModel event, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(
              context,
              '/event-details',
              arguments: event,
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  AppColors.primary.withValues(alpha: 0.05),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 16,
                                color: AppColors.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat('h:mm a').format(event.date),
                                style: const TextStyle(
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Icon(
                                Icons.location_on,
                                size: 16,
                                color: AppColors.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  event.location,
                                  style: const TextStyle(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getEventStatusColor(event.status),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        event.status,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                if (event.description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    event.description,
                    style: TextStyle(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.people,
                      size: 16,
                      color: AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${event.participants.length} participants',
                      style: const TextStyle(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    if (event.communityId.isNotEmpty) ...[
                      Icon(
                        Icons.group,
                        size: 16,
                        color: AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Community Event',
                        style: const TextStyle(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getEventStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'upcoming':
        return Colors.blue;
      case 'ongoing':
        return Colors.green;
      case 'completed':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return AppColors.primary;
    }
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        FloatingActionButton(
          onPressed: () {
            Navigator.pushNamed(context, '/create-event');
          },
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add, color: Colors.white),
        ),
        FloatingActionButton(
          onPressed: () {
            setState(() {
              _focusedDay = DateTime.now();
              _selectedDay = DateTime.now();
            });
          },
          backgroundColor: AppColors.secondary,
          child: const Icon(Icons.today, color: Colors.white),
        ),
        FloatingActionButton(
          onPressed: () {
            setState(() {
              _calendarFormat = _calendarFormat == CalendarFormat.month
                  ? CalendarFormat.week
                  : CalendarFormat.month;
            });
          },
          backgroundColor: AppColors.tertiary,
          child: Icon(
            _calendarFormat == CalendarFormat.month
                ? Icons.view_week
                : Icons.view_module,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
} 