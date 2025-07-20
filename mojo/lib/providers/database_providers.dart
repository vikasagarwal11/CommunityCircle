import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_service.dart';
import '../services/community_service.dart';
import '../services/event_service.dart';
import '../models/user_model.dart';
import '../models/community_model.dart';
import '../models/event_model.dart';
import '../models/message_model.dart';
import '../models/moment_model.dart';
import '../models/poll_model.dart';
import '../models/challenge_model.dart';
import 'auth_providers.dart';

// Database Service Provider
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

// Community Service Provider
final communityServiceProvider = Provider<CommunityService>((ref) {
  return CommunityService();
});

// Event Service Provider
final eventServiceProvider = Provider<EventService>((ref) {
  return EventService();
});

// User Providers
final userProvider = FutureProvider.family<UserModel?, String>((ref, userId) async {
  final databaseService = ref.watch(databaseServiceProvider);
  return await databaseService.getUser(userId);
});

// All users provider
final usersProvider = StreamProvider<List<UserModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('users')
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id; // Add the document ID to the data
          return UserModel.fromMap(data);
        }).toList();
      });
});

// Community Providers
final communityProvider = FutureProvider.family<CommunityModel?, String>((ref, communityId) async {
  final databaseService = ref.watch(databaseServiceProvider);
  return await databaseService.getCommunity(communityId);
});

// Business communities provider - create a method for this
final businessCommunitiesProvider = StreamProvider<List<CommunityModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('communities')
      .where('is_business', isEqualTo: true)
      .where('visibility', isEqualTo: 'public')
      .orderBy('created_at', descending: true)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) {
          return CommunityModel.fromMap(doc.data(), doc.id);
        }).toList();
      });
});

// Search communities provider
final searchCommunitiesProvider = StreamProvider.family<List<CommunityModel>, String>((ref, query) {
  final communityService = ref.watch(communityServiceProvider);
  return communityService.searchCommunities(query: query);
});

// Event Providers
final eventProvider = FutureProvider.family<EventModel?, String>((ref, eventId) async {
  final databaseService = ref.watch(databaseServiceProvider);
  return await databaseService.getEvent(eventId);
});

// Community events provider with real-time updates
final communityEventsProvider = FutureProvider.family<List<EventModel>, String>((ref, communityId) async {
  final eventService = ref.watch(eventServiceProvider);
  final currentUser = ref.watch(currentUserProvider).value;
  
  if (currentUser == null) return [];
  return await eventService.getCommunityEvents(communityId, currentUser);
});

// Accessible events provider with real-time updates
final accessibleEventsProvider = FutureProvider<List<EventModel>>((ref) async {
  final eventService = ref.watch(eventServiceProvider);
  final currentUser = ref.watch(currentUserProvider).value;
  
  if (currentUser == null) return [];
  return await eventService.getAccessibleEvents(currentUser);
});

final upcomingEventsProvider = FutureProvider.family<List<EventModel>, String>((ref, communityId) async {
  final querySnapshot = await FirebaseFirestore.instance
      .collection('events')
      .where('communityId', isEqualTo: communityId)
      .where('date', isGreaterThan: DateTime.now())
      .orderBy('date', descending: false)
      .get();

  return querySnapshot.docs.map((doc) {
    return EventModel.fromMap(
      doc.data(),
      doc.id,
    );
  }).toList();
});

// Message Providers
final messageProvider = FutureProvider.family<MessageModel?, String>((ref, messageId) async {
  final databaseService = ref.watch(databaseServiceProvider);
  return await databaseService.getMessage(messageId);
});

final communityMessagesProvider = StreamProvider.family<List<MessageModel>, String>((ref, communityId) {
  return FirebaseFirestore.instance
      .collection('messages')
      .where('communityId', isEqualTo: communityId)
      .orderBy('timestamp', descending: true)
      .limit(50)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) {
          return MessageModel.fromMap(
            doc.data(),
            doc.id,
          );
        }).toList();
      });
});

// Moment Providers
final momentProvider = FutureProvider.family<MomentModel?, String>((ref, momentId) async {
  final databaseService = ref.watch(databaseServiceProvider);
  return await databaseService.getMoment(momentId);
});

