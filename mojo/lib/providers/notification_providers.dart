import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../services/notification_service.dart';

final Logger _logger = Logger();

// Notification service provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// Notification state provider
final notificationStateProvider = StateNotifierProvider<NotificationStateNotifier, NotificationState>((ref) {
  return NotificationStateNotifier();
});

// Badge count provider (unread messages)
final badgeCountProvider = StateNotifierProvider<BadgeCountNotifier, Map<String, int>>((ref) {
  return BadgeCountNotifier();
});

// Mute preferences provider
final mutePreferencesProvider = StateNotifierProvider<MutePreferencesNotifier, Map<String, bool>>((ref) {
  return MutePreferencesNotifier();
});

// In-app notification banner provider
final inAppNotificationProvider = StateNotifierProvider<InAppNotificationNotifier, InAppNotification?>((ref) {
  return InAppNotificationNotifier();
});

// Notification state
class NotificationState {
  final bool isInitialized;
  final bool hasPermission;
  final String? fcmToken;
  final String? error;

  const NotificationState({
    this.isInitialized = false,
    this.hasPermission = false,
    this.fcmToken,
    this.error,
  });

  NotificationState copyWith({
    bool? isInitialized,
    bool? hasPermission,
    String? fcmToken,
    String? error,
  }) {
    return NotificationState(
      isInitialized: isInitialized ?? this.isInitialized,
      hasPermission: hasPermission ?? this.hasPermission,
      fcmToken: fcmToken ?? this.fcmToken,
      error: error ?? this.error,
    );
  }
}

// Badge count state
class BadgeCountNotifier extends StateNotifier<Map<String, int>> {
  BadgeCountNotifier() : super({});

  void incrementBadge(String chatId) {
    state = {
      ...state,
      chatId: (state[chatId] ?? 0) + 1,
    };
    _logger.d('Badge count incremented for chat $chatId: ${state[chatId]}');
  }

  void clearBadge(String chatId) {
    state = {
      ...state,
      chatId: 0,
    };
    _logger.d('Badge count cleared for chat $chatId');
  }

  void clearAllBadges() {
    state = {};
    _logger.d('All badge counts cleared');
  }

  int getTotalBadgeCount() {
    return state.values.fold(0, (sum, count) => sum + count);
  }
}

// Mute preferences state
class MutePreferencesNotifier extends StateNotifier<Map<String, bool>> {
  MutePreferencesNotifier() : super({});

  void toggleMute(String chatId) {
    state = {
      ...state,
      chatId: !(state[chatId] ?? false),
    };
    _logger.d('Mute toggled for chat $chatId: ${state[chatId]}');
  }

  void setMute(String chatId, bool isMuted) {
    state = {
      ...state,
      chatId: isMuted,
    };
    _logger.d('Mute set for chat $chatId: $isMuted');
  }

  bool isMuted(String chatId) {
    return state[chatId] ?? false;
  }
}

// In-app notification state
class InAppNotification {
  final String id;
  final String title;
  final String body;
  final String? imageUrl;
  final Map<String, dynamic>? data;
  final DateTime timestamp;

  const InAppNotification({
    required this.id,
    required this.title,
    required this.body,
    this.imageUrl,
    this.data,
    required this.timestamp,
  });
}

class InAppNotificationNotifier extends StateNotifier<InAppNotification?> {
  InAppNotificationNotifier() : super(null);

  void showNotification(InAppNotification notification) {
    state = notification;
    _logger.d('In-app notification shown: ${notification.title}');
  }

  void hideNotification() {
    state = null;
    _logger.d('In-app notification hidden');
  }

  void showMessageNotification({
    required String chatId,
    required String senderName,
    required String message,
    String? senderAvatar,
  }) {
    final notification = InAppNotification(
      id: 'message_${DateTime.now().millisecondsSinceEpoch}',
      title: senderName,
      body: message,
      imageUrl: senderAvatar,
      data: {
        'type': 'message',
        'chatId': chatId,
        'navigation': '/chat/$chatId',
      },
      timestamp: DateTime.now(),
    );

    showNotification(notification);
  }

  void showEventNotification({
    required String eventId,
    required String eventTitle,
    required String communityName,
    String? eventImage,
  }) {
    final notification = InAppNotification(
      id: 'event_${DateTime.now().millisecondsSinceEpoch}',
      title: 'New Event: $eventTitle',
      body: 'From $communityName',
      imageUrl: eventImage,
      data: {
        'type': 'event',
        'eventId': eventId,
        'navigation': '/event/$eventId',
      },
      timestamp: DateTime.now(),
    );

    showNotification(notification);
  }
}

// Notification state notifier
class NotificationStateNotifier extends StateNotifier<NotificationState> {
  NotificationStateNotifier() : super(const NotificationState());

  Future<void> initialize({
    required Function(String) onNotificationTap,
  }) async {
    try {
      _logger.i('Initializing notification service');
      
      final notificationService = NotificationService();
      await notificationService.initialize(onNotificationTap: onNotificationTap);
      
      state = state.copyWith(
        isInitialized: true,
        hasPermission: true, // We'll get actual permission status later
      );
      
      _logger.i('Notification service initialized successfully');
    } catch (e) {
      _logger.e('Failed to initialize notification service: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> refreshToken() async {
    try {
      final notificationService = NotificationService();
      await notificationService.refreshToken();
      
      // Update state with new token (you might want to get it from the service)
      state = state.copyWith(error: null);
      _logger.i('FCM token refreshed');
    } catch (e) {
      _logger.e('Failed to refresh FCM token: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> clearToken() async {
    try {
      final notificationService = NotificationService();
      await notificationService.clearToken();
      
      state = state.copyWith(
        fcmToken: null,
        error: null,
      );
      _logger.i('FCM token cleared');
    } catch (e) {
      _logger.e('Failed to clear FCM token: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    try {
      final notificationService = NotificationService();
      await notificationService.subscribeToTopic(topic);
      _logger.i('Subscribed to topic: $topic');
    } catch (e) {
      _logger.e('Failed to subscribe to topic $topic: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      final notificationService = NotificationService();
      await notificationService.unsubscribeFromTopic(topic);
      _logger.i('Unsubscribed from topic: $topic');
    } catch (e) {
      _logger.e('Failed to unsubscribe from topic $topic: $e');
      state = state.copyWith(error: e.toString());
    }
  }
} 