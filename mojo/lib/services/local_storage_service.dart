import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:logger/logger.dart';
import '../models/community_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';

class LocalStorageService {
  static const String _communitiesBox = 'communities';
  static const String _messagesBox = 'messages';
  static const String _usersBox = 'users';
  static const String _offlineActionsBox = 'offline_actions';
  static const String _settingsBox = 'settings';

  final Logger _logger = Logger();

  // Initialize Hive boxes
  Future<void> initialize() async {
    try {
      await Hive.openBox(_communitiesBox);
      await Hive.openBox(_messagesBox);
      await Hive.openBox(_usersBox);
      await Hive.openBox(_offlineActionsBox);
      await Hive.openBox(_settingsBox);
      _logger.i('LocalStorageService initialized');
    } catch (e) {
      _logger.e('Error initializing LocalStorageService: $e');
    }
  }

  // Dispose resources
  Future<void> dispose() async {
    try {
      await Hive.close();
      _logger.i('LocalStorageService disposed');
    } catch (e) {
      _logger.e('Error disposing LocalStorageService: $e');
    }
  }

  // Community caching methods
  Future<void> cacheCommunities(List<CommunityModel> communities) async {
    try {
      // Check if box is initialized
      if (!Hive.isBoxOpen(_communitiesBox)) {
        await Hive.openBox(_communitiesBox);
      }
      
      final box = Hive.box(_communitiesBox);
      final Map<String, dynamic> communitiesMap = {};
      
      for (final community in communities) {
        communitiesMap[community.id] = {
          'data': community.toMap(),
          'cachedAt': DateTime.now().millisecondsSinceEpoch,
        };
      }
      
      await box.putAll(communitiesMap);
      _logger.i('Cached ${communities.length} communities');
    } catch (e) {
      _logger.e('Error caching communities: $e');
    }
  }

  Future<List<CommunityModel>> getCachedCommunities() async {
    try {
      // Check if box is initialized
      if (!Hive.isBoxOpen(_communitiesBox)) {
        await Hive.openBox(_communitiesBox);
      }
      
      final box = Hive.box(_communitiesBox);
      final List<CommunityModel> communities = [];
      
      for (final key in box.keys) {
        final data = box.get(key);
        if (data != null) {
          final communityData = data['data'] as Map<String, dynamic>;
          final community = CommunityModel.fromMap(communityData, key.toString());
          communities.add(community);
        }
      }
      
      _logger.i('Retrieved ${communities.length} cached communities');
      return communities;
    } catch (e) {
      _logger.e('Error getting cached communities: $e');
      return [];
    }
  }

  Future<CommunityModel?> getCachedCommunity(String communityId) async {
    try {
      final box = Hive.box(_communitiesBox);
      final data = box.get(communityId);
      
      if (data != null) {
        final communityData = data['data'] as Map<String, dynamic>;
        return CommunityModel.fromMap(communityData, communityId);
      }
      
      return null;
    } catch (e) {
      _logger.e('Error getting cached community: $e');
      return null;
    }
  }

  Future<void> cacheCommunity(CommunityModel community) async {
    try {
      final box = Hive.box(_communitiesBox);
      await box.put(community.id, {
        'data': community.toMap(),
        'cachedAt': DateTime.now().millisecondsSinceEpoch,
      });
      _logger.i('Cached community: ${community.id}');
    } catch (e) {
      _logger.e('Error caching community: $e');
    }
  }

  // Message caching methods
  Future<void> cacheMessages(String communityId, List<MessageModel> messages) async {
    try {
      // Check if box is initialized
      if (!Hive.isBoxOpen(_messagesBox)) {
        await Hive.openBox(_messagesBox);
      }
      
      final box = Hive.box(_messagesBox);
      final Map<String, dynamic> messagesMap = {};
      
      for (final message in messages) {
        messagesMap[message.id] = {
          'data': message.toMap(),
          'communityId': communityId,
          'cachedAt': DateTime.now().millisecondsSinceEpoch,
        };
      }
      
      await box.putAll(messagesMap);
      _logger.i('Cached ${messages.length} messages for community: $communityId');
    } catch (e) {
      _logger.e('Error caching messages: $e');
    }
  }

