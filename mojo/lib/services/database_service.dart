import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import '../models/user_model.dart';
import '../models/community_model.dart';
import '../models/event_model.dart';
import '../models/message_model.dart';
import '../models/moment_model.dart';
import '../models/poll_model.dart';
import '../models/challenge_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();

  // Collections
  CollectionReference get _users => _firestore.collection('users');
  CollectionReference get _communities => _firestore.collection('communities');
  CollectionReference get _events => _firestore.collection('events');
  CollectionReference get _messages => _firestore.collection('messages');
  CollectionReference get _moments => _firestore.collection('moments');
  CollectionReference get _polls => _firestore.collection('polls');
  CollectionReference get _challenges => _firestore.collection('challenges');

  // User Operations
  Future<UserModel?> getUser(String userId) async {
    try {
      _logger.d('Fetching user: $userId');
      final doc = await _users.doc(userId).get();
      if (doc.exists) {
        final user = UserModel.fromMap(doc.data() as Map<String, dynamic>);
        _logger.i('User fetched successfully: ${user.displayName}');
        return user;
      }
      _logger.w('User not found: $userId');
      return null;
    } catch (e) {
      _logger.e('Error fetching user: $e');
      rethrow;
    }
  }

  Future<void> createUser(UserModel user) async {
    try {
      _logger.d('Creating user: ${user.displayName}');
      await _users.doc(user.id).set(user.toMap());
      _logger.i('User created successfully: ${user.displayName}');
    } catch (e) {
      _logger.e('Error creating user: $e');
      rethrow;
    }
  }

  Future<void> updateUser(UserModel user) async {
    try {
      _logger.d('Updating user: ${user.displayName}');
      await _users.doc(user.id).update(user.toMap());
      _logger.i('User updated successfully: ${user.displayName}');
    } catch (e) {
      _logger.e('Error updating user: $e');
      rethrow;
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      _logger.d('Deleting user: $userId');
      await _users.doc(userId).delete();
      _logger.i('User deleted successfully: $userId');
    } catch (e) {
      _logger.e('Error deleting user: $e');
      rethrow;
    }
  }

  // Community Operations
  Future<CommunityModel?> getCommunity(String communityId) async {
    try {
      _logger.d('Fetching community: $communityId');
      final doc = await _communities.doc(communityId).get();
      if (doc.exists) {
        final community = CommunityModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
        _logger.i('Community fetched successfully: ${community.name}');
        return community;
      }
      _logger.w('Community not found: $communityId');
      return null;
    } catch (e) {
      _logger.e('Error fetching community: $e');
      rethrow;
    }
  }

  Future<String> createCommunity(CommunityModel community) async {
    try {
      _logger.d('Creating community: ${community.name}');
      final docRef = await _communities.add(community.toMap());
      _logger.i('Community created successfully: ${community.name} with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      _logger.e('Error creating community: $e');
      rethrow;
    }
  }

  Future<void> updateCommunity(CommunityModel community) async {
    try {
      _logger.d('Updating community: ${community.name}');
      await _communities.doc(community.id).update(community.toMap());
      _logger.i('Community updated successfully: ${community.name}');
    } catch (e) {
      _logger.e('Error updating community: $e');
      rethrow;
    }
  }

  Future<void> deleteCommunity(String communityId) async {
    try {
      _logger.d('Deleting community: $communityId');
      await _communities.doc(communityId).delete();
      _logger.i('Community deleted successfully: $communityId');
    } catch (e) {
      _logger.e('Error deleting community: $e');
      rethrow;
    }
  }

  // Event Operations
  Future<EventModel?> getEvent(String eventId) async {
    try {
      _logger.d('Fetching event: $eventId');
      final doc = await _events.doc(eventId).get();
      if (doc.exists) {
        final event = EventModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
        _logger.i('Event fetched successfully: ${event.title}');
        return event;
      }
      _logger.w('Event not found: $eventId');
      return null;
    } catch (e) {
      _logger.e('Error fetching event: $e');
      rethrow;
    }
  }

  Future<String> createEvent(EventModel event) async {
    try {
      _logger.d('Creating event: ${event.title}');
      final docRef = await _events.add(event.toMap());
      _logger.i('Event created successfully: ${event.title} with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      _logger.e('Error creating event: $e');
      rethrow;
    }
  }

  Future<void> updateEvent(EventModel event) async {
    try {
      _logger.d('Updating event: ${event.title}');
      await _events.doc(event.id).update(event.toMap());
      _logger.i('Event updated successfully: ${event.title}');
    } catch (e) {
      _logger.e('Error updating event: $e');
      rethrow;
    }
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      _logger.d('Deleting event: $eventId');
      await _events.doc(eventId).delete();
      _logger.i('Event deleted successfully: $eventId');
    } catch (e) {
      _logger.e('Error deleting event: $e');
      rethrow;
    }
  }

  // Message Operations
  Future<MessageModel?> getMessage(String messageId) async {
    try {
      _logger.d('Fetching message: $messageId');
      final doc = await _messages.doc(messageId).get();
      if (doc.exists) {
        final message = MessageModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
        _logger.i('Message fetched successfully');
        return message;
      }
      _logger.w('Message not found: $messageId');
      return null;
    } catch (e) {
      _logger.e('Error fetching message: $e');
      rethrow;
    }
  }

  Future<String> createMessage(MessageModel message) async {
    try {
      _logger.d('Creating message');
      final docRef = await _messages.add(message.toMap());
      _logger.i('Message created successfully with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      _logger.e('Error creating message: $e');
      rethrow;
    }
  }

  Future<void> updateMessage(MessageModel message) async {
    try {
      _logger.d('Updating message: ${message.id}');
      await _messages.doc(message.id).update(message.toMap());
      _logger.i('Message updated successfully');
    } catch (e) {
      _logger.e('Error updating message: $e');
      rethrow;
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      _logger.d('Deleting message: $messageId');
      await _messages.doc(messageId).delete();
      _logger.i('Message deleted successfully: $messageId');
    } catch (e) {
      _logger.e('Error deleting message: $e');
      rethrow;
    }
  }

  // Moment Operations
  Future<MomentModel?> getMoment(String momentId) async {
    try {
      _logger.d('Fetching moment: $momentId');
      final doc = await _moments.doc(momentId).get();
      if (doc.exists) {
        final moment = MomentModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
        _logger.i('Moment fetched successfully');
        return moment;
      }
      _logger.w('Moment not found: $momentId');
      return null;
    } catch (e) {
      _logger.e('Error fetching moment: $e');
      rethrow;
    }
  }

  Future<String> createMoment(MomentModel moment) async {
    try {
      _logger.d('Creating moment');
      final docRef = await _moments.add(moment.toMap());
      _logger.i('Moment created successfully with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      _logger.e('Error creating moment: $e');
      rethrow;
    }
  }

  Future<void> updateMoment(MomentModel moment) async {
    try {
      _logger.d('Updating moment: ${moment.id}');
      await _moments.doc(moment.id).update(moment.toMap());
      _logger.i('Moment updated successfully');
    } catch (e) {
      _logger.e('Error updating moment: $e');
      rethrow;
    }
  }

  Future<void> deleteMoment(String momentId) async {
    try {
      _logger.d('Deleting moment: $momentId');
      await _moments.doc(momentId).delete();
      _logger.i('Moment deleted successfully: $momentId');
    } catch (e) {
      _logger.e('Error deleting moment: $e');
      rethrow;
    }
  }

  // Poll Operations
  Future<PollModel?> getPoll(String pollId) async {
    try {
      _logger.d('Fetching poll: $pollId');
      final doc = await _polls.doc(pollId).get();
      if (doc.exists) {
        final poll = PollModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
        _logger.i('Poll fetched successfully: ${poll.question}');
        return poll;
      }
      _logger.w('Poll not found: $pollId');
      return null;
    } catch (e) {
      _logger.e('Error fetching poll: $e');
      rethrow;
    }
  }

  Future<String> createPoll(PollModel poll) async {
    try {
      _logger.d('Creating poll: ${poll.question}');
      final docRef = await _polls.add(poll.toMap());
      _logger.i('Poll created successfully: ${poll.question} with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      _logger.e('Error creating poll: $e');
      rethrow;
    }
  }

  Future<void> updatePoll(PollModel poll) async {
    try {
      _logger.d('Updating poll: ${poll.question}');
      await _polls.doc(poll.id).update(poll.toMap());
      _logger.i('Poll updated successfully: ${poll.question}');
    } catch (e) {
      _logger.e('Error updating poll: $e');
      rethrow;
    }
  }

  Future<void> deletePoll(String pollId) async {
    try {
      _logger.d('Deleting poll: $pollId');
      await _polls.doc(pollId).delete();
      _logger.i('Poll deleted successfully: $pollId');
    } catch (e) {
      _logger.e('Error deleting poll: $e');
      rethrow;
    }
  }

  // Challenge Operations
  Future<ChallengeModel?> getChallenge(String challengeId) async {
    try {
      _logger.d('Fetching challenge: $challengeId');
      final doc = await _challenges.doc(challengeId).get();
      if (doc.exists) {
        final challenge = ChallengeModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
        _logger.i('Challenge fetched successfully: ${challenge.title}');
        return challenge;
      }
      _logger.w('Challenge not found: $challengeId');
      return null;
    } catch (e) {
      _logger.e('Error fetching challenge: $e');
      rethrow;
    }
  }

  Future<String> createChallenge(ChallengeModel challenge) async {
    try {
      _logger.d('Creating challenge: ${challenge.title}');
      final docRef = await _challenges.add(challenge.toMap());
      _logger.i('Challenge created successfully: ${challenge.title} with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      _logger.e('Error creating challenge: $e');
      rethrow;
    }
  }

  Future<void> updateChallenge(ChallengeModel challenge) async {
    try {
      _logger.d('Updating challenge: ${challenge.title}');
      await _challenges.doc(challenge.id).update(challenge.toMap());
      _logger.i('Challenge updated successfully: ${challenge.title}');
    } catch (e) {
      _logger.e('Error updating challenge: $e');
      rethrow;
    }
  }

  Future<void> deleteChallenge(String challengeId) async {
    try {
      _logger.d('Deleting challenge: $challengeId');
      await _challenges.doc(challengeId).delete();
      _logger.i('Challenge deleted successfully: $challengeId');
    } catch (e) {
      _logger.e('Error deleting challenge: $e');
      rethrow;
    }
  }

  // Batch Operations
  Future<void> batchWrite(List<Map<String, dynamic>> operations) async {
    try {
      _logger.d('Executing batch write with ${operations.length} operations');
      final batch = _firestore.batch();
      
      for (final operation in operations) {
        final collection = operation['collection'] as String;
        final docId = operation['docId'] as String?;
        final data = operation['data'] as Map<String, dynamic>;
        final action = operation['action'] as String;

        final docRef = _firestore.collection(collection).doc(docId ?? '');
        
        switch (action) {
          case 'set':
            batch.set(docRef, data);
            break;
          case 'update':
            batch.update(docRef, data);
            break;
          case 'delete':
            batch.delete(docRef);
            break;
        }
      }

      await batch.commit();
      _logger.i('Batch write completed successfully');
    } catch (e) {
      _logger.e('Error executing batch write: $e');
      rethrow;
    }
  }

  // Transaction Operations
  Future<T> runTransaction<T>(Future<T> Function(Transaction) transaction) async {
    try {
      _logger.d('Starting transaction');
      final result = await _firestore.runTransaction(transaction);
      _logger.i('Transaction completed successfully');
      return result;
    } catch (e) {
      _logger.e('Error in transaction: $e');
      rethrow;
    }
  }

  // FCM Token Management
  Future<void> updateUserFCMToken(String userId, String? token) async {
    try {
      _logger.d('Updating FCM token for user: $userId');
      await _users.doc(userId).update({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });
      _logger.i('FCM token updated successfully for user: $userId');
    } catch (e) {
      _logger.e('Error updating FCM token: $e');
      rethrow;
    }
  }

  Future<List<String>> getFCMTokensForUsers(List<String> userIds) async {
    try {
      _logger.d('Fetching FCM tokens for ${userIds.length} users');
      final query = await _users
          .where(FieldPath.documentId, whereIn: userIds)
          .where('fcmToken', isNotEqualTo: null)
          .get();
      
      final tokens = query.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['fcmToken'] as String?)
          .where((token) => token != null && token.isNotEmpty)
          .cast<String>()
          .toList();
      
      _logger.i('Fetched ${tokens.length} FCM tokens');
      return tokens;
    } catch (e) {
      _logger.e('Error fetching FCM tokens: $e');
      rethrow;
    }
  }

  Future<List<String>> getFCMTokensForCommunityMembers(String communityId) async {
    try {
      _logger.d('Fetching FCM tokens for community members: $communityId');
      final community = await getCommunity(communityId);
      if (community == null) {
        _logger.w('Community not found: $communityId');
        return [];
      }

      final tokens = await getFCMTokensForUsers(community.members);
      _logger.i('Fetched ${tokens.length} FCM tokens for community members');
      return tokens;
    } catch (e) {
      _logger.e('Error fetching FCM tokens for community members: $e');
      rethrow;
    }
  }

  // Get current user (helper method for notification service)
  Future<UserModel?> getCurrentUser() async {
    try {
      final auth = FirebaseAuth.instance;
      if (auth.currentUser != null) {
        return await getUser(auth.currentUser!.uid);
      }
      return null;
    } catch (e) {
      _logger.e('Error getting current user: $e');
      return null;
    }
  }
} 