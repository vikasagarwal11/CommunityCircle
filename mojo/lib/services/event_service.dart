import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  // Get events for a specific community
  Future<List<EventModel>> getCommunityEvents(String communityId, UserModel? user) async {
    try {
      if (user == null) return [];
      
      // Check if user can access this community
      final communityDoc = await _firestore.collection('communities').doc(communityId).get();
      if (!communityDoc.exists) return [];
      
      final community = CommunityModel.fromMap(communityDoc.data()!, communityDoc.id);
      
      // If community is private, only members can see events
      if (community.visibility == 'private' && !community.members.contains(user.id)) {
        return [];
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

  // Create event with proper access control
  Future<String?> createEvent(EventModel event, UserModel user) async {
    try {
      // Check if user can create events in this community
      if (!await canCreateEvent(event.communityId, user)) {
        throw Exception('Insufficient permissions to create event');
      }
      
      _logger.i('Creating event: ${event.title} by user: ${user.id}');
      
      final docRef = await _firestore.collection('events').add(event.toMap());
      
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
      
      await _firestore.collection('events').doc(eventId).delete();
      
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
      
      _logger.i('RSVP updated successfully with status: $status');
    } catch (e) {
      _logger.e('Error updating RSVP: $e');
      rethrow;
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
} 