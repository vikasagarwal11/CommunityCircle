import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';

import '../services/database_service.dart';
import '../models/event_model.dart';
import '../models/user_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final Logger _logger = Logger();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();

  // Navigation callback
  Function(String)? _onNotificationTap;

  // Initialize notification service
  Future<void> initialize({
    required Function(String) onNotificationTap,
  }) async {
    try {
      _onNotificationTap = onNotificationTap;
      
      // Request permission
      await _requestPermission();
      
      // Initialize local notifications
      await _initializeLocalNotifications();
      
      // Get FCM token
      await _getFCMToken();
      
      // Set up message handlers
      await _setupMessageHandlers();
      
      _logger.i('Notification service initialized successfully');
    } catch (e) {
      _logger.e('Failed to initialize notification service: $e');
    }
  }

  // Request notification permission
  Future<void> _requestPermission() async {
    try {
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      _logger.i('User granted permission: ${settings.authorizationStatus}');
    } catch (e) {
      _logger.e('Failed to request notification permission: $e');
    }
  }

  // Initialize local notifications for in-app banners
  Future<void> _initializeLocalNotifications() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _logger.i('Local notifications initialized');
    } catch (e) {
      _logger.e('Failed to initialize local notifications: $e');
    }
  }

  // Get and save FCM token
  Future<void> _getFCMToken() async {
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        await _saveTokenToDatabase(token);
        _logger.i('FCM token saved: ${token.substring(0, 20)}...');
      }
    } catch (e) {
      _logger.e('Failed to get FCM token: $e');
    }
  }

  // Save FCM token to user's document in Firestore
  Future<void> _saveTokenToDatabase(String token) async {
    try {
      final currentUser = await DatabaseService().getCurrentUser();
      if (currentUser != null) {
        await DatabaseService().updateUserFCMToken(currentUser.id, token);
      }
    } catch (e) {
      _logger.e('Failed to save FCM token to database: $e');
    }
  }

  // Set up message handlers for foreground and background
  Future<void> _setupMessageHandlers() async {
    // Foreground message handler
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Notification tap handler
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    
    // App opened from terminated state
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  // Handle foreground messages (show in-app banner)
  void _handleForegroundMessage(RemoteMessage message) {
    _logger.i('Received foreground message: ${message.messageId}');
    
    // Show local notification banner
    _showLocalNotification(message);
    
    // Trigger any real-time UI updates
    _updateRealTimeUI(message);
  }

  // Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    _logger.i('Notification tapped: ${message.messageId}');
    
    // Extract navigation data
    String? navigationData = message.data['navigation'];
    if (navigationData != null && _onNotificationTap != null) {
      _onNotificationTap!(navigationData);
    }
  }

  // Show local notification banner
  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'mojo_chat',
        'MOJO Chat',
        channelDescription: 'Chat notifications',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
      );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _localNotifications.show(
        message.hashCode,
        message.notification?.title ?? 'New Message',
        message.notification?.body ?? '',
        platformChannelSpecifics,
        payload: json.encode(message.data),
      );
    } catch (e) {
      _logger.e('Failed to show local notification: $e');
    }
  }

  // Handle local notification tap
  void _onNotificationTapped(NotificationResponse response) {
    try {
      if (response.payload != null) {
        Map<String, dynamic> data = json.decode(response.payload!);
        String? navigationData = data['navigation'];
        if (navigationData != null && _onNotificationTap != null) {
          _onNotificationTap!(navigationData);
        }
      }
    } catch (e) {
      _logger.e('Failed to handle local notification tap: $e');
    }
  }

  // Update real-time UI (for badge counts, etc.)
  void _updateRealTimeUI(RemoteMessage message) {
    // This will be integrated with Riverpod providers
    // For now, just log the update
    _logger.i('Updating real-time UI for message: ${message.messageId}');
  }

  // Refresh FCM token (call this when user logs in)
  Future<void> refreshToken() async {
    try {
      await _getFCMToken();
      _logger.i('FCM token refreshed');
    } catch (e) {
      _logger.e('Failed to refresh FCM token: $e');
    }
  }

  // Clear FCM token (call this when user logs out)
  Future<void> clearToken() async {
    try {
      final currentUser = await DatabaseService().getCurrentUser();
      if (currentUser != null) {
        await DatabaseService().updateUserFCMToken(currentUser.id, null);
      }
      _logger.i('FCM token cleared');
    } catch (e) {
      _logger.e('Failed to clear FCM token: $e');
    }
  }

  // Subscribe to topic (for community-wide notifications)
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      _logger.i('Subscribed to topic: $topic');
    } catch (e) {
      _logger.e('Failed to subscribe to topic $topic: $e');
    }
  }

  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      _logger.i('Unsubscribed from topic: $topic');
    } catch (e) {
      _logger.e('Failed to unsubscribe from topic $topic: $e');
    }
  }

  // ===== EVENT REMINDER NOTIFICATIONS =====

  // Schedule event reminder notification
  Future<void> scheduleEventReminder(EventModel event, UserModel user, {
    required DateTime reminderTime,
    String? customMessage,
  }) async {
    try {
      final notificationId = _generateNotificationId('event_reminder', event.id, user.id);
      
      final title = 'Event Reminder: ${event.title}';
      final body = customMessage ?? 
          'Your event "${event.title}" starts in ${_getTimeUntilEvent(event.date)}';
      
      await _scheduleLocalNotification(
        id: notificationId,
        title: title,
        body: body,
        scheduledDate: reminderTime,
        payload: {
          'type': 'event_reminder',
          'event_id': event.id,
          'navigation': '/event/${event.id}',
        },
      );
      
      _logger.i('Scheduled event reminder for ${event.title} at ${reminderTime}');
    } catch (e) {
      _logger.e('Failed to schedule event reminder: $e');
    }
  }

  // Cancel event reminder notification
  Future<void> cancelEventReminder(String eventId, String userId) async {
    try {
      final notificationId = _generateNotificationId('event_reminder', eventId, userId);
      await _localNotifications.cancel(notificationId);
      _logger.i('Cancelled event reminder for event $eventId');
    } catch (e) {
      _logger.e('Failed to cancel event reminder: $e');
    }
  }

  // Send RSVP confirmation notification
  Future<void> sendRSVPConfirmation(EventModel event, UserModel user, String rsvpStatus) async {
    try {
      final title = 'RSVP Confirmed';
      final body = 'You have ${rsvpStatus.toLowerCase()} "${event.title}" on ${_formatEventDate(event.date)}';
      
      await _sendLocalNotification(
        title: title,
        body: body,
        payload: {
          'type': 'rsvp_confirmation',
          'event_id': event.id,
          'rsvp_status': rsvpStatus,
          'navigation': '/event/${event.id}',
        },
      );
      
      _logger.i('Sent RSVP confirmation for ${event.title}');
    } catch (e) {
      _logger.e('Failed to send RSVP confirmation: $e');
    }
  }

  // Send event update notification
  Future<void> sendEventUpdate(EventModel event, List<String> attendeeIds, String updateType) async {
    try {
      final title = 'Event Updated';
      final body = 'Your event "${event.title}" has been updated';
      
      // Send to all attendees
      for (final attendeeId in attendeeIds) {
        await _sendLocalNotification(
          title: title,
          body: body,
          payload: {
            'type': 'event_update',
            'event_id': event.id,
            'update_type': updateType,
            'navigation': '/event/${event.id}',
          },
        );
      }
      
      _logger.i('Sent event update notification for ${event.title}');
    } catch (e) {
      _logger.e('Failed to send event update notification: $e');
    }
  }

  // Send check-in reminder
  Future<void> sendCheckInReminder(EventModel event, List<String> attendeeIds) async {
    try {
      final title = 'Check-in Reminder';
      final body = 'Don\'t forget to check in for "${event.title}"!';
      
      for (final attendeeId in attendeeIds) {
        await _sendLocalNotification(
          title: title,
          body: body,
          payload: {
            'type': 'check_in_reminder',
            'event_id': event.id,
            'navigation': '/event/${event.id}',
          },
        );
      }
      
      _logger.i('Sent check-in reminders for ${event.title}');
    } catch (e) {
      _logger.e('Failed to send check-in reminders: $e');
    }
  }

  // ===== HELPER METHODS =====

  // Schedule a local notification for a specific time
  Future<void> _scheduleLocalNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required Map<String, dynamic> payload,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'mojo_events',
        'MOJO Events',
        channelDescription: 'Event reminders and updates',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );

      const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
      );

      await _localNotifications.zonedSchedule(
        id,
        title,
        body,
        _convertToTZDateTime(scheduledDate),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: json.encode(payload),
      );
    } catch (e) {
      _logger.e('Failed to schedule local notification: $e');
    }
  }

  // Send an immediate local notification
  Future<void> _sendLocalNotification({
    required String title,
    required String body,
    required Map<String, dynamic> payload,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'mojo_events',
        'MOJO Events',
        channelDescription: 'Event reminders and updates',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );

      const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
      );

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        details,
        payload: json.encode(payload),
      );
    } catch (e) {
      _logger.e('Failed to send local notification: $e');
    }
  }

  // Generate unique notification ID
  int _generateNotificationId(String type, String eventId, String userId) {
    return '$type-$eventId-$userId'.hashCode;
  }

  // Convert DateTime to TZDateTime (simplified)
  dynamic _convertToTZDateTime(DateTime dateTime) {
    // In a real implementation, you'd use timezone package
    // For now, return the DateTime as is
    return dateTime;
  }

  // Get time until event
  String _getTimeUntilEvent(DateTime eventTime) {
    final now = DateTime.now();
    final difference = eventTime.difference(now);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''}';
    } else {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    }
  }

  // Format event date
  String _formatEventDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if needed
  // await Firebase.initializeApp();
  
  Logger().i('Handling background message: ${message.messageId}');
  
  // You can perform background tasks here
  // For now, just log the message
} 