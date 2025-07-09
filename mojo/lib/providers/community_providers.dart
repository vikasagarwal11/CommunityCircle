import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/community_service.dart';
import '../services/storage_service.dart';
import '../models/community_model.dart';
import '../models/user_model.dart';
import '../providers/auth_providers.dart';

// Community service provider
final communityServiceProvider = Provider<CommunityService>((ref) {
  return CommunityService();
});

// Storage service provider
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

// Public communities provider with pagination
final publicCommunitiesProvider = StreamProvider.family<List<CommunityModel>, Map<String, dynamic>>((ref, params) {
  final communityService = ref.watch(communityServiceProvider);
  final limit = params['limit'] as int? ?? 10;
  final lastDocument = params['lastDocument'] as DocumentSnapshot?;
  
  return communityService.getPublicCommunities(
    limit: limit,
    lastDocument: lastDocument,
  );
});

// User's communities provider
final userCommunitiesProvider = StreamProvider<List<CommunityModel>>((ref) {
  final communityService = ref.watch(communityServiceProvider);
  final userAsync = ref.watch(authNotifierProvider);
  
  return userAsync.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      return communityService.getUserCommunities(user.id);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

// User's owned communities provider
final ownedCommunitiesProvider = StreamProvider<List<CommunityModel>>((ref) {
  final communityService = ref.watch(communityServiceProvider);
  final userAsync = ref.watch(authNotifierProvider);
  
  return userAsync.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      return communityService.getOwnedCommunities(user.id);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

// Community details provider
final communityDetailsProvider = StreamProvider.family<CommunityModel?, String>((ref, communityId) {
  final communityService = ref.watch(communityServiceProvider);
  return communityService.getCommunityStream(communityId);
});

// Search communities provider
final searchCommunitiesProvider = StreamProvider.family<List<CommunityModel>, Map<String, dynamic>>((ref, params) {
  final communityService = ref.watch(communityServiceProvider);
  final query = params['query'] as String;
  final category = params['category'] as String?;
  final isBusiness = params['isBusiness'] as bool?;
  final limit = params['limit'] as int? ?? 20;
  
  if (query.isEmpty) return Stream.value([]);
  
  return communityService.searchCommunities(
    query: query,
    category: category,
    isBusiness: isBusiness,
    limit: limit,
  );
});

// Community statistics provider
final communityStatsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, communityId) async {
  final communityService = ref.watch(communityServiceProvider);
  return await communityService.getCommunityStats(communityId);
});

// Community members provider with real-time updates
final communityMembersProvider = StreamProvider.family<List<UserModel>, String>((ref, communityId) {
  final communityService = ref.watch(communityServiceProvider);
  return communityService.getCommunityMembersStream(communityId);
});

// Community banned users provider
final communityBannedUsersProvider = StreamProvider.family<List<UserModel>, String>((ref, communityId) {
  final communityService = ref.watch(communityServiceProvider);
  return communityService.getCommunityBannedUsersStream(communityId);
});

// Member search provider
final memberSearchProvider = StateProvider.family<String, String>((ref, communityId) => '');

// Filtered members provider
final filteredMembersProvider = Provider.family<List<UserModel>, String>((ref, communityId) {
  final membersAsync = ref.watch(communityMembersProvider(communityId));
  final searchQuery = ref.watch(memberSearchProvider(communityId));
  
  return membersAsync.when(
    data: (members) {
      if (searchQuery.isEmpty) return members;
      
      return members.where((member) {
        final query = searchQuery.toLowerCase();
        return member.displayName?.toLowerCase().contains(query) == true ||
               member.email?.toLowerCase().contains(query) == true ||
               member.phoneNumber.toLowerCase().contains(query);
      }).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// Selected members for bulk actions
final selectedMembersProvider = StateProvider.family<Set<String>, String>((ref, communityId) => {});

// Community actions notifier
class CommunityActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final CommunityService _communityService;
  final Ref _ref;

  CommunityActionsNotifier(this._communityService, this._ref) : super(const AsyncValue.data(null));

  Future<void> createCommunity({
    required String name,
    required String description,
    String? coverImage,
    required String visibility,
    bool approvalRequired = false,
    bool isBusiness = false,
    Map<String, String>? theme,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      await _communityService.createCommunity(
        name: name,
        description: description,
        coverImage: coverImage,
        visibility: visibility,
        approvalRequired: approvalRequired,
        isBusiness: isBusiness,
        theme: theme,
      );
      
      state = const AsyncValue.data(null);
      
      // Invalidate related providers
      _ref.invalidate(publicCommunitiesProvider);
      _ref.invalidate(userCommunitiesProvider);
      _ref.invalidate(ownedCommunitiesProvider);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> joinCommunity(String communityId) async {
    state = const AsyncValue.loading();
    
    try {
      await _communityService.joinCommunity(communityId);
      state = const AsyncValue.data(null);
      
      // Invalidate related providers
      _ref.invalidate(communityDetailsProvider(communityId));
      _ref.invalidate(userCommunitiesProvider);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> leaveCommunity(String communityId) async {
    state = const AsyncValue.loading();
    
    try {
      await _communityService.leaveCommunity(communityId);
      state = const AsyncValue.data(null);
      
      // Invalidate related providers
      _ref.invalidate(communityDetailsProvider(communityId));
      _ref.invalidate(userCommunitiesProvider);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> updateCommunity({
    required String communityId,
    String? name,
    String? description,
    String? coverImage,
    String? visibility,
    bool? approvalRequired,
    Map<String, String>? theme,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      await _communityService.updateCommunity(
        communityId: communityId,
        name: name,
        description: description,
        coverImage: coverImage,
        visibility: visibility,
        approvalRequired: approvalRequired,
        theme: theme,
      );
      
      state = const AsyncValue.data(null);
      
      // Invalidate related providers
      _ref.invalidate(communityDetailsProvider(communityId));
      _ref.invalidate(publicCommunitiesProvider);
      _ref.invalidate(userCommunitiesProvider);
      _ref.invalidate(ownedCommunitiesProvider);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> deleteCommunity(String communityId) async {
    state = const AsyncValue.loading();
    
    try {
      await _communityService.deleteCommunity(communityId);
      state = const AsyncValue.data(null);
      
      // Invalidate related providers
      _ref.invalidate(communityDetailsProvider(communityId));
      _ref.invalidate(publicCommunitiesProvider);
      _ref.invalidate(userCommunitiesProvider);
      _ref.invalidate(ownedCommunitiesProvider);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> banUser(String communityId, String userId) async {
    state = const AsyncValue.loading();
    
    try {
      await _communityService.banUser(communityId, userId);
      state = const AsyncValue.data(null);
      
      // Invalidate related providers
      _ref.invalidate(communityDetailsProvider(communityId));
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> unbanUser(String communityId, String userId) async {
    state = const AsyncValue.loading();
    
    try {
      await _communityService.unbanUser(communityId, userId);
      state = const AsyncValue.data(null);
      
      // Invalidate related providers
      _ref.invalidate(communityDetailsProvider(communityId));
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

// Community actions provider
final communityActionsProvider = StateNotifierProvider<CommunityActionsNotifier, AsyncValue<void>>((ref) {
  final communityService = ref.watch(communityServiceProvider);
  return CommunityActionsNotifier(communityService, ref);
});

// Search query provider
final searchQueryProvider = StateProvider<String>((ref) => '');

// Search filters provider
final searchFiltersProvider = StateProvider<Map<String, dynamic>>((ref) => {
  'category': null,
  'isBusiness': null,
  'limit': 20,
});

// Pagination provider for public communities
final paginationProvider = StateProvider<Map<String, dynamic>>((ref) => {
  'lastDocument': null,
  'hasMore': true,
  'loading': false,
});

// Community creation form provider
final communityFormProvider = StateProvider<Map<String, dynamic>>((ref) => {
  'name': '',
  'description': '',
  'coverImage': '',
  'visibility': 'public',
  'approvalRequired': false,
  'isBusiness': false,
  'theme': {'color': '#2196F3', 'banner_url': ''},
});

// Community form validation provider
final communityFormValidationProvider = Provider<Map<String, String>>((ref) {
  final form = ref.watch(communityFormProvider);
  final errors = <String, String>{};
  
  // Validate name
  if (form['name'].toString().trim().isEmpty) {
    errors['name'] = 'Community name is required';
  } else if (form['name'].toString().length < 3) {
    errors['name'] = 'Community name must be at least 3 characters';
  } else if (form['name'].toString().length > 50) {
    errors['name'] = 'Community name must be less than 50 characters';
  }
  
  // Validate description
  if (form['description'].toString().trim().isEmpty) {
    errors['description'] = 'Community description is required';
  } else if (form['description'].toString().length < 10) {
    errors['description'] = 'Description must be at least 10 characters';
  } else if (form['description'].toString().length > 500) {
    errors['description'] = 'Description must be less than 500 characters';
  }
  
  return errors;
});

// Community form is valid provider
final communityFormIsValidProvider = Provider<bool>((ref) {
  final errors = ref.watch(communityFormValidationProvider);
  return errors.isEmpty;
});

// Bulk actions notifier
class BulkActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final CommunityService _communityService;
  final Ref _ref;

  BulkActionsNotifier(this._communityService, this._ref) : super(const AsyncValue.data(null));

  Future<void> banSelectedMembers(String communityId, List<String> memberIds) async {
    state = const AsyncValue.loading();
    
    try {
      for (final memberId in memberIds) {
        await _communityService.banUser(communityId, memberId);
      }
      
      state = const AsyncValue.data(null);
      
      // Clear selection
      _ref.read(selectedMembersProvider(communityId).notifier).state = {};
      
      // Invalidate related providers
      _ref.invalidate(communityMembersProvider(communityId));
      _ref.invalidate(communityBannedUsersProvider(communityId));
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> removeSelectedMembers(String communityId, List<String> memberIds) async {
    state = const AsyncValue.loading();
    
    try {
      for (final memberId in memberIds) {
        await _communityService.removeMember(communityId, memberId);
      }
      
      state = const AsyncValue.data(null);
      
      // Clear selection
      _ref.read(selectedMembersProvider(communityId).notifier).state = {};
      
      // Invalidate related providers
      _ref.invalidate(communityMembersProvider(communityId));
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> sendBulkInvitations(String communityId, List<String> emails) async {
    state = const AsyncValue.loading();
    
    try {
      await _communityService.sendBulkInvitations(communityId, emails);
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

// Bulk actions provider
final bulkActionsProvider = StateNotifierProvider.family<BulkActionsNotifier, AsyncValue<void>, String>((ref, communityId) {
  final communityService = ref.watch(communityServiceProvider);
  return BulkActionsNotifier(communityService, ref);
});

// Notification settings provider
final notificationSettingsProvider = StateProvider<Map<String, bool>>((ref) => {
  'member_joined': true,
  'member_left': true,
  'new_message': true,
  'new_event': true,
  'reported_content': true,
  'community_updates': true,
});

// Advanced analytics provider
final advancedAnalyticsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, communityId) async {
  final communityService = ref.watch(communityServiceProvider);
  return await communityService.getAdvancedAnalytics(communityId);
});

// Community membership provider
final communityMembershipProvider = StreamProvider.family<String, String>((ref, communityId) {
  final userAsync = ref.watch(authNotifierProvider);
  final communityService = ref.watch(communityServiceProvider);
  
  return userAsync.when(
    data: (user) {
      if (user == null) return Stream.value('none');
      
      return communityService.getCommunityStream(communityId).map((community) {
        if (community == null) return 'none';
        
        if (community.adminUid == user.id) return 'admin';
        if (community.members.contains(user.id)) return 'member';
        if (community.bannedUsers.contains(user.id)) return 'banned';
        return 'none';
      });
    },
    loading: () => Stream.value('none'),
    error: (_, __) => Stream.value('none'),
  );
}); 