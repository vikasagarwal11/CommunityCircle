import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';
import '../models/user_model.dart';
import '../core/constants.dart';
import '../core/logger.dart';
import '../providers/auth_providers.dart';
import '../providers/community_providers.dart';

final Logger _logger = Logger('EventProviders');

// Event notifier for managing events
class EventNotifier extends StateNotifier<AsyncValue<List<EventModel>>> {
  final String communityId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  EventNotifier(this.communityId) : super(const AsyncValue.loading()) {
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    try {
      state = const AsyncValue.loading();
      
      final query = _firestore
          .collection(AppConstants.eventsCollection)
          .where('communityId', isEqualTo: communityId)
          .orderBy('date', descending: false);

      final snapshot = await query.get();
      final events = snapshot.docs
          .map((doc) => EventModel.fromMap(doc.data(), doc.id))
          .toList();

      state = AsyncValue.data(events);
      _logger.i('📅 Loaded ${events.length} events for community: $communityId');
    } catch (e, stack) {
      _logger.e('❌ Error loading events: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  // Create new event (admin only)
  Future<void> createEvent(EventModel event) async {
    try {
      final docRef = await _firestore
          .collection(AppConstants.eventsCollection)
          .add(event.toMap());

      final newEvent = event.copyWith(id: docRef.id);
      
      state.whenData((events) {
        state = AsyncValue.data([newEvent, ...events]);
      });

      _logger.i('🎬 Created event: ${event.title}');
    } catch (e) {
      _logger.e('❌ Error creating event: $e');
      rethrow;
    }
  }

  // Update event (admin only)
  Future<void> updateEvent(EventModel event) async {
    try {
      await _firestore
          .collection(AppConstants.eventsCollection)
          .doc(event.id)
          .update(event.toMap());

      state.whenData((events) {
        final updatedEvents = events.map((e) => e.id == event.id ? event : e).toList();
        state = AsyncValue.data(updatedEvents);
      });

      _logger.i('📝 Updated event: ${event.title}');
    } catch (e) {
      _logger.e('❌ Error updating event: $e');
      rethrow;
    }
  }

  // Delete event (admin only)
  Future<void> deleteEvent(String eventId) async {
    try {
      await _firestore
          .collection(AppConstants.eventsCollection)
          .doc(eventId)
          .delete();

      state.whenData((events) {
        final filteredEvents = events.where((e) => e.id != eventId).toList();
        state = AsyncValue.data(filteredEvents);
      });

      _logger.i('🗑️ Deleted event: $eventId');
    } catch (e) {
      _logger.e('❌ Error deleting event: $e');
      rethrow;
    }
  }

  // RSVP to event
  Future<void> rsvpToEvent(String eventId, String userId, String status) async {
    try {
      await _firestore
          .collection(AppConstants.eventsCollection)
          .doc(eventId)
          .update({
        'rsvps.$userId': status,
      });

      state.whenData((events) {
        final updatedEvents = events.map((event) {
          if (event.id == eventId) {
            final updatedRsvps = Map<String, String>.from(event.rsvps);
            updatedRsvps[userId] = status;
            return event.copyWith(rsvps: updatedRsvps);
          }
          return event;
        }).toList();
        state = AsyncValue.data(updatedEvents);
      });

      _logger.i('✅ RSVP updated: $userId -> $status for event: $eventId');
    } catch (e) {
      _logger.e('❌ Error updating RSVP: $e');
      rethrow;
    }
  }

  // Cancel RSVP
  Future<void> cancelRsvp(String eventId, String userId) async {
    try {
      await _firestore
          .collection(AppConstants.eventsCollection)
          .doc(eventId)
          .update({
        'rsvps.$userId': FieldValue.delete(),
      });

      state.whenData((events) {
        final updatedEvents = events.map((event) {
          if (event.id == eventId) {
            final updatedRsvps = Map<String, String>.from(event.rsvps);
            updatedRsvps.remove(userId);
            return event.copyWith(rsvps: updatedRsvps);
          }
          return event;
        }).toList();
        state = AsyncValue.data(updatedEvents);
      });

      _logger.i('❌ RSVP cancelled: $userId for event: $eventId');
    } catch (e) {
      _logger.e('❌ Error cancelling RSVP: $e');
      rethrow;
    }
  }

  // Check in to event
  Future<void> checkInToEvent(String eventId, String userId) async {
    try {
      await _firestore
          .collection(AppConstants.eventsCollection)
          .doc(eventId)
          .update({
        'checkIns.$userId': FieldValue.serverTimestamp(),
      });

      state.whenData((events) {
        final updatedEvents = events.map((event) {
          if (event.id == eventId) {
            final updatedCheckIns = Map<String, DateTime>.from(event.checkIns);
            updatedCheckIns[userId] = DateTime.now();
            return event.copyWith(checkIns: updatedCheckIns);
          }
          return event;
        }).toList();
        state = AsyncValue.data(updatedEvents);
      });

      _logger.i('✅ Checked in: $userId for event: $eventId');
    } catch (e) {
      _logger.e('❌ Error checking in: $e');
      rethrow;
    }
  }

  // Refresh events
  Future<void> refreshEvents() async {
    await _loadEvents();
  }
}

// Event notifier provider
final eventNotifierProvider = StateNotifierProvider.family<EventNotifier, AsyncValue<List<EventModel>>, String>((ref, communityId) {
  return EventNotifier(communityId);
});

// Global events provider (for calendar view)
final eventsProvider = StreamProvider<List<EventModel>>((ref) {
  final firestore = FirebaseFirestore.instance;
  return firestore
      .collection(AppConstants.eventsCollection)
      .orderBy('date', descending: false)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => EventModel.fromMap(doc.data(), doc.id))
          .toList());
});

// Selected day events provider
final selectedDayEventsProvider = StreamProvider.family<List<EventModel>, DateTime>((ref, selectedDay) {
  final firestore = FirebaseFirestore.instance;
  final startOfDay = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));
  
