import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../core/constants.dart';
import '../core/navigation_service.dart';
import '../services/notification_preferences_service.dart';

class NotificationPreferencesScreen extends HookConsumerWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferencesService = NotificationPreferencesService();
    final preferences = useState<Map<String, bool>>({});
    final reminderTime = useState<int>(30);
    final quietHoursEnabled = useState<bool>(false);
    final quietHoursStart = useState<String>('22:00');
    final quietHoursEnd = useState<String>('08:00');
    final isLoading = useState<bool>(true);

    // Load preferences on init
    useEffect(() {
      _loadPreferences(preferencesService, preferences, reminderTime, quietHoursEnabled, quietHoursStart, quietHoursEnd, isLoading);
      return null;
    }, []);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Preferences'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => NavigationService.goBack(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadPreferences(preferencesService, preferences, reminderTime, quietHoursEnabled, quietHoursStart, quietHoursEnd, isLoading),
          ),
        ],
      ),
      body: isLoading.value
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: AppConstants.largePadding),
                  _buildNotificationTypes(context, preferences, preferencesService),
                  const SizedBox(height: AppConstants.largePadding),
                  _buildReminderSettings(context, reminderTime, preferencesService),
                  const SizedBox(height: AppConstants.largePadding),
                  _buildQuietHours(context, quietHoursEnabled, quietHoursStart, quietHoursEnd, preferencesService),
                  const SizedBox(height: AppConstants.largePadding),
                  _buildActions(context, preferences, preferencesService),
                ],
              ),
            ),
    );
  }

  Future<void> _loadPreferences(
    NotificationPreferencesService service,
    ValueNotifier<Map<String, bool>> preferences,
    ValueNotifier<int> reminderTime,
    ValueNotifier<bool> quietHoursEnabled,
    ValueNotifier<String> quietHoursStart,
    ValueNotifier<String> quietHoursEnd,
    ValueNotifier<bool> isLoading,
  ) async {
    try {
      final prefs = await service.getAllPreferences();
      preferences.value = prefs;
      
      final reminder = await service.getReminderTime();
      reminderTime.value = reminder;
      
      final quietHours = await service.getQuietHours();
      quietHoursEnabled.value = quietHours['enabled'] ?? false;
      quietHoursStart.value = quietHours['start'] ?? '22:00';
      quietHoursEnd.value = quietHours['end'] ?? '08:00';
    } catch (e) {
      // Handle error
    } finally {
      isLoading.value = false;
    }
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.notifications,
          size: 48,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: AppConstants.defaultPadding),
        Text(
          'Notification Preferences',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.smallPadding),
        Text(
          'Customize how and when you receive notifications',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationTypes(
    BuildContext context,
    ValueNotifier<Map<String, bool>> preferences,
    NotificationPreferencesService service,
  ) {
    final notificationTypes = service.getNotificationTypes();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notification Types',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.smallPadding),
        Text(
          'Choose which notifications you want to receive',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: AppConstants.defaultPadding),
        ...notificationTypes.map((type) => _buildNotificationTypeTile(
          context,
          type,
          preferences.value[type] ?? true,
          (value) {
            preferences.value = {...preferences.value, type: value};
            service.setNotificationPreference(type, value);
          },
          service,
        )),
      ],
    );
  }

  Widget _buildNotificationTypeTile(
    BuildContext context,
    String type,
    bool isEnabled,
    ValueChanged<bool> onChanged,
    NotificationPreferencesService service,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.smallPadding),
      child: SwitchListTile(
        title: Text(service.getPreferenceDisplayName(type)),
        subtitle: Text(service.getPreferenceDescription(type)),
        secondary: Icon(IconData(int.parse(service.getPreferenceIcon(type)), fontFamily: 'MaterialIcons')),
        value: isEnabled,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildReminderSettings(
    BuildContext context,
    ValueNotifier<int> reminderTime,
    NotificationPreferencesService service,
  ) {
    final reminderOptions = service.getReminderTimeOptions();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Event Reminder Time',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.smallPadding),
        Text(
          'How early should you be reminded about events?',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: AppConstants.defaultPadding),
        Card(
          child: Column(
            children: reminderOptions.map((option) => RadioListTile<int>(
              title: Text(_getReminderLabel(option)),
              value: option,
              groupValue: reminderTime.value,
              onChanged: (value) {
                if (value != null) {
                  reminderTime.value = value;
                  service.setReminderTime(value);
                }
              },
            )).toList(),
          ),
        ),
      ],
    );
  }

  String _getReminderLabel(int minutes) {
    if (minutes < 60) {
      return '$minutes minutes before';
    } else if (minutes == 60) {
      return '1 hour before';
    } else if (minutes == 120) {
      return '2 hours before';
    } else if (minutes == 1440) {
      return '1 day before';
    } else {
      return '${minutes ~/ 60} hours before';
    }
  }

  Widget _buildQuietHours(
    BuildContext context,
    ValueNotifier<bool> quietHoursEnabled,
    ValueNotifier<String> quietHoursStart,
    ValueNotifier<String> quietHoursEnd,
    NotificationPreferencesService service,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quiet Hours',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.smallPadding),
        Text(
          'Set times when you don\'t want to receive notifications',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: AppConstants.defaultPadding),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Enable Quiet Hours'),
                subtitle: const Text('Suppress notifications during specified hours'),
                value: quietHoursEnabled.value,
                onChanged: (value) {
                  quietHoursEnabled.value = value;
                  service.setQuietHours(value, quietHoursStart.value, quietHoursEnd.value);
                },
              ),
              if (quietHoursEnabled.value) ...[
                const Divider(),
                ListTile(
                  title: const Text('Start Time'),
                  subtitle: Text(quietHoursStart.value),
                  trailing: const Icon(Icons.access_time),
                  onTap: () => _showTimePicker(
                    context,
                    quietHoursStart.value,
                    (time) {
                      quietHoursStart.value = time;
                      service.setQuietHours(quietHoursEnabled.value, time, quietHoursEnd.value);
                    },
                  ),
                ),
                ListTile(
                  title: const Text('End Time'),
                  subtitle: Text(quietHoursEnd.value),
                  trailing: const Icon(Icons.access_time),
                  onTap: () => _showTimePicker(
                    context,
                    quietHoursEnd.value,
                    (time) {
                      quietHoursEnd.value = time;
                      service.setQuietHours(quietHoursEnabled.value, quietHoursStart.value, time);
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _showTimePicker(
    BuildContext context,
    String currentTime,
    ValueChanged<String> onTimeChanged,
  ) {
    final parts = currentTime.split(':');
    final initialHour = int.parse(parts[0]);
    final initialMinute = int.parse(parts[1]);

    showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
    ).then((time) {
      if (time != null) {
        final timeString = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
        onTimeChanged(timeString);
      }
    });
  }

  Widget _buildActions(
    BuildContext context,
    ValueNotifier<Map<String, bool>> preferences,
    NotificationPreferencesService service,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.defaultPadding),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  await service.resetToDefaults();
                  // Reload preferences
                  final prefs = await service.getAllPreferences();
                  preferences.value = prefs;
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Reset to Defaults'),
              ),
            ),
            const SizedBox(width: AppConstants.smallPadding),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  // Test notification
                  // TODO: Implement test notification
                },
                icon: const Icon(Icons.notifications),
                label: const Text('Test Notification'),
              ),
            ),
          ],
        ),
      ],
    );
  }
} 