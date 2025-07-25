import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/community_service.dart';
import '../services/storage_service.dart';
import '../models/community_model.dart';
import '../models/user_model.dart';
import '../providers/auth_providers.dart';
import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityQueryParams extends Equatable {
  final int limit;
  const CommunityQueryParams({required this.limit});
  @override
  List<Object?> get props => [limit];
}

class CommunitySearchParams extends Equatable {
  final String query;
  final String? category;
  final bool? isBusiness;
  final int limit;

  const CommunitySearchParams({
    required this.query,
    this.category,
    this.isBusiness,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [query, category, isBusiness, limit];
}

// Enhanced pagination state for communities
class PaginatedCommunitiesState {
  final List<CommunityModel> communities;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final bool isRefreshing;

  const PaginatedCommunitiesState({
    this.communities = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.isRefreshing = false,
  });

  PaginatedCommunitiesState copyWith({
    List<CommunityModel>? communities,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    bool? isRefreshing,
  }) {
    return PaginatedCommunitiesState(
      communities: communities ?? this.communities,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error ?? this.error,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

// Paginated communities notifier for infinite scrolling
class PaginatedCommunitiesNotifier extends StateNotifier<PaginatedCommunitiesState> {
  final CommunityService _communityService;
  static const int _pageSize = 20; // Batch size
  DocumentSnapshot? _lastDocument;

  PaginatedCommunitiesNotifier(this._communityService) : super(const PaginatedCommunitiesState());

  Future<void> loadInitial() async {
    if (state.isLoading) return;
    
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final communities = await _communityService.getPublicCommunitiesPaginated(
        limit: _pageSize,
        lastDocument: null,
      );
      
      if (communities.isNotEmpty) {
        final lastCommunity = communities.last;
        final lastDoc = await _communityService.getCommunityDocument(lastCommunity.id);
        _lastDocument = lastDoc;
      }
      
      final hasMore = communities.length == _pageSize;
      
      state = state.copyWith(
        communities: communities,
        isLoading: false,
        hasMore: hasMore,
      );
      print('Initial communities loaded: ${communities.length} (hasMore: $hasMore)'); // Debug print
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore || state.isLoading) return;
    
    state = state.copyWith(isLoadingMore: true);
    
    try {
      final newCommunities = await _communityService.getPublicCommunitiesPaginated(
        limit: _pageSize,
        lastDocument: _lastDocument,
      );
      
      if (newCommunities.isNotEmpty) {
        final allCommunities = [...state.communities, ...newCommunities];
        
        final lastCommunity = newCommunities.last;
        final lastDoc = await _communityService.getCommunityDocument(lastCommunity.id);
        _lastDocument = lastDoc;
        
        final hasMore = newCommunities.length == _pageSize;
        
        state = state.copyWith(
          communities: allCommunities,
          hasMore: hasMore,
          isLoadingMore: false,
        );
        print('Loaded more communities: ${newCommunities.length} (total: ${allCommunities.length}, hasMore: $hasMore)'); // Debug print
      } else {
        state = state.copyWith(hasMore: false, isLoadingMore: false);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoadingMore: false);
    }
  }

  Future<void> refresh() async {
    _lastDocument = null;
    state = state.copyWith(isRefreshing: true, error: null);
    
    try {
      final communities = await _communityService.getPublicCommunitiesPaginated(
        limit: _pageSize,
        lastDocument: null,
      );
      
      if (communities.isNotEmpty) {
        final lastCommunity = communities.last;
        final lastDoc = await _communityService.getCommunityDocument(lastCommunity.id);
        _lastDocument = lastDoc;
      }
      
      final hasMore = communities.length == _pageSize;
      
      state = state.copyWith(
        communities: communities,
        isRefreshing: false,
        hasMore: hasMore,
      );
    } catch (e) {
      state = state.copyWith(
        isRefreshing: false,
        error: e.toString(),
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider for paginated communities (added autoDispose for performance)
final paginatedCommunitiesProvider = StateNotifierProvider.autoDispose<PaginatedCommunitiesNotifier, PaginatedCommunitiesState>((ref) {
  final communityService = ref.watch(communityServiceProvider);
  return PaginatedCommunitiesNotifier(communityService);
});

// Community service provider
final communityServiceProvider = Provider<CommunityService>((ref) {
  return CommunityService();
});

// Storage service provider
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

// Public communities provider with pagination
final publicCommunitiesProvider = StreamProvider.autoDispose.family<List<CommunityModel>, CommunityQueryParams>((ref, params) {
  final communityService = ref.watch(communityServiceProvider);
  return communityService.getPublicCommunities(
    limit: params.limit,
  );
});

// User's communities provider
final userCommunitiesProvider = StreamProvider.autoDispose<List<CommunityModel>>((ref) {
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
final ownedCommunitiesProvider = StreamProvider.autoDispose<List<CommunityModel>>((ref) {
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

// Enhanced personalization: Recommended communities provider
final recommendedCommunitiesProvider = FutureProvider.autoDispose<List<CommunityModel>>((ref) async {
  final userAsync = ref.watch(authNotifierProvider);
  final communityService = ref.watch(communityServiceProvider);
  
  return userAsync.when(
    data: (user) async {
      if (user == null) return [];
      
      try {
        // Get user's joined communities to understand their interests
        final userCommunities = await ref.read(userCommunitiesProvider.future);
        
        // Extract tags from user's communities to understand preferences
        final userTags = <String>{};
        for (final community in userCommunities) {
          userTags.addAll(community.tags);
        }
        
        // If user has no communities or tags, return popular communities
        if (userTags.isEmpty) {
          final allCommunities = await communityService.getPublicCommunitiesPaginated(limit: 20);
          // Sort by member count for popularity
          allCommunities.sort((a, b) => b.memberCount.compareTo(a.memberCount));
          return allCommunities.take(5).toList();
        }
        
        // Get all public communities
        final allCommunities = await communityService.getPublicCommunitiesPaginated(limit: 50);
        
        // Filter communities that match user's interests
        final recommended = allCommunities.where((community) {
          // Don't recommend communities user is already in
          if (community.isMember(user.id)) return false;
          
          // Check if community tags match user's interests
          final hasMatchingTags = community.tags.any((tag) => userTags.contains(tag));
          
          // Also check if community name/description contains user's interests
          final hasMatchingContent = userTags.any((tag) =>
            community.name.toLowerCase().contains(tag.toLowerCase()) ||
            community.description.toLowerCase().contains(tag.toLowerCase())
          );
          
          return hasMatchingTags || hasMatchingContent;
        }).toList();
        
        // Sort by relevance (communities with more matching tags first)
        recommended.sort((a, b) {
          final aMatches = a.tags.where((tag) => userTags.contains(tag)).length;
          final bMatches = b.tags.where((tag) => userTags.contains(tag)).length;
          if (aMatches != bMatches) return bMatches.compareTo(aMatches);
          // If same relevance, sort by member count
          return b.memberCount.compareTo(a.memberCount);
        });
        
        return recommended.take(10).toList();
      } catch (e) {
        // Fallback to popular communities
        final allCommunities = await communityService.getPublicCommunitiesPaginated(limit: 20);
        allCommunities.sort((a, b) => b.memberCount.compareTo(a.memberCount));
        return allCommunities.take(5).toList();
      }
    },
    loading: () async => [],
    error: (_, __) async => [],
  );
});

// Trending communities provider (based on member count and recent activity)
final trendingCommunitiesProvider = FutureProvider.autoDispose<List<CommunityModel>>((ref) async {
  final communityService = ref.watch(communityServiceProvider);
  
  try {
    final allCommunities = await communityService.getPublicCommunitiesPaginated(limit: 30);
    
    // Sort by trending score (member count + recency)
    allCommunities.sort((a, b) {
      // Calculate trending score based on member count and recency
      final aScore = a.memberCount + (DateTime.now().difference(a.createdAt).inDays < 7 ? 50 : 0);
      final bScore = b.memberCount + (DateTime.now().difference(b.createdAt).inDays < 7 ? 50 : 0);
      return bScore.compareTo(aScore);
    });
    
    return allCommunities.take(5).toList();
  } catch (e) {
    return [];
  }
});

// New communities provider (recently created)
final newCommunitiesProvider = FutureProvider.autoDispose<List<CommunityModel>>((ref) async {
  final communityService = ref.watch(communityServiceProvider);
  
  try {
    final allCommunities = await communityService.getPublicCommunitiesPaginated(limit: 20);
    
    // Sort by creation date (newest first)
    allCommunities.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    return allCommunities.take(5).toList();
  } catch (e) {
    return [];
  }
});

// User interests provider (extracted from user's communities)
final userInterestsProvider = FutureProvider.autoDispose<Set<String>>((ref) async {
  final userAsync = ref.watch(authNotifierProvider);
  
  return userAsync.when(
    data: (user) async {
      if (user == null) return {};
      
      try {
        final userCommunities = await ref.read(userCommunitiesProvider.future);
        final interests = <String>{};
        
        for (final community in userCommunities) {
          interests.addAll(community.tags);
        }
        
        return interests;
      } catch (e) {
        return {};
      }
    },
    loading: () async => {},
    error: (_, __) async => {},
  );
});

// Community details provider
final communityDetailsProvider = StreamProvider.autoDispose.family<CommunityModel?, String>((ref, communityId) {
  final communityService = ref.watch(communityServiceProvider);
  return communityService.getCommunityStream(communityId);
});

// Search communities provider
final searchCommunitiesProvider = StreamProvider.autoDispose.family<List<CommunityModel>, CommunitySearchParams>((ref, params) {
  final communityService = ref.watch(communityServiceProvider);
  final query = params.query;
  final category = params.category;
  final isBusiness = params.isBusiness;
  final limit = params.limit;

  if (query.isEmpty) {
    // Show all public communities, sorted by member count
    return communityService.getPublicCommunities(limit: 100).map((communities) {
      final sorted = [...communities];
      sorted.sort((a, b) => b.memberCount.compareTo(a.memberCount));
      return sorted;
    });
  }
  return communityService.searchCommunities(
    query: query,
    category: category,
    isBusiness: isBusiness,
    limit: limit,
  );
});

// Community statistics provider
final communityStatsProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, communityId) async {
  final communityService = ref.watch(communityServiceProvider);
  return await communityService.getCommunityStats(communityId);
});

// Community members provider with real-time updates
final communityMembersProvider = StreamProvider.autoDispose.family<List<UserModel>, String>((ref, communityId) {
  final communityService = ref.watch(communityServiceProvider);
  return communityService.getCommunityMembersStream(communityId);
});

// Community banned users provider
final communityBannedUsersProvider = StreamProvider.autoDispose.family<List<UserModel>, String>((ref, communityId) {
  final communityService = ref.watch(communityServiceProvider);
  return communityService.getCommunityBannedUsersStream(communityId);
});

// Member search provider with debouncing
final memberSearchProvider = StateProvider.autoDispose.family<String, String>((ref, communityId) => '');

// Debounced search provider for better performance
final debouncedSearchProvider = StateProvider.autoDispose.family<String, String>((ref, communityId) => '');

// Filtered members provider with enhanced search
final filteredMembersProvider = Provider.autoDispose.family<List<UserModel>, String>((ref, communityId) {
  final membersAsync = ref.watch(communityMembersProvider(communityId));
  final searchQuery = ref.watch(debouncedSearchProvider(communityId));
  
  return membersAsync.when(
    data: (members) {
      if (searchQuery.isEmpty) return members;
      
      final query = searchQuery.toLowerCase().trim();
      final queryWords = query.split(' ').where((word) => word.isNotEmpty).toList();
      
      return members.where((member) {
        // Search in display name, email, and phone number
        final displayName = member.displayName?.toLowerCase() ?? '';
        final email = member.email?.toLowerCase() ?? '';
        final phone = member.phoneNumber.toLowerCase();
        
        // If single word query, check if it's contained in any field
        if (queryWords.length == 1) {
          return displayName.contains(query) ||
                 email.contains(query) ||
                 phone.contains(query);
        }
        
        // For multi-word queries, check if all words are found in any field
        return queryWords.every((word) =>
          displayName.contains(word) ||
          email.contains(word) ||
          phone.contains(word)
        );
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

  Future<CommunityModel?> createCommunity({
    required String name,
    required String description,
    String? coverImage,
    String? badgeUrl,
    required String visibility,
    bool approvalRequired = false,
    bool isBusiness = false,
    List<String>? joinQuestions,
    List<String>? rules,
    String? welcomeMessage, // NEW: Custom welcome message
    List<String>? tags, // NEW: Community tags
    Map<String, String>? theme,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      final createdCommunity = await _communityService.createCommunity(
        name: name,
        description: description,
        coverImage: coverImage,
        badgeUrl: badgeUrl,
        visibility: visibility,
        approvalRequired: approvalRequired,
        isBusiness: isBusiness,
        joinQuestions: joinQuestions,
        rules: rules,
        welcomeMessage: welcomeMessage, // NEW
        tags: tags, // NEW
        theme: theme,
      );
      
      state = const AsyncValue.data(null);
      
      // Invalidate related providers
      _ref.invalidate(publicCommunitiesProvider);
      _ref.invalidate(userCommunitiesProvider);
      _ref.invalidate(ownedCommunitiesProvider);
      
      return createdCommunity;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return null;
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

  Future<void> updateJoinQuestions(String communityId, List<String> questions) async {
    state = const AsyncValue.loading();
    
    try {
      await _communityService.updateJoinQuestions(communityId, questions);
      state = const AsyncValue.data(null);
      
      // Invalidate related providers
      _ref.invalidate(communityDetailsProvider(communityId));
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> joinCommunityWithAnswers(String communityId, List<String> answers) async {
    state = const AsyncValue.loading();
    
    try {
      await _communityService.joinCommunityWithAnswers(communityId, answers);
      state = const AsyncValue.data(null);
      
      // Invalidate related providers
      _ref.invalidate(communityDetailsProvider(communityId));
      _ref.invalidate(userCommunitiesProvider);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> updateRules(String communityId, List<String> rules) async {
    state = const AsyncValue.loading();
    
    try {
      await _communityService.updateRules(communityId, rules);
      state = const AsyncValue.data(null);
      
      // Invalidate related providers
      _ref.invalidate(communityDetailsProvider(communityId));
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // NEW: Update welcome message
  Future<void> updateWelcomeMessage(String communityId, String welcomeMessage) async {
    state = const AsyncValue.loading();
    
    try {
      await _communityService.updateWelcomeMessage(communityId, welcomeMessage);
      state = const AsyncValue.data(null);
      
      // Invalidate related providers
      _ref.invalidate(communityDetailsProvider(communityId));
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // NEW: Acknowledge rules
  Future<void> acknowledgeRules(String communityId, List<String> acknowledgedRules) async {
    state = const AsyncValue.loading();
    
    try {
      await _communityService.acknowledgeRules(communityId, acknowledgedRules);
      state = const AsyncValue.data(null);
      
      // Invalidate related providers
      _ref.invalidate(communityDetailsProvider(communityId));
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // NEW: Approve join request
  Future<void> approveJoinRequest(String communityId, String userId) async {
    state = const AsyncValue.loading();
    
    try {
      await _communityService.approveJoinRequest(communityId, userId);
      state = const AsyncValue.data(null);
      
      // Invalidate related providers
      _ref.invalidate(communityDetailsProvider(communityId));
      _ref.invalidate(userCommunitiesProvider);
      _ref.invalidate(pendingJoinRequestsProvider(communityId));
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // NEW: Reject join request
  Future<void> rejectJoinRequest(String communityId, String userId, String? reason) async {
    state = const AsyncValue.loading();
    
    try {
      await _communityService.rejectJoinRequest(communityId, userId, reason);
      state = const AsyncValue.data(null);
      
      // Invalidate related providers
      _ref.invalidate(pendingJoinRequestsProvider(communityId));
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // NEW: Complete onboarding for user in community
  Future<void> completeOnboarding(String communityId, String userId) async {
    state = const AsyncValue.loading();
    
    try {
      await _communityService.completeOnboarding(communityId, userId);
      state = const AsyncValue.data(null);
      
      // Invalidate related providers
      _ref.invalidate(communityMembersProvider(communityId));
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
final communityFormProvider = StateProvider<Map<String, dynamic>>((ref) => <String, dynamic>{
  'name': '',
  'description': '',
  'coverImage': '',
  'visibility': 'public',
  'approvalRequired': false,
  'isBusiness': false,
  'theme': <String, String>{'color': '#2196F3', 'banner_url': ''},
});

// Community form validation provider
final communityFormValidationProvider = Provider<Map<String, String>>((ref) {
  try {
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
      errors['description'] = 'Community description must be at least 10 characters';
    } else if (form['description'].toString().length > 500) {
      errors['description'] = 'Community description must be less than 500 characters';
    }
    
    return errors;
  } catch (e) {
    print('🔍 CommunityFormValidationProvider error: $e');
    return <String, String>{};
  }
});

// NEW: Pending join requests provider for admin review
final pendingJoinRequestsProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, communityId) {
  final communityService = ref.watch(communityServiceProvider);
  return communityService.getPendingJoinRequests(communityId);
});

// NEW: User join answers provider
final userJoinAnswersProvider = FutureProvider.family<List<String>, Map<String, String>>((ref, params) async {
  final communityService = ref.watch(communityServiceProvider);
  final communityId = params['communityId']!;
  final userId = params['userId']!;
  return await communityService.getUserJoinAnswers(communityId, userId);
});

// NEW: Rule acknowledgment status provider
final ruleAcknowledgmentStatusProvider = FutureProvider.family<bool, Map<String, String>>((ref, params) async {
  final communityService = ref.watch(communityServiceProvider);
  final communityId = params['communityId']!;
  final userId = params['userId']!;
  return await communityService.hasUserAcknowledgedRules(communityId, userId);
});

// NEW: Welcome message provider
final welcomeMessageProvider = Provider.family<String, CommunityModel?>((ref, community) {
  return community?.welcomeMessage ?? '';
});

// NEW: Community rules provider
final communityRulesProvider = Provider.family<List<String>, CommunityModel?>((ref, community) {
  return community?.rules ?? [];
});

// NEW: Community join questions provider
final communityJoinQuestionsProvider = Provider.family<List<String>, CommunityModel?>((ref, community) {
  return community?.joinQuestions ?? [];
});

// NEW: User onboarding completion status provider
final userOnboardingStatusProvider = FutureProvider.family<bool, Map<String, String>>((ref, params) async {
  final communityService = ref.watch(communityServiceProvider);
  final communityId = params['communityId']!;
  final userId = params['userId']!;
  return await communityService.hasUserCompletedOnboarding(communityId, userId);
});

// Community form is valid provider
final communityFormIsValidProvider = Provider<bool>((ref) {
  try {
    final errors = ref.watch(communityFormValidationProvider);
    return errors.isEmpty;
  } catch (e) {
    print('🔍 CommunityFormIsValidProvider error: $e');
    return false;
  }
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