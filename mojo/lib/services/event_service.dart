import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';
import '../core/logger.dart';
import '../models/event_model.dart';
import '../models/user_model.dart';
import '../models/community_model.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger('EventService');

  // Check if user can view an event
  Future<bool> canViewEvent(String eventId, UserModel? user) async {
    try {
      if (user == null) return false;
      
      final eventDoc = await _firestore.collection('events').doc(eventId).get();
      if (!eventDoc.exists) return false;
      
      final event = EventModel.fromMap(eventDoc.data()!, eventDoc.id);
      
      // Public events can be viewed by anyone
      if (event.isPublic) return true;
      
      // Private events can only be viewed by community members
      final communityDoc = await _firestore.collection('communities').doc(event.communityId).get();
      if (!communityDoc.exists) return false;
      
      final community = CommunityModel.fromMap(communityDoc.data()!, communityDoc.id);
      return community.members.contains(user.id);
    } catch (e) {
      _logger.e('Error checking event view permission: $e');
      return false;
    }
  }

  // Check if user can create events in a community
  Future<bool> canCreateEvent(String communityId, UserModel? user) async {
    try {
      if (user == null) return false;
      
      // Anonymous users cannot create events
      if (user.role == 'anonymous') return false;
      
      final communityDoc = await _firestore.collection('communities').doc(communityId).get();
      if (!communityDoc.exists) return false;
      
      final community = CommunityModel.fromMap(communityDoc.data()!, communityDoc.id);
      
      // Only admins and business users can create events
      return user.role == 'admin' || user.role == 'business' || community.adminUid == user.id;
    } catch (e) {
      _logger.e('Error checking event creation permission: $e');
      return false;
    }
  }

  // Check if user can edit an event
  Future<bool> canEditEvent(String eventId, UserModel? user) async {
    try {
      if (user == null) return false;
      
      final eventDoc = await _firestore.collection('events').doc(eventId).get();
      if (!eventDoc.exists) return false;
      
      final event = EventModel.fromMap(eventDoc.data()!, eventDoc.id);
      
      // Event creator can always edit
      if (event.isCreator(user.id)) return true;
      
      // Admins and business users can edit
      if (user.role == 'admin' || user.role == 'business') return true;
      
      // Community admin can edit events in their community
      final communityDoc = await _firestore.collection('communities').doc(event.communityId).get();
      if (!communityDoc.exists) return false;
      
      final community = CommunityModel.fromMap(communityDoc.data()!, communityDoc.id);
      return community.adminUid == user.id;
    } catch (e) {
      _logger.e('Error checking event edit permission: $e');
      return false;
    }
  }

  // Check if user can delete an event
  Future<bool> canDeleteEvent(String eventId, UserModel? user) async {
    return await canEditEvent(eventId, user);
  }

  // Check if user can RSVP to an event
  Future<bool> canRsvpToEvent(String eventId, UserModel? user) async {
    try {
      if (user == null) return false;
      
      // Anonymous users cannot RSVP
      if (user.role == 'anonymous') return false;
      
      final eventDoc = await _firestore.collection('events').doc(eventId).get();
      if (!eventDoc.exists) return false;
      
      final event = EventModel.fromMap(eventDoc.data()!, eventDoc.id);
      
      // Public events can be RSVP'd by any authenticated user
      if (event.isPublic) return true;
      
      // Private events can only be RSVP'd by community members
      final communityDoc = await _firestore.collection('communities').doc(event.communityId).get();
      if (!communityDoc.exists) return false;
      
      final community = CommunityModel.fromMap(communityDoc.data()!, communityDoc.id);
      return community.members.contains(user.id);
    } catch (e) {
      _logger.e('Error checking RSVP permission: $e');
      return false;
    }
  }

  // Check if user can check in to an event
  Future<bool> canCheckInToEvent(String eventId, UserModel? user) async {
    try {
      if (user == null) return false;
      
      // Anonymous users cannot check in
      if (user.role == 'anonymous') return false;
      
      final eventDoc = await _firestore.collection('events').doc(eventId).get();
      if (!eventDoc.exists) return false;
      
      final event = EventModel.fromMap(eventDoc.data()!, eventDoc.id);
      
      // User must have RSVP'd to check in
      if (!event.isRsvped(user.id)) return false;
      
      // Public events can be checked in by any authenticated user who RSVP'd
      if (event.isPublic) return true;
      
      // Private events can only be checked in by community members who RSVP'd
      final communityDoc = await _firestore.collection('communities').doc(event.communityId).get();
      if (!communityDoc.exists) return false;
      
      final community = CommunityModel.fromMap(communityDoc.data()!, communityDoc.id);
      return community.members.contains(user.id);
    } catch (e) {
      _logger.e('Error checking check-in permission: $e');
      return false;
    }
  }

  // Get events that a user can view
  Future<List<EventModel>> getAccessibleEvents(UserModel? user) async {
    try {
      if (user == null) return [];
      
      List<EventModel> accessibleEvents = [];
      
      // Get public events
      final publicEventsQuery = await _firestore
          .collection('events')
          .where('visibility', isEqualTo: 'public')
          .orderBy('date', descending: true)
          .get();
      
      accessibleEvents.addAll(
        publicEventsQuery.docs.map((doc) => EventModel.fromMap(doc.data(), doc.id))
      );
      
      // Get private events from communities the user is a member of
      if (user.role != 'anonymous') {
        final userCommunitiesQuery = await _firestore
            .collection('communities')
            .where('members', arrayContains: user.id)
            .get();
        
        for (final communityDoc in userCommunitiesQuery.docs) {
          final privateEventsQuery = await _firestore
              .collection('events')
              .where('communityId', isEqualTo: communityDoc.id)
              .where('visibility', isEqualTo: 'private')
              .orderBy('date', descending: true)
              .get();
          
          accessibleEvents.addAll(
            privateEventsQuery.docs.map((doc) => EventModel.fromMap(doc.data(), doc.id))
          );
        }
      }
      
      // Remove duplicates and sort by date
      accessibleEvents = accessibleEvents.toSet().toList();
      accessibleEvents.sort((a, b) => b.date.compareTo(a.date));
      
      return accessibleEvents;
    } catch (e) {
      _logger.e('Error getting accessible events: $e');
      return [];
    }
  }

  // Get accessible events as a real-time stream
  Stream<List<EventModel>> getAccessibleEventsStream(UserModel user) {
    try {
      if (user == null) return Stream.value([]);
      
      // Get public events stream
      final publicEventsStream = _firestore
          .collection('events')
          .where('visibility', isEqualTo: 'public')
          .orderBy('date', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => EventModel.fromMap(doc.data(), doc.id)).toList());
      
      if (user.role == 'anonymous') {
        return publicEventsStream;
      }
      
      // Get private events from communities the user is a member of
      final userCommunitiesStream = _firestore
          .collection('communities')
          .where('members', arrayContains: user.id)
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
      
      return userCommunitiesStream.switchMap((communityIds) {
        if (communityIds.isEmpty) {
          return publicEventsStream;
        }
        
        // Get private events for each community
        final privateEventsStreams = communityIds.map((communityId) {
          return _firestore
              .collection('events')
              .where('communityId', isEqualTo: communityId)
              .where('visibility', isEqualTo: 'private')
              .orderBy('date', descending: true)
              .snapshots()
              .map((snapshot) => snapshot.docs.map((doc) => EventModel.fromMap(doc.data(), doc.id)).toList());
        });
        
        // Combine public and private events
        return Rx.combineLatest([publicEventsStream, ...privateEventsStreams], (List<List<EventModel>> lists) {
          List<EventModel> allEvents = [];
          for (final eventList in lists) {
            allEvents.addAll(eventList);
          }
          
          // Remove duplicates and sort by date
          allEvents = allEvents.toSet().toList();
          allEvents.sort((a, b) => b.date.compareTo(a.date));
          
          return allEvents;
        });
      });
    } catch (e) {
      _logger.e('Error getting accessible events stream: $e');
      return Stream.value([]);
    }
  }

  // Get events for a specific community
  Future<List<EventModel>> getCommunityEvents(String communityId, UserModel? user) async {
    try {
      // Check if community exists
      final communityDoc = await _firestore.collection('communities').doc(communityId).get();
      if (!communityDoc.exists) return [];
      
      final community = CommunityModel.fromMap(communityDoc.data()!, communityDoc.id);
      
      // If community is private, only members can see events
      if (community.visibility == 'private') {
        if (user == null) return [];
        if (!community.members.contains(user.id)) {
          return [];
        }
      }
      
      // Get all events for this community
      final eventsQuery = await _firestore
          .collection('events')
          .where('communityId', isEqualTo: communityId)
          .orderBy('date', descending: true)
          .get();
      
      return eventsQuery.docs.map((doc) => EventModel.fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      _logger.e('Error getting community events: $e');
      return [];
    }
  }

  // Get community events as a real-time stream
  Stream<List<EventModel>> getCommunityEventsStream(String communityId, UserModel user) {
    try {
      // Check if community exists and user has access
      return _firestore.collection('communities').doc(communityId).snapshots().switchMap((communityDoc) {
        if (!communityDoc.exists) return Stream.value([]);
        
        final community = CommunityModel.fromMap(communityDoc.data()!, communityDoc.id);
        
        // If community is private, only members can see events
        if (community.visibility == 'private') {
          if (user == null) return Stream.value([]);
          if (!community.members.contains(user.id)) {
            return Stream.value([]);
          }
        }
        
        // Get all events for this community as a stream
        return _firestore
            .collection('events')
            .where('communityId', isEqualTo: communityId)
            .orderBy('date', descending: true)
            .snapshots()
            .map((snapshot) => snapshot.docs.map((doc) => EventModel.fromMap(doc.data(), doc.id)).toList());
      });
    } catch (e) {
      _logger.e('Error getting community events stream: $e');
      return Stream.value([]);
    }
  }

  // Create event with proper access control
  Future<String?> createEvent(EventModel event, UserModel user) async {
    try {
      // Check if user can create events in this community
      if (!await canCreateEvent(event.communityId, user)) {
        throw Exception('Insufficient permissions to create event');
      }
      
      _logger.i('Creating event: ${event.title} by user: ${user.id}');
      
      final docRef = await _firestore.collection('events').add(event.toMap());
      
      // Update community event count
      await _firestore.collection('communities').doc(event.communityId).update({
        'metadata.event_count': FieldValue.increment(1),
        'metadata.last_activity': FieldValue.serverTimestamp(),
      });
      
      _logger.i('Event created successfully: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      _logger.e('Error creating event: $e');
      rethrow;
    }
  }

  // Update event with proper access control
  Future<void> updateEvent(EventModel event, UserModel user) async {
    try {
      // Check if user can edit this event
      if (!await canEditEvent(event.id, user)) {
        throw Exception('Insufficient permissions to edit event');
      }
      
      _logger.i('Updating event: ${event.title} by user: ${user.id}');
      
      await _firestore.collection('events').doc(event.id).update(event.toMap());
      
      _logger.i('Event updated successfully');
    } catch (e) {
      _logger.e('Error updating event: $e');
      rethrow;
    }
  }

  // Delete event with proper access control
  Future<void> deleteEvent(String eventId, UserModel user) async {
    try {
      // Check if user can delete this event
      if (!await canDeleteEvent(eventId, user)) {
        throw Exception('Insufficient permissions to delete event');
      }
      
      _logger.i('Deleting event: $eventId by user: ${user.id}');
      
      // Get the event to get communityId before deleting
      final eventDoc = await _firestore.collection('events').doc(eventId).get();
      if (!eventDoc.exists) {
        throw Exception('Event not found');
      }
      
      final event = EventModel.fromMap(eventDoc.data()!, eventId);
      
      // Delete the event
      await _firestore.collection('events').doc(eventId).delete();
      
      // Update community event count
      await _firestore.collection('communities').doc(event.communityId).update({
        'metadata.event_count': FieldValue.increment(-1),
      });
      
      _logger.i('Event deleted successfully');
    } catch (e) {
      _logger.e('Error deleting event: $e');
      rethrow;
    }
  }

  // Enhanced RSVP to event with multiple statuses and waitlist management
  Future<void> rsvpToEvent(String eventId, String status, UserModel user) async {
    try {
      // Check if user can RSVP to this event
      if (!await canRsvpToEvent(eventId, user)) {
        throw Exception('Insufficient permissions to RSVP to event');
      }
      
      _logger.i('User ${user.id} RSVPing to event $eventId with status: $status');
      
      final eventDoc = await _firestore.collection('events').doc(eventId).get();
      if (!eventDoc.exists) throw Exception('Event not found');
      
      EventModel event = EventModel.fromMap(eventDoc.data()!, eventDoc.id);
      
      // Handle RSVP removal
      if (status == 'remove') {
        final updatedEvent = event.removeRsvp(user.id);
        await _firestore.collection('events').doc(eventId).update(updatedEvent.toMap());
        
        // Remove reminder when RSVP is removed
        await _removeEventReminder(eventId, user.id);
        
        _logger.i('RSVP removed successfully');
        return;
      }
      
      // Validate status
      final validStatuses = [
        EventModel.rsvpGoing,
        EventModel.rsvpInterested,
        EventModel.rsvpNotGoing,
        EventModel.rsvpWaitlist,
      ];
      
      if (!validStatuses.contains(status)) {
        throw Exception('Invalid RSVP status: $status');
      }
      
      // Handle "going" status with spot limit logic
      if (status == EventModel.rsvpGoing) {
        if (event.hasSpotsLimit && event.isFull) {
          // Event is full, add to waitlist instead
          status = EventModel.rsvpWaitlist;
          _logger.i('Event is full, adding user to waitlist');
        }
      }
      
      // Update RSVP
      final updatedRsvps = Map<String, String>.from(event.rsvps);
      updatedRsvps[user.id] = status;
      
      // If user is going and event was full, try to promote someone from waitlist
      EventModel updatedEvent = event.copyWith(rsvps: updatedRsvps);
      
      if (status == EventModel.rsvpGoing && event.hasSpotsLimit) {
        // Check if we can promote someone from waitlist
        final waitlistUsers = event.waitlistUserIds;
        if (waitlistUsers.isNotEmpty && !updatedEvent.isFull) {
          // Promote the first person on waitlist
          final nextWaitlistUser = waitlistUsers.first;
          if (nextWaitlistUser != user.id) { // Don't promote the same user
            updatedEvent = updatedEvent.promoteFromWaitlist(nextWaitlistUser);
            _logger.i('Promoted user $nextWaitlistUser from waitlist');
          }
        }
      }
      
      await _firestore.collection('events').doc(eventId).update(updatedEvent.toMap());
      
      // Set up reminder for "going" status
      if (status == EventModel.rsvpGoing) {
        await _scheduleEventReminder(eventId, event, user);
      }
      
      _logger.i('RSVP updated successfully with status: $status');
    } catch (e) {
      _logger.e('Error updating RSVP: $e');
      rethrow;
    }
  }

  // Schedule event reminder for user
  Future<void> _scheduleEventReminder(String eventId, EventModel event, UserModel user) async {
    try {
      // Calculate reminder times
      final now = DateTime.now();
      final eventTime = event.date;
      final timeUntilEvent = eventTime.difference(now);
      
      // Don't schedule reminders for past events
      if (timeUntilEvent.isNegative) return;
      
      // Schedule reminders at different intervals
      final reminderIntervals = [
        const Duration(hours: 1),    // 1 hour before
        const Duration(hours: 24),   // 1 day before
        const Duration(days: 7),     // 1 week before
      ];
      
      for (final interval in reminderIntervals) {
        if (timeUntilEvent > interval) {
          final reminderTime = eventTime.subtract(interval);
          await _scheduleLocalReminder(eventId, event, user, reminderTime, interval);
        }
      }
      
      _logger.i('Event reminders scheduled for user ${user.id}');
    } catch (e) {
      _logger.e('Error scheduling event reminder: $e');
    }
  }

  // Schedule local reminder notification
  Future<void> _scheduleLocalReminder(
    String eventId,
    EventModel event,
    UserModel user,
    DateTime reminderTime,
    Duration interval,
  ) async {
    try {
      // Store reminder in Firestore for cross-device sync
      await _firestore.collection('event_reminders').add({
        'eventId': eventId,
        'userId': user.id,
        'eventTitle': event.title,
        'eventDate': event.date,
        'reminderTime': reminderTime,
        'interval': interval.inMinutes, // Store in minutes for easy comparison
        'sent': false,
        'createdAt': DateTime.now(),
      });
      
      _logger.i('Reminder scheduled for ${event.title} at ${reminderTime.toIso8601String()}');
    } catch (e) {
      _logger.e('Error scheduling local reminder: $e');
    }
  }

  // Remove event reminder for user
  Future<void> _removeEventReminder(String eventId, String userId) async {
    try {
      // Remove all reminders for this event and user
      final remindersQuery = await _firestore
          .collection('event_reminders')
          .where('eventId', isEqualTo: eventId)
          .where('userId', isEqualTo: userId)
          .get();
      
      for (final doc in remindersQuery.docs) {
        await doc.reference.delete();
      }
      
      _logger.i('Reminders removed for user $userId and event $eventId');
    } catch (e) {
      _logger.e('Error removing event reminders: $e');
    }
  }

  // Get user's RSVP status for an event
  Future<String?> getUserRsvpStatus(String eventId, String userId) async {
    try {
      final eventDoc = await _firestore.collection('events').doc(eventId).get();
      if (!eventDoc.exists) return null;
      
      final event = EventModel.fromMap(eventDoc.data()!, eventDoc.id);
      return event.getUserRsvpStatus(userId);
    } catch (e) {
      _logger.e('Error getting user RSVP status: $e');
      return null;
    }
  }

  // Get RSVP statistics for an event
  Future<Map<String, int>> getEventRsvpStats(String eventId) async {
    try {
      final eventDoc = await _firestore.collection('events').doc(eventId).get();
      if (!eventDoc.exists) return {};
      
      final event = EventModel.fromMap(eventDoc.data()!, eventDoc.id);
      
      return {
        'going': event.goingCount,
        'interested': event.interestedCount,
        'not_going': event.notGoingCount,
        'waitlist': event.waitlistCount,
        'total': event.rsvpCount,
      };
    } catch (e) {
      _logger.e('Error getting event RSVP stats: $e');
      return {};
    }
  }

  // Promote user from waitlist to confirmed (admin function)
  Future<void> promoteFromWaitlist(String eventId, String userId, UserModel admin) async {
    try {
      // Check if user can edit this event
      if (!await canEditEvent(eventId, admin)) {
        throw Exception('Insufficient permissions to manage event RSVPs');
      }
      
      final eventDoc = await _firestore.collection('events').doc(eventId).get();
      if (!eventDoc.exists) throw Exception('Event not found');
      
      final event = EventModel.fromMap(eventDoc.data()!, eventDoc.id);
      
      if (!event.isUserOnWaitlist(userId)) {
        throw Exception('User is not on waitlist');
      }
      
      if (event.isFull) {
        throw Exception('Event is full, cannot promote from waitlist');
      }
      
      final updatedEvent = event.promoteFromWaitlist(userId);
      await _firestore.collection('events').doc(eventId).update(updatedEvent.toMap());
      
      _logger.i('User $userId promoted from waitlist successfully');
    } catch (e) {
      _logger.e('Error promoting from waitlist: $e');
      rethrow;
    }
  }

  // Check in to event with proper access control
  Future<void> checkInToEvent(String eventId, UserModel user) async {
    try {
      // Check if user can check in to this event
      if (!await canCheckInToEvent(eventId, user)) {
        throw Exception('Insufficient permissions to check in to event');
      }
      
      _logger.i('User ${user.id} checking in to event $eventId');
      
      final eventDoc = await _firestore.collection('events').doc(eventId).get();
      if (!eventDoc.exists) throw Exception('Event not found');
      
      final event = EventModel.fromMap(eventDoc.data()!, eventDoc.id);
      final updatedCheckIns = Map<String, DateTime>.from(event.checkIns);
      updatedCheckIns[user.id] = DateTime.now();
      
      final updatedEvent = event.copyWith(checkIns: updatedCheckIns);
      await _firestore.collection('events').doc(eventId).update(updatedEvent.toMap());
      
      _logger.i('Check-in successful');
    } catch (e) {
      _logger.e('Error checking in: $e');
      rethrow;
    }
  }

  // Get user's upcoming events with RSVP status
  Future<List<Map<String, dynamic>>> getUserUpcomingEvents(String userId) async {
    try {
      final now = DateTime.now();
      
      // Get events where user has RSVPed
      final eventsQuery = await _firestore
          .collection('events')
          .where('date', isGreaterThan: now)
          .get();
      
      final userEvents = <Map<String, dynamic>>[];
      
      for (final doc in eventsQuery.docs) {
        final event = EventModel.fromMap(doc.data(), doc.id);
        final userRsvpStatus = event.getUserRsvpStatus(userId);
        
        if (userRsvpStatus != null) {
          userEvents.add({
            'event': event,
            'rsvpStatus': userRsvpStatus,
            'isCheckedIn': event.isCheckedIn(userId),
          });
        }
      }
      
      // Sort by event date
      userEvents.sort((a, b) => (a['event'] as EventModel).date.compareTo((b['event'] as EventModel).date));
      
      return userEvents;
    } catch (e) {
      _logger.e('Error getting user upcoming events: $e');
      return [];
    }
  }

  // Get event attendance statistics
  Future<Map<String, dynamic>> getEventAttendanceStats(String eventId) async {
    try {
      final eventDoc = await _firestore.collection('events').doc(eventId).get();
      if (!eventDoc.exists) return {};
      
      final event = EventModel.fromMap(eventDoc.data()!, eventDoc.id);
      
      // Get user details for attendees
      final attendeeIds = event.rsvps.keys.toList();
      final attendeeDetails = <Map<String, dynamic>>[];
      
      for (final userId in attendeeIds) {
        try {
          final userDoc = await _firestore.collection('users').doc(userId).get();
          if (userDoc.exists) {
            final userData = userDoc.data()!;
            attendeeDetails.add({
              'userId': userId,
              'name': userData['name'] ?? 'Unknown User',
              'email': userData['email'] ?? '',
              'rsvpStatus': event.rsvps[userId],
              'isCheckedIn': event.checkIns.containsKey(userId),
              'checkInTime': event.checkIns[userId],
            });
          }
        } catch (e) {
          _logger.e('Error getting user details for $userId: $e');
        }
      }
      
      return {
        'event': event,
        'totalRsvps': event.rsvpCount,
        'goingCount': event.goingCount,
        'interestedCount': event.interestedCount,
        'notGoingCount': event.notGoingCount,
        'waitlistCount': event.waitlistCount,
        'checkInCount': event.checkInCount,
        'attendeeDetails': attendeeDetails,
        'capacity': event.maxSpots,
        'isFull': event.isFull,
        'availableSpots': event.availableSpots,
      };
    } catch (e) {
      _logger.e('Error getting event attendance stats: $e');
      return {};
    }
  }

  // Send reminder notifications for upcoming events
  Future<void> sendEventReminders() async {
    try {
      final now = DateTime.now();
      final oneHourFromNow = now.add(const Duration(hours: 1));
      final oneDayFromNow = now.add(const Duration(days: 1));
      final oneWeekFromNow = now.add(const Duration(days: 7));
      
      // Get events happening soon
      final upcomingEventsQuery = await _firestore
          .collection('events')
          .where('date', isGreaterThan: now)
          .where('date', isLessThan: oneWeekFromNow)
          .get();
      
      for (final eventDoc in upcomingEventsQuery.docs) {
        final event = EventModel.fromMap(eventDoc.data(), eventDoc.id);
        
        // Send reminders to confirmed attendees
        for (final userId in event.confirmedUserIds) {
          final timeUntilEvent = event.date.difference(now);
          
          // Send reminder based on time until event
          if (timeUntilEvent.inHours <= 1) {
            await _sendReminderNotification(event, userId, '1 hour');
          } else if (timeUntilEvent.inDays <= 1) {
            await _sendReminderNotification(event, userId, '1 day');
          } else if (timeUntilEvent.inDays <= 7) {
            await _sendReminderNotification(event, userId, '1 week');
          }
        }
      }
      
      _logger.i('Event reminders sent successfully');
    } catch (e) {
      _logger.e('Error sending event reminders: $e');
    }
  }

  // Send reminder notification to user
  Future<void> _sendReminderNotification(EventModel event, String userId, String timeFrame) async {
    try {
      // Get user's FCM token
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return;
      
      final userData = userDoc.data()!;
      final fcmToken = userData['fcmToken'];
      
      if (fcmToken != null) {
        // Send push notification via Cloud Functions
        await _firestore.collection('notification_queue').add({
          'type': 'event_reminder',
          'userId': userId,
          'fcmToken': fcmToken,
          'title': 'Event Reminder',
          'body': '${event.title} starts in $timeFrame',
          'data': {
            'eventId': event.id,
            'navigation': '/event/${event.id}',
          },
          'createdAt': DateTime.now(),
        });
        
        _logger.i('Reminder notification queued for user $userId');
      }
    } catch (e) {
      _logger.e('Error sending reminder notification: $e');
    }
  }

  // Bulk RSVP operations for event organizers
  Future<void> bulkRsvpOperation(
    String eventId,
    List<String> userIds,
    String operation,
    UserModel organizer,
  ) async {
    try {
      // Check if user can manage this event
      if (!await canEditEvent(eventId, organizer)) {
        throw Exception('Insufficient permissions to manage event RSVPs');
      }
      
      final eventDoc = await _firestore.collection('events').doc(eventId).get();
      if (!eventDoc.exists) throw Exception('Event not found');
      
      EventModel event = EventModel.fromMap(eventDoc.data()!, eventDoc.id);
      
      switch (operation) {
        case 'confirm_all':
          // Confirm all waitlist users if spots available
          for (final userId in userIds) {
            if (event.isUserOnWaitlist(userId) && !event.isFull) {
              event = event.promoteFromWaitlist(userId);
            }
          }
          break;
          
        case 'remove_all':
          // Remove all specified users from RSVP
          for (final userId in userIds) {
            event = event.removeRsvp(userId);
            await _removeEventReminder(eventId, userId);
          }
          break;
          
        case 'check_in_all':
          // Check in all specified users
          final updatedCheckIns = Map<String, DateTime>.from(event.checkIns);
          for (final userId in userIds) {
            if (event.isRsvped(userId)) {
              updatedCheckIns[userId] = DateTime.now();
            }
          }
          event = event.copyWith(checkIns: updatedCheckIns);
          break;
          
        default:
          throw Exception('Invalid bulk operation: $operation');
      }
      
      await _firestore.collection('events').doc(eventId).update(event.toMap());
      
      _logger.i('Bulk RSVP operation completed: $operation for ${userIds.length} users');
    } catch (e) {
      _logger.e('Error performing bulk RSVP operation: $e');
      rethrow;
    }
  }
} 