  return firestore
      .collection(AppConstants.eventsCollection)
      .where('date', isGreaterThanOrEqualTo: startOfDay)
      .where('date', isLessThan: endOfDay)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => EventModel.fromMap(doc.data(), doc.id))
          .toList());
});

// User's RSVP status for a specific event
final userEventRsvpProvider = Provider.family<String?, String>((ref, eventId) {
  final userAsync = ref.watch(authNotifierProvider);
  
  return userAsync.when(
    data: (user) {
      if (user == null) return null;
      
      // For now, return null - we'll implement this when we have the event data
      return null;
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

// User's check-in status for a specific event
final userEventCheckInProvider = Provider.family<bool, String>((ref, eventId) {
  final userAsync = ref.watch(authNotifierProvider);
  
  return userAsync.when(
    data: (user) {
      if (user == null) return false;
      
      // For now, return false - we'll implement this when we have the event data
      return false;
    },
    loading: () => false,
    error: (_, __) => false,
  );
});

// User's admin status for community
final userCommunityAdminProvider = Provider.family<bool, String>((ref, communityId) {
  final userAsync = ref.watch(authNotifierProvider);
  final communityAsync = ref.watch(communityDetailsProvider(communityId));
  
  return userAsync.when(
    data: (user) {
      if (user == null) return false;
      
      return communityAsync.when(
        data: (community) {
          return community?.adminUid == user.id;
        },
        loading: () => false,
        error: (_, __) => false,
      );
    },
    loading: () => false,
    error: (_, __) => false,
  );
});

// User's member status for community
final userCommunityMemberProvider = Provider.family<bool, String>((ref, communityId) {
  final userAsync = ref.watch(authNotifierProvider);
  final communityAsync = ref.watch(communityDetailsProvider(communityId));
  
  return userAsync.when(
    data: (user) {
      if (user == null) return false;
      
      return communityAsync.when(
        data: (community) {
          return community?.isMember(user.id) ?? false;
        },
        loading: () => false,
        error: (_, __) => false,
      );
    },
    loading: () => false,
    error: (_, __) => false,
  );
});

// Event creation permission provider
final eventCreationPermissionProvider = Provider.family<bool, String>((ref, communityId) {
  final isAdmin = ref.watch(userCommunityAdminProvider(communityId));
  
  // Only admins can create events
  return isAdmin;
});

// Event management permission provider (admin only)
final eventManagementPermissionProvider = Provider.family<bool, String>((ref, communityId) {
  final isAdmin = ref.watch(userCommunityAdminProvider(communityId));
  
  // Only admins can manage events
  return isAdmin;
}); 