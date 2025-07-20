import 'package:shared_preferences/shared_preferences.dart';
import '../core/logger.dart';

class NotificationPreferencesService {
  static const String _keyEventReminders = 'event_reminders';
  static const String _keyRSVPConfirmations = 'rsvp_confirmations';
  static const String _keyEventUpdates = 'event_updates';
  static const String _keyCheckInReminders = 'check_in_reminders';
  static const String _keyCommunityMessages = 'community_messages';
  static const String _keyPersonalMessages = 'personal_messages';
  static const String _keyChallengeUpdates = 'challenge_updates';
  static const String _keyMomentNotifications = 'moment_notifications';
  static const String _keyReminderTime = 'reminder_time';
  static const String _keyQuietHoursStart = 'quiet_hours_start';
  static const String _keyQuietHoursEnd = 'quiet_hours_end';
  static const String _keyQuietHoursEnabled = 'quiet_hours_enabled';

  final Logger _logger = Logger('NotificationPreferencesService');

  // Default preferences
  static const Map<String, bool> _defaultPreferences = {
    _keyEventReminders: true,
    _keyRSVPConfirmations: true,
    _keyEventUpdates: true,
    _keyCheckInReminders: true,
    _keyCommunityMessages: true,
    _keyPersonalMessages: true,
    _keyChallengeUpdates: true,
    _keyMomentNotifications: true,
  };