  Future<List<MessageModel>> getCachedMessages(String communityId) async {
    try {
      // Check if box is initialized
      if (!Hive.isBoxOpen(_messagesBox)) {
        await Hive.openBox(_messagesBox);
      }
      
      final box = Hive.box(_messagesBox);
      final List<MessageModel> messages = [];
      
      for (final key in box.keys) {
        final data = box.get(key);
        if (data != null && data['communityId'] == communityId) {
          final messageData = data['data'] as Map<String, dynamic>;
          final message = MessageModel.fromMap(messageData, key.toString());
          messages.add(message);
        }
      }
      
      // Sort by timestamp (newest first)
      messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      _logger.i('Retrieved ${messages.length} cached messages for community: $communityId');
      return messages;
    } catch (e) {
      _logger.e('Error getting cached messages: $e');
      return [];
    }
  }

  Future<void> addCachedMessage(String communityId, MessageModel message) async {
    try {
      final box = Hive.box(_messagesBox);
      await box.put(message.id, {
        'data': message.toMap(),
        'communityId': communityId,
        'cachedAt': DateTime.now().millisecondsSinceEpoch,
      });
      _logger.i('Added cached message: ${message.id}');
    } catch (e) {
      _logger.e('Error adding cached message: $e');
    }
  }

  // User caching methods
  Future<void> cacheUsers(List<UserModel> users) async {
    try {
      // Check if box is initialized
      if (!Hive.isBoxOpen(_usersBox)) {
        await Hive.openBox(_usersBox);
      }
      
      final box = Hive.box(_usersBox);
      final Map<String, dynamic> usersMap = {};
      
      for (final user in users) {
        usersMap[user.id] = {
          'data': user.toMap(),
          'cachedAt': DateTime.now().millisecondsSinceEpoch,
        };
      }
      
      await box.putAll(usersMap);
      _logger.i('Cached ${users.length} users');
    } catch (e) {
      _logger.e('Error caching users: $e');
    }
  }

  Future<List<UserModel>> getCachedUsers() async {
    try {
      // Check if box is initialized
      if (!Hive.isBoxOpen(_usersBox)) {
        await Hive.openBox(_usersBox);
      }
      
      final box = Hive.box(_usersBox);
      final List<UserModel> users = [];
      
      for (final key in box.keys) {
        final data = box.get(key);
        if (data != null) {
          final userData = data['data'] as Map<String, dynamic>;
          final user = UserModel.fromMap(userData);
          users.add(user);
        }
      }
      
      _logger.i('Retrieved ${users.length} cached users');
      return users;
    } catch (e) {
      _logger.e('Error getting cached users: $e');
      return [];
    }
  }

  Future<UserModel?> getCachedUser(String userId) async {
    try {
      // Check if box is initialized
      if (!Hive.isBoxOpen(_usersBox)) {
        await Hive.openBox(_usersBox);
      }
      
      final box = Hive.box(_usersBox);
      final data = box.get(userId);
      
      if (data != null) {
        final userData = data['data'] as Map<String, dynamic>;
        return UserModel.fromMap(userData);
      }
      
      return null;
    } catch (e) {
      _logger.e('Error getting cached user: $e');
      return null;
    }
  }

