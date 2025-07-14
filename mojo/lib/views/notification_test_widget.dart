import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';

import '../providers/notification_providers.dart';

class NotificationTestWidget extends ConsumerWidget {
  const NotificationTestWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationState = ref.watch(notificationStateProvider);
    final inAppNotification = ref.watch(inAppNotificationProvider);
    final badgeCounts = ref.watch(badgeCountProvider);
    final mutePreferences = ref.watch(mutePreferencesProvider);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Notification Test',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            
            // Notification State
            _buildStatusSection(
              context,
              'Notification Service',
              notificationState.isInitialized ? '✅ Initialized' : '❌ Not Initialized',
              notificationState.error != null ? 'Error: ${notificationState.error}' : null,
            ),
            
            const SizedBox(height: 8),
            
            // FCM Token
            _buildStatusSection(
              context,
              'FCM Token',
              notificationState.fcmToken != null 
                  ? '✅ ${notificationState.fcmToken!.substring(0, 20)}...' 
                  : '❌ Not Available',
              null,
            ),
            
            const SizedBox(height: 16),
            
            // Test Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: notificationState.isInitialized
                        ? () => _testLocalNotification(ref)
                        : null,
                    child: const Text('Test Local Notification'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: notificationState.isInitialized
                        ? () => _testInAppNotification(ref)
                        : null,
                    child: const Text('Test In-App Banner'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: notificationState.isInitialized
                        ? () => _testBadgeCount(ref)
                        : null,
                    child: const Text('Test Badge Count'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: notificationState.isInitialized
                        ? () => _testMuteToggle(ref)
                        : null,
                    child: const Text('Test Mute Toggle'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Current State Display
            if (inAppNotification != null) ...[
              _buildStatusSection(
                context,
                'In-App Notification',
                '✅ ${inAppNotification.title}',
                inAppNotification.body,
              ),
              const SizedBox(height: 8),
            ],
            
            if (badgeCounts.isNotEmpty) ...[
              _buildStatusSection(
                context,
                'Badge Counts',
                '✅ ${badgeCounts.length} chats',
                badgeCounts.entries.map((e) => '${e.key}: ${e.value}').join(', '),
              ),
              const SizedBox(height: 8),
            ],
            
            if (mutePreferences.isNotEmpty) ...[
              _buildStatusSection(
                context,
                'Mute Preferences',
                '✅ ${mutePreferences.length} chats',
                mutePreferences.entries.map((e) => '${e.key}: ${e.value ? "Muted" : "Unmuted"}').join(', '),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection(
    BuildContext context,
    String title,
    String status,
    String? details,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          status,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (details != null) ...[
          const SizedBox(height: 2),
          Text(
            details,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  void _testLocalNotification(WidgetRef ref) {
    final logger = Logger();
    logger.i('Testing local notification');
    
    // Show in-app notification banner
    ref.read(inAppNotificationProvider.notifier).showMessageNotification(
      chatId: 'test_chat_123',
      senderName: 'Test User',
      message: 'This is a test message for local notification!',
    );
    
    // Also increment badge count to test real-time updates
    ref.read(badgeCountProvider.notifier).incrementBadge('test_chat_123');
  }

  void _testInAppNotification(WidgetRef ref) {
    final logger = Logger();
    logger.i('Testing in-app notification banner');
    
    ref.read(inAppNotificationProvider.notifier).showEventNotification(
      eventId: 'test_event_456',
      eventTitle: 'Test Event',
      communityName: 'Test Community',
    );
  }

  void _testBadgeCount(WidgetRef ref) {
    final logger = Logger();
    logger.i('Testing badge count');
    
    ref.read(badgeCountProvider.notifier).incrementBadge('test_chat_123');
  }

  void _testMuteToggle(WidgetRef ref) {
    final logger = Logger();
    logger.i('Testing mute toggle');
    
    ref.read(mutePreferencesProvider.notifier).toggleMute('test_chat_123');
  }
} 