final communityMomentsProvider = StreamProvider.family<List<MomentModel>, String>((ref, communityId) {
  return FirebaseFirestore.instance
      .collection('moments')
      .where('communityId', isEqualTo: communityId)
      .where('expiresAt', isGreaterThan: DateTime.now())
      .orderBy('expiresAt', descending: true)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) {
          return MomentModel.fromMap(
            doc.data(),
            doc.id,
          );
        }).toList();
      });
});

// Poll Providers
final pollProvider = FutureProvider.family<PollModel?, String>((ref, pollId) async {
  final databaseService = ref.watch(databaseServiceProvider);
  return await databaseService.getPoll(pollId);
});

final communityPollsProvider = FutureProvider.family<List<PollModel>, String>((ref, communityId) async {
  final querySnapshot = await FirebaseFirestore.instance
      .collection('polls')
      .where('communityId', isEqualTo: communityId)
      .where('isActive', isEqualTo: true)
      .orderBy('createdAt', descending: true)
      .get();

  return querySnapshot.docs.map((doc) {
    return PollModel.fromMap(
      doc.data(),
      doc.id,
    );
  }).toList();
});

// Challenge Providers
final challengeProvider = FutureProvider.family<ChallengeModel?, String>((ref, challengeId) async {
  final databaseService = ref.watch(databaseServiceProvider);
  return await databaseService.getChallenge(challengeId);
});

final communityChallengesProvider = FutureProvider.family<List<ChallengeModel>, String>((ref, communityId) async {
  final querySnapshot = await FirebaseFirestore.instance
      .collection('challenges')
      .where('communityId', isEqualTo: communityId)
      .where('isActive', isEqualTo: true)
      .orderBy('startDate', descending: true)
      .get();

  return querySnapshot.docs.map((doc) {
    return ChallengeModel.fromMap(
      doc.data(),
      doc.id,
    );
  }).toList();
});

// Active Challenges Provider
final activeChallengesProvider = FutureProvider.family<List<ChallengeModel>, String>((ref, communityId) async {
  final querySnapshot = await FirebaseFirestore.instance
      .collection('challenges')
      .where('communityId', isEqualTo: communityId)
      .where('isActive', isEqualTo: true)
      .where('startDate', isLessThanOrEqualTo: DateTime.now())
      .where('endDate', isGreaterThan: DateTime.now())
      .orderBy('endDate', descending: false)
      .get();

  return querySnapshot.docs.map((doc) {
    return ChallengeModel.fromMap(
      doc.data(),
      doc.id,
    );
  }).toList();
});

// Community Stats Provider
final communityStatsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, communityId) async {
  final communityService = ref.watch(communityServiceProvider);
  return await communityService.getCommunityStats(communityId);
});

// Notifiers for State Management
class CommunityNotifier extends StateNotifier<AsyncValue<List<CommunityModel>>> {
  final CommunityService _communityService;

  CommunityNotifier(this._communityService) : super(const AsyncValue.loading());

  Future<void> loadPublicCommunities() async {
    state = const AsyncValue.loading();
    try {
      final communitiesStream = _communityService.getPublicCommunities();
      final communities = await communitiesStream.first;
      state = AsyncValue.data(communities);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> loadUserCommunities(String userId) async {
    state = const AsyncValue.loading();
    try {
      final communitiesStream = _communityService.getUserCommunities(userId);
      final communities = await communitiesStream.first;
      state = AsyncValue.data(communities);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> searchCommunities(String query) async {
    state = const AsyncValue.loading();
    try {
      final communitiesStream = _communityService.searchCommunities(query: query);
      final communities = await communitiesStream.first;
      state = AsyncValue.data(communities);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final communityNotifierProvider = StateNotifierProvider<CommunityNotifier, AsyncValue<List<CommunityModel>>>((ref) {
  final communityService = ref.watch(communityServiceProvider);
  return CommunityNotifier(communityService);
});

// User Notifier
class UserNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final DatabaseService _databaseService;

  UserNotifier(this._databaseService) : super(const AsyncValue.loading());

  Future<void> loadUser(String userId) async {
    state = const AsyncValue.loading();
    try {
      final user = await _databaseService.getUser(userId);
      state = AsyncValue.data(user);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateUser(UserModel user) async {
    try {
      await _databaseService.updateUser(user);
      state = AsyncValue.data(user);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final userNotifierProvider = StateNotifierProvider.family<UserNotifier, AsyncValue<UserModel?>, String>((ref, userId) {
  final databaseService = ref.watch(databaseServiceProvider);
  return UserNotifier(databaseService);
}); 