  // Offline actions methods
  Future<void> addOfflineAction(Map<String, dynamic> actionData) async {
    try {
      // Check if box is initialized
      if (!Hive.isBoxOpen(_offlineActionsBox)) {
        await Hive.openBox(_offlineActionsBox);
      }
      
      final box = Hive.box(_offlineActionsBox);
      final actionId = DateTime.now().millisecondsSinceEpoch.toString();
      await box.put(actionId, actionData);
      _logger.i('Added offline action: ${actionData['action']}');
    } catch (e) {
      _logger.e('Error adding offline action: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getOfflineActions() async {
    try {
      // Check if box is initialized
      if (!Hive.isBoxOpen(_offlineActionsBox)) {
        await Hive.openBox(_offlineActionsBox);
      }
      
      final box = Hive.box(_offlineActionsBox);
      final List<Map<String, dynamic>> actions = [];
      
      for (final key in box.keys) {
        final data = box.get(key);
        if (data != null) {
          actions.add(Map<String, dynamic>.from(data));
        }
      }
      
      // Sort by timestamp (oldest first for processing order)
      actions.sort((a, b) => (a['timestamp'] as int).compareTo(b['timestamp'] as int));
      
      _logger.i('Retrieved ${actions.length} offline actions');
      return actions;
    } catch (e) {
      _logger.e('Error getting offline actions: $e');
      return [];
    }
  }

  Future<void> removeOfflineAction(Map<String, dynamic> actionData) async {
    try {
      // Check if box is initialized
      if (!Hive.isBoxOpen(_offlineActionsBox)) {
        await Hive.openBox(_offlineActionsBox);
      }
      
      final box = Hive.box(_offlineActionsBox);
      
      // Find the action by matching data
      for (final key in box.keys) {
        final data = box.get(key);
        if (data != null && _actionsMatch(data, actionData)) {
          await box.delete(key);
          _logger.i('Removed offline action: ${actionData['action']}');
          break;
        }
      }
    } catch (e) {
      _logger.e('Error removing offline action: $e');
    }
  }

  Future<void> updateOfflineAction(Map<String, dynamic> actionData) async {
    try {
      // Check if box is initialized
      if (!Hive.isBoxOpen(_offlineActionsBox)) {
        await Hive.openBox(_offlineActionsBox);
      }
      
      final box = Hive.box(_offlineActionsBox);
      
      // Find the action by matching data
      for (final key in box.keys) {
        final data = box.get(key);
        if (data != null && _actionsMatch(data, actionData)) {
          await box.put(key, actionData);
          _logger.i('Updated offline action: ${actionData['action']}');
          break;
        }
      }
    } catch (e) {
      _logger.e('Error updating offline action: $e');
    }
  }

  Future<void> clearOfflineActions() async {
    try {
      // Check if box is initialized
      if (!Hive.isBoxOpen(_offlineActionsBox)) {
        await Hive.openBox(_offlineActionsBox);
      }
      
      final box = Hive.box(_offlineActionsBox);
      await box.clear();
      _logger.i('Cleared all offline actions');
    } catch (e) {
      _logger.e('Error clearing offline actions: $e');
    }
  }

  // Helper method to match actions
  bool _actionsMatch(Map<String, dynamic> action1, Map<String, dynamic> action2) {
    return action1['action'] == action2['action'] &&
           action1['timestamp'] == action2['timestamp'];
  }

  // Settings methods
  Future<void> saveSetting(String key, dynamic value) async {
    try {
      // Check if box is initialized
      if (!Hive.isBoxOpen(_settingsBox)) {
        await Hive.openBox(_settingsBox);
      }
      
      final box = Hive.box(_settingsBox);
      await box.put(key, value);
      _logger.i('Saved setting: $key');
    } catch (e) {
      _logger.e('Error saving setting: $e');
    }
  }

  dynamic getSetting(String key, {dynamic defaultValue}) {
    try {
      // Check if box is initialized
      if (!Hive.isBoxOpen(_settingsBox)) {
        return defaultValue;
      }
      
      final box = Hive.box(_settingsBox);
      return box.get(key, defaultValue: defaultValue);
    } catch (e) {
      _logger.e('Error getting setting: $e');
      return defaultValue;
    }
  }

  Future<void> removeSetting(String key) async {
    try {
      // Check if box is initialized
      if (!Hive.isBoxOpen(_settingsBox)) {
        await Hive.openBox(_settingsBox);
      }
      
      final box = Hive.box(_settingsBox);
      await box.delete(key);
      _logger.i('Removed setting: $key');
    } catch (e) {
      _logger.e('Error removing setting: $e');
    }
  }

  // Cache cleanup methods
  Future<void> cleanupOldCache({Duration maxAge = const Duration(days: 7)}) async {
    try {
      final cutoffTime = DateTime.now().subtract(maxAge).millisecondsSinceEpoch;
      
      // Clean up communities
      final communitiesBox = Hive.box(_communitiesBox);
      for (final key in communitiesBox.keys) {
        final data = communitiesBox.get(key);
        if (data != null && data['cachedAt'] < cutoffTime) {
          await communitiesBox.delete(key);
        }
      }
      
      // Clean up messages
      final messagesBox = Hive.box(_messagesBox);
      for (final key in messagesBox.keys) {
        final data = messagesBox.get(key);
        if (data != null && data['cachedAt'] < cutoffTime) {
          await messagesBox.delete(key);
        }
      }
      
      // Clean up users
      final usersBox = Hive.box(_usersBox);
      for (final key in usersBox.keys) {
        final data = usersBox.get(key);
        if (data != null && data['cachedAt'] < cutoffTime) {
          await usersBox.delete(key);
        }
      }
      
      _logger.i('Cache cleanup completed');
    } catch (e) {
      _logger.e('Error during cache cleanup: $e');
    }
  }

  // Get cache statistics
  Map<String, int> getCacheStats() {
    try {
      final communitiesBox = Hive.box(_communitiesBox);
      final messagesBox = Hive.box(_messagesBox);
      final usersBox = Hive.box(_usersBox);
      final offlineActionsBox = Hive.box(_offlineActionsBox);
      
      return {
        'communities': communitiesBox.length,
        'messages': messagesBox.length,
        'users': usersBox.length,
        'offlineActions': offlineActionsBox.length,
      };
    } catch (e) {
      _logger.e('Error getting cache stats: $e');
      return {};
    }
  }
} 