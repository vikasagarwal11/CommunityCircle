import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/offline_providers.dart';
import '../core/constants.dart';
import '../core/theme.dart';

class OfflineStatusWidget extends HookConsumerWidget {
  const OfflineStatusWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offlineStatus = ref.watch(offlineStatusProvider);
    
    // Don't show anything if online and no pending actions
    if (offlineStatus.isOnline && !offlineStatus.hasPendingActions) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(AppConstants.smallPadding),
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding,
        vertical: AppConstants.smallPadding,
      ),
      decoration: BoxDecoration(
        color: offlineStatus.isOnline 
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(
          color: offlineStatus.isOnline 
              ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
              : Theme.of(context).colorScheme.error.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            offlineStatus.isOnline ? Icons.cloud_sync : Icons.cloud_off,
            size: 20,
            color: offlineStatus.isOnline 
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: AppConstants.smallPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  offlineStatus.isOnline ? 'Syncing...' : 'Offline Mode',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: offlineStatus.isOnline 
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.error,
                  ),
                ),
                if (offlineStatus.hasPendingActions) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${offlineStatus.pendingActions} action${offlineStatus.pendingActions == 1 ? '' : 's'} pending',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: offlineStatus.isOnline 
                          ? Theme.of(context).colorScheme.primary.withOpacity(0.7)
                          : Theme.of(context).colorScheme.error.withOpacity(0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (offlineStatus.isSyncing) ...[
            const SizedBox(width: AppConstants.smallPadding),
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  offlineStatus.isOnline 
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ],
          if (!offlineStatus.isOnline && offlineStatus.hasPendingActions) ...[
            const SizedBox(width: AppConstants.smallPadding),
            IconButton(
              onPressed: () {
                ref.read(offlineSyncNotifierProvider.notifier).manualSync();
              },
              icon: const Icon(Icons.sync, size: 20),
              tooltip: 'Sync now',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Compact offline indicator for app bar
class OfflineIndicator extends HookConsumerWidget {
  const OfflineIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offlineStatus = ref.watch(offlineStatusProvider);
    
    if (offlineStatus.isOnline) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(right: AppConstants.smallPadding),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off,
            size: 16,
            color: Theme.of(context).colorScheme.error,
          ),
          if (offlineStatus.hasPendingActions) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                offlineStatus.pendingActions.toString(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onError,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Offline banner for full-screen offline mode
class OfflineBanner extends HookConsumerWidget {
  final VoidCallback? onRetry;
  
  const OfflineBanner({super.key, this.onRetry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offlineStatus = ref.watch(offlineStatusProvider);
    
    if (offlineStatus.isOnline) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.error.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.cloud_off,
            color: Theme.of(context).colorScheme.error,
            size: 24,
          ),
          const SizedBox(width: AppConstants.smallPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'You\'re offline',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                if (offlineStatus.hasPendingActions) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${offlineStatus.pendingActions} action${offlineStatus.pendingActions == 1 ? '' : 's'} will sync when you\'re back online',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error.withOpacity(0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: AppConstants.smallPadding),
            TextButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
} 