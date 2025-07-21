import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/offline_sync_service.dart';
import '../services/local_storage_service.dart';
import '../models/community_model.dart';
import '../models/message_model.dart';

// Offline sync service provider
final offlineSyncServiceProvider = Provider<OfflineSyncService>((ref) {
  return OfflineSyncService();
});

// Local storage service provider
final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService();
});

// Connectivity provider
final connectivityProvider = StreamProvider<ConnectivityResult>((ref) {
  return Connectivity().onConnectivityChanged;
});

// Online status provider
final isOnlineProvider = Provider<bool>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  return connectivity.when(
    data: (result) => result != ConnectivityResult.none,
    loading: () => true, // Assume online while loading
    error: (_, __) => false, // Assume offline on error
  );
});

// Offline actions count provider
final offlineActionsCountProvider = StreamProvider<int>((ref) async* {
  final offlineService = ref.watch(offlineSyncServiceProvider);
  while (true) {
    yield await offlineService.getOfflineActionsCount();
    await Future.delayed(const Duration(seconds: 30)); // Reduced from 5 to 30 seconds
  }
});

// Syncing status provider
final isSyncingProvider = Provider<bool>((ref) {
  final offlineService = ref.watch(offlineSyncServiceProvider);
  return offlineService.isSyncing;
});

// Cached communities provider
final cachedCommunitiesProvider = FutureProvider<List<CommunityModel>>((ref) async {
  final localStorage = ref.watch(localStorageServiceProvider);
  return await localStorage.getCachedCommunities();
});

// Cached messages provider
final cachedMessagesProvider = FutureProvider.family<List<MessageModel>, String>((ref, communityId) async {
  final localStorage = ref.watch(localStorageServiceProvider);
  return await localStorage.getCachedMessages(communityId);
});

// Offline-first communities provider
final offlineFirstCommunitiesProvider = FutureProvider<List<CommunityModel>>((ref) async {
  final offlineService = ref.watch(offlineSyncServiceProvider);
  return await offlineService.getCommunitiesWithFallback();
});

// Offline-first messages provider
final offlineFirstMessagesProvider = FutureProvider.family<List<MessageModel>, String>((ref, communityId) async {
  final offlineService = ref.watch(offlineSyncServiceProvider);
  return await offlineService.getMessagesWithFallback(communityId);
});

// Offline sync notifier
class OfflineSyncNotifier extends StateNotifier<AsyncValue<void>> {
  final OfflineSyncService _offlineService;
  final Ref _ref;

  OfflineSyncNotifier(this._offlineService, this._ref) : super(const AsyncValue.data(null));

  // Initialize offline sync
  Future<void> initialize() async {
    try {
      state = const AsyncValue.loading();
      await _offlineService.initialize();
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // Send message with offline support
  Future<void> sendMessageOffline({
    required String text,
    required String communityId,
  }) async {
    try {
      state = const AsyncValue.loading();
      await _offlineService.sendMessageOffline(
        text: text,
        communityId: communityId,
      );
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // Join community with offline support
  Future<void> joinCommunityOffline(String communityId) async {
    try {
      state = const AsyncValue.loading();
      await _offlineService.queueOfflineAction(
        action: 'join_community',
        data: {'communityId': communityId},
      );
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // Manual sync
  Future<void> manualSync() async {
    try {
      state = const AsyncValue.loading();
      await _offlineService.manualSync();
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // Clear offline actions
  Future<void> clearOfflineActions() async {
    try {
      state = const AsyncValue.loading();
      await _offlineService.clearOfflineActions();
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // Dispose
  @override
  void dispose() {
    _offlineService.dispose();
    super.dispose();
  }
}

// Offline sync notifier provider
final offlineSyncNotifierProvider = StateNotifierProvider<OfflineSyncNotifier, AsyncValue<void>>((ref) {
  final offlineService = ref.watch(offlineSyncServiceProvider);
  return OfflineSyncNotifier(offlineService, ref);
});

// Offline status provider (combines online status and sync status)
final offlineStatusProvider = Provider<OfflineStatus>((ref) {
  final isOnline = ref.watch(isOnlineProvider);
  final isSyncing = ref.watch(isSyncingProvider);
  final actionsCount = ref.watch(offlineActionsCountProvider);
  
  return OfflineStatus(
    isOnline: isOnline,
    isSyncing: isSyncing,
    pendingActions: actionsCount.when(
      data: (count) => count,
      loading: () => 0,
      error: (_, __) => 0,
    ),
  );
});

// Offline status class
class OfflineStatus {
  final bool isOnline;
  final bool isSyncing;
  final int pendingActions;

  const OfflineStatus({
    required this.isOnline,
    required this.isSyncing,
    required this.pendingActions,
  });

  bool get hasPendingActions => pendingActions > 0;
  bool get needsSync => !isOnline && hasPendingActions;
} 