  // Get notification preference
  Future<bool> getNotificationPreference(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(key) ?? _defaultPreferences[key] ?? true;
    } catch (e) {
      _logger.e('Error getting notification preference: $e');
      return _defaultPreferences[key] ?? true;
    }
  }

  // Set notification preference
  Future<void> setNotificationPreference(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
      _logger.i('Notification preference updated: $key = $value');
    } catch (e) {
      _logger.e('Error setting notification preference: $e');
    }
  }

  // Get all notification preferences
  Future<Map<String, bool>> getAllPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, bool> preferences = {};
      
      for (final key in _defaultPreferences.keys) {
        preferences[key] = prefs.getBool(key) ?? _defaultPreferences[key] ?? true;
      }
      
      return preferences;
    } catch (e) {
      _logger.e('Error getting all notification preferences: $e');
      return Map.from(_defaultPreferences);
    }
  }

  // Set all notification preferences
  Future<void> setAllPreferences(Map<String, bool> preferences) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final entry in preferences.entries) {
        await prefs.setBool(entry.key, entry.value);
      }
      _logger.i('All notification preferences updated');
    } catch (e) {
      _logger.e('Error setting all notification preferences: $e');
    }
  }

  // Reset to default preferences
  Future<void> resetToDefaults() async {
    try {
      await setAllPreferences(_defaultPreferences);
      _logger.i('Notification preferences reset to defaults');
    } catch (e) {
      _logger.e('Error resetting notification preferences: $e');
    }
  }

  // Get reminder time (in minutes before event)
  Future<int> getReminderTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_keyReminderTime) ?? 30; // Default: 30 minutes
    } catch (e) {
      _logger.e('Error getting reminder time: $e');
      return 30;
    }
  }

  // Set reminder time (in minutes before event)
  Future<void> setReminderTime(int minutes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyReminderTime, minutes);
      _logger.i('Reminder time updated: $minutes minutes');
    } catch (e) {
      _logger.e('Error setting reminder time: $e');
    }
  }

  // Get quiet hours settings
  Future<Map<String, dynamic>> getQuietHours() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'enabled': prefs.getBool(_keyQuietHoursEnabled) ?? false,
        'start': prefs.getString(_keyQuietHoursStart) ?? '22:00',
        'end': prefs.getString(_keyQuietHoursEnd) ?? '08:00',
      };
    } catch (e) {
      _logger.e('Error getting quiet hours: $e');
      return {
        'enabled': false,
        'start': '22:00',
        'end': '08:00',
      };
    }
  }

  // Set quiet hours settings
  Future<void> setQuietHours(bool enabled, String start, String end) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyQuietHoursEnabled, enabled);
      await prefs.setString(_keyQuietHoursStart, start);
      await prefs.setString(_keyQuietHoursEnd, end);
      _logger.i('Quiet hours updated: enabled=$enabled, start=$start, end=$end');
    } catch (e) {
      _logger.e('Error setting quiet hours: $e');
    }
  }

  // Check if notification should be sent based on preferences
  Future<bool> shouldSendNotification(String type) async {
    try {
      // Check if quiet hours are enabled and current time is within quiet hours
      final quietHours = await getQuietHours();
      if (quietHours['enabled'] == true) {
        final now = DateTime.now();
        final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
        
        if (_isTimeInRange(currentTime, quietHours['start'], quietHours['end'])) {
          _logger.i('Notification suppressed due to quiet hours: $type');
          return false;
        }
      }

      // Check if this notification type is enabled
      final isEnabled = await getNotificationPreference(type);
      if (!isEnabled) {
        _logger.i('Notification type disabled: $type');
        return false;
      }

      return true;
    } catch (e) {
      _logger.e('Error checking if notification should be sent: $e');
      return true; // Default to allowing notifications if there's an error
    }
  }

  // Helper method to check if time is within range
  bool _isTimeInRange(String currentTime, String startTime, String endTime) {
    try {
      final current = _parseTime(currentTime);
      final start = _parseTime(startTime);
      final end = _parseTime(endTime);

      if (start <= end) {
        // Same day range (e.g., 09:00 to 17:00)
        return current >= start && current <= end;
      } else {
        // Overnight range (e.g., 22:00 to 08:00)
        return current >= start || current <= end;
      }
    } catch (e) {
      _logger.e('Error parsing time range: $e');
      return false;
    }
  }

  // Helper method to parse time string to minutes
  int _parseTime(String time) {
    final parts = time.split(':');
    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);
    return hours * 60 + minutes;
  }

  // Get notification preference display name
  String getPreferenceDisplayName(String key) {
    switch (key) {
      case _keyEventReminders:
        return 'Event Reminders';
      case _keyRSVPConfirmations:
        return 'RSVP Confirmations';
      case _keyEventUpdates:
        return 'Event Updates';
      case _keyCheckInReminders:
        return 'Check-in Reminders';
      case _keyCommunityMessages:
        return 'Community Messages';
      case _keyPersonalMessages:
        return 'Personal Messages';
      case _keyChallengeUpdates:
        return 'Challenge Updates';
      case _keyMomentNotifications:
        return 'Moment Notifications';
      default:
        return key;
    }
  }

  // Get notification preference description
  String getPreferenceDescription(String key) {
    switch (key) {
      case _keyEventReminders:
        return 'Receive reminders before events you\'re attending';
      case _keyRSVPConfirmations:
        return 'Get notified when someone RSVPs to your events';
      case _keyEventUpdates:
        return 'Receive updates when events you\'re attending change';
      case _keyCheckInReminders:
        return 'Get reminded to check in at events';
      case _keyCommunityMessages:
        return 'Receive messages from communities you\'re part of';
      case _keyPersonalMessages:
        return 'Get notified of new personal messages';
      case _keyChallengeUpdates:
        return 'Receive updates about challenges and competitions';
      case _keyMomentNotifications:
        return 'Get notified of new moments and highlights';
      default:
        return '';
    }
  }

  // Get all preference keys
  List<String> getAllPreferenceKeys() {
    return _defaultPreferences.keys.toList();
  }

  // Check if a preference is enabled
  Future<bool> isPreferenceEnabled(String key) async {
    return await getNotificationPreference(key);
  }

  // Toggle a preference
  Future<void> togglePreference(String key) async {
    final currentValue = await getNotificationPreference(key);
    await setNotificationPreference(key, !currentValue);
  }

  // Get preference icon
  String getPreferenceIcon(String key) {
    switch (key) {
      case _keyEventReminders:
        return 'event';
      case _keyRSVPConfirmations:
        return 'rsvp';
      case _keyEventUpdates:
        return 'update';
      case _keyCheckInReminders:
        return 'check_circle';
      case _keyCommunityMessages:
        return 'group';
      case _keyPersonalMessages:
        return 'message';
      case _keyChallengeUpdates:
        return 'emoji_events';
      case _keyMomentNotifications:
        return 'flash_on';
      default:
        return 'notifications';
    }
  }

  // Get notification types for UI
  List<String> getNotificationTypes() {
    return _defaultPreferences.keys.toList();
  }

  // Get reminder time options
  List<int> getReminderTimeOptions() {
    return [5, 10, 15, 30, 60, 120, 1440]; // 5 min, 10 min, 15 min, 30 min, 1 hour, 2 hours, 1 day
  }
} 