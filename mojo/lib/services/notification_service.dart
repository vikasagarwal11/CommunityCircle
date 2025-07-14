import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';

import '../services/database_service.dart';

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