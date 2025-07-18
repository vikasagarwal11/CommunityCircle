import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/community_model.dart';
import '../models/user_model.dart';
import '../core/constants.dart';
import 'package:logger/logger.dart';

class WelcomeFlashScreen extends HookWidget {
  final CommunityModel community;
  final UserModel user;
  final VoidCallback onDismiss;

  const WelcomeFlashScreen({
    super.key,
    required this.community,
    required this.user,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final logger = Logger();
    final isVisible = useState(true);
    final opacity = useAnimationController(
      duration: const Duration(milliseconds: 300),
    );

    void _dismiss(BuildContext context, Logger logger) {
      isVisible.value = false;
      opacity.reverse().then((_) {
        logger.i('Welcome flash screen dismissed for community: ${community.id}');
        onDismiss();
      });
    }

    // Auto-dismiss after 4 seconds
    useEffect(() {
      final timer = Future.delayed(const Duration(seconds: 4), () {
        if (isVisible.value) {
          _dismiss(context, logger);
        }
      });

      return () => timer;
    }, []);

    // Fade in animation
    useEffect(() {
      opacity.forward();
      return null;
    }, []);

    return AnimatedBuilder(
      animation: opacity,
      builder: (context, child) {
        return Opacity(
          opacity: opacity.value,
          child: Material(
            color: Colors.black.withValues(alpha: 0.8),
            child: SafeArea(
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(AppConstants.defaultPadding),
                  padding: const EdgeInsets.all(AppConstants.defaultPadding * 1.5),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Close button
                      Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          onPressed: () => _dismiss(context, logger),
                          icon: const Icon(Icons.close),
                          style: IconButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                          ),
                        ),
                      ),
                      
                      // Welcome icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: Icon(
                          Icons.waving_hand,
                          size: 40,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      
                      const SizedBox(height: AppConstants.defaultPadding),
                      
                      // Welcome title
                      Text(
                        'Welcome to ${community.name}!',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: AppConstants.smallPadding),
                      
                      // Welcome message
                      if (community.welcomeMessage.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(AppConstants.defaultPadding),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.message_outlined,
                                    size: 16,
                                    color: Theme.of(context).colorScheme.secondary,
                                  ),
                                  const SizedBox(width: AppConstants.smallPadding),
                                  Text(
                                    'From Admin',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.secondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppConstants.smallPadding),
                              Text(
                                community.welcomeMessage,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppConstants.defaultPadding),
                      ],
                      
                      // Community info
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 16,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${community.memberCount} members',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: AppConstants.defaultPadding),
                      
                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _dismiss(context, logger),
                              icon: const Icon(Icons.explore_outlined),
                              label: const Text('Explore'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppConstants.smallPadding),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _dismiss(context, logger),
                              icon: const Icon(Icons.chat_bubble_outline),
                              label: const Text('Start Chat'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: AppConstants.smallPadding),
                      
                      // Auto-dismiss indicator
                      Text(
                        'This will dismiss automatically in a few seconds',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
} 