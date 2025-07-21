import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import '../core/logger.dart';
import '../models/message_model.dart';
import '../models/community_model.dart';
import '../models/user_model.dart';
import 'chat_service.dart';
import 'community_service.dart';
import 'local_storage_service.dart';

class OfflineSyncService {
  final Connectivity _connectivity = Connectivity();
  final ChatService _chatService = ChatService();
  final CommunityService _communityService = CommunityService();
  final LocalStorageService _localStorage = LocalStorageService();
  final Logger _logger = Logger('OfflineSyncService');

  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  Timer? _syncTimer;
  bool _isOnline = true;
  bool _isSyncing = false;

  // Initialize the service
  Future<void> initialize() async {
    _logger.i('Initializing OfflineSyncService');
    
    // Check initial connectivity
    final connectivityResult = await _connectivity.checkConnectivity();
    _isOnline = connectivityResult != ConnectivityResult.none;
    
    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);
    
    // Start periodic sync timer
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) => _syncOfflineActions());
    
    _logger.i('OfflineSyncService initialized. Online: $_isOnline');
  }

  // Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
    _logger.i('OfflineSyncService disposed');
  }

  // Handle connectivity changes
  void _onConnectivityChanged(ConnectivityResult result) {
    final wasOnline = _isOnline;
    _isOnline = result != ConnectivityResult.none;
    
    _logger.i('Connectivity changed: ${result.name}. Online: $_isOnline');
    
    if (!wasOnline && _isOnline) {
      // Just came back online, sync offline actions
      _syncOfflineActions();
    }
  }

  // Get online status
  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;

  // Queue an offline action
  Future<void> queueOfflineAction({
    required String action,
    required Map<String, dynamic> data,
  }) async {
    if (_isOnline) {
      _logger.i('Action performed online: $action');
      return;
    }

    try {
      final actionData = {
        'action': action,
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'retryCount': 0,
      };

      await _localStorage.addOfflineAction(actionData);
      _logger.i('Offline action queued: $action');
    } catch (e) {
      _logger.e('Error queuing offline action: $e');
    }
  }

  // Send message with offline support
  Future<void> sendMessageOffline({
    required String communityId,
    required String text,
    String? mediaUrl,
    String? mediaType,
    List<String> mentions = const [],
  }) async {
    if (_isOnline) {
      // Send immediately if online
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception('User not authenticated');
        
        await _chatService.sendMessage(
          communityId: communityId,
          userId: user.uid,
          text: text,
          mediaUrl: mediaUrl,
          mediaType: mediaType,
          mentions: mentions,
        );
        
        _logger.i('Message sent online');
      } catch (e) {
        _logger.e('Error sending message online: $e');
        // Fall back to offline queue
        await queueOfflineAction(
          action: 'send_message',
          data: {
            'communityId': communityId,
            'text': text,
            'mediaUrl': mediaUrl,
            'mediaType': mediaType,
            'mentions': mentions,
          },
        );
      }
    } else {
      // Queue for offline sync
      await queueOfflineAction(
        action: 'send_message',
        data: {
          'communityId': communityId,
          'text': text,
          'mediaUrl': mediaUrl,
          'mediaType': mediaType,
          'mentions': mentions,
        },
      );
    }
  }

  // Sync offline actions
  Future<void> _syncOfflineActions() async {
    if (!_isOnline || _isSyncing) return;

    _isSyncing = true;
    _logger.i('Starting offline actions sync');

    try {
      final actions = await _localStorage.getOfflineActions();
      
      for (final actionData in actions) {
        final action = actionData['action'] as String;
        final data = actionData['data'] as Map<String, dynamic>;
        final retryCount = actionData['retryCount'] as int;

        if (retryCount >= 3) {
          _logger.w('Skipping action with max retries: $action');
          await _localStorage.removeOfflineAction(actionData);
          continue;
        }

        try {
          switch (action) {
            case 'send_message':
              await _syncSendMessage(data);
              break;
            case 'join_community':
              await _syncJoinCommunity(data);
              break;
            case 'leave_community':
              await _syncLeaveCommunity(data);
              break;
            case 'update_profile':
              await _syncUpdateProfile(data);
              break;
            default:
              _logger.w('Unknown offline action: $action');
          }

          // Remove successful action
          await _localStorage.removeOfflineAction(actionData);
          _logger.i('Successfully synced action: $action');
        } catch (e) {
          _logger.e('Error syncing action $action: $e');
          
          // Increment retry count
          actionData['retryCount'] = retryCount + 1;
          await _localStorage.updateOfflineAction(actionData);
        }
      }
    } catch (e) {
      _logger.e('Error during offline sync: $e');
    } finally {
      _isSyncing = false;
      _logger.i('Offline actions sync completed');
    }
  }

  // Sync send message action
  Future<void> _syncSendMessage(Map<String, dynamic> data) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _chatService.sendMessage(
      communityId: data['communityId'],
      userId: user.uid,
      text: data['text'],
      mediaUrl: data['mediaUrl'],
      mediaType: data['mediaType'],
      mentions: List<String>.from(data['mentions'] ?? []),
    );
  }

  // Sync join community action
  Future<void> _syncJoinCommunity(Map<String, dynamic> data) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _communityService.joinCommunity(data['communityId']);
  }

  // Sync leave community action
  Future<void> _syncLeaveCommunity(Map<String, dynamic> data) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _communityService.leaveCommunity(data['communityId']);
  }

  // Sync update profile action
  Future<void> _syncUpdateProfile(Map<String, dynamic> data) async {
    // TODO: Implement profile update sync
    _logger.i('Profile update sync not implemented yet');
  }

  // Get offline actions count
  Future<int> getOfflineActionsCount() async {
    final actions = await _localStorage.getOfflineActions();
    return actions.length;
  }

  // Cache communities for offline access
  Future<List<CommunityModel>> cacheCommunitiesForOffline() async {
    try {
      _logger.i('Caching communities for offline access');
      
      final communities = await _communityService.getPublicCommunitiesPaginated(limit: 50);
      await _localStorage.cacheCommunities(communities);
      
      _logger.i('Cached ${communities.length} communities');
      return communities;
    } catch (e) {
      _logger.e('Error caching communities: $e');
      return [];
    }
  }

  // Cache messages for offline access
  Future<List<MessageModel>> cacheMessagesForOffline(String communityId) async {
    try {
      _logger.i('Caching messages for community: $communityId');
      
      // Get messages stream and convert to list
      final messagesStream = _chatService.getMessagesStream(communityId);
      final messages = await messagesStream.first;
      
      await _localStorage.cacheMessages(communityId, messages);
      
      _logger.i('Cached ${messages.length} messages for community: $communityId');
      return messages;
    } catch (e) {
      _logger.e('Error caching messages: $e');
      return [];
    }
  }

  // Get cached data with fallback
  Future<List<CommunityModel>> getCommunitiesWithFallback() async {
    try {
      if (_isOnline) {
        // Try to get fresh data
        final communities = await _communityService.getPublicCommunitiesPaginated(limit: 50);
        // Cache the fresh data
        await _localStorage.cacheCommunities(communities);
        return communities;
      } else {
        // Return cached data
        return await _localStorage.getCachedCommunities();
      }
    } catch (e) {
      _logger.e('Error getting communities with fallback: $e');
      // Return cached data as last resort
      return await _localStorage.getCachedCommunities();
    }
  }

  // Get cached messages with fallback
  Future<List<MessageModel>> getMessagesWithFallback(String communityId) async {
    try {
      if (_isOnline) {
        // Try to get fresh data
        final messagesStream = _chatService.getMessagesStream(communityId);
        final messages = await messagesStream.first;
        // Cache the fresh data
        await _localStorage.cacheMessages(communityId, messages);
        return messages;
      } else {
        // Return cached data
        return await _localStorage.getCachedMessages(communityId);
      }
    } catch (e) {
      _logger.e('Error getting messages with fallback: $e');
      // Return cached data as last resort
      return await _localStorage.getCachedMessages(communityId);
    }
  }

  // Manual sync trigger
  Future<void> manualSync() async {
    if (!_isOnline) {
      _logger.w('Cannot sync while offline');
      return;
    }
    
    _logger.i('Manual sync triggered');
    await _syncOfflineActions();
  }

  // Clear all offline actions
  Future<void> clearOfflineActions() async {
    try {
      await _localStorage.clearOfflineActions();
      _logger.i('All offline actions cleared');
    } catch (e) {
      _logger.e('Error clearing offline actions: $e');
    }
  }
} 