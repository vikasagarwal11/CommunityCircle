import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../core/navigation_service.dart';
import '../providers/auth_providers.dart';
import 'home_screen.dart';
import 'event_list_screen.dart';
import 'chat_hub_screen.dart';
import 'personal_chat_hub_screen.dart';
import 'profile_screen.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _currentIndex = 0;
  bool _isDisposed = false;

  final List<Widget> _screens = [
    const HomeScreen(),
    const EventListScreen(),
    const ChatHubScreen(),
    const PersonalChatHubScreen(),
    const ProfileScreen(),
  ];

  final List<BottomNavigationBarItem> _bottomNavItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.home),
      label: 'Communities',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.event),
      label: 'Events',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.chat),
      label: 'Group Chat',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.person),
      label: '1:1 Chat',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.person_outline),
      label: 'Profile',
    ),
  ];

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authNotifierProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(
              child: Text('User not authenticated'),
            ),
          );
        }

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _currentIndex,
            onTap: (index) {
              if (_isDisposed) return;
              
              setState(() {
                _currentIndex = index;
              });
              
              // Track navigation analytics
              try {
                NavigationService.trackUserEngagement('bottom_nav_tap', parameters: {
                  'tab_index': index,
                  'tab_name': _bottomNavItems[index].label,
                });
              } catch (e) {
                // Ignore analytics errors
                print('Analytics error: $e');
              }
            },
            items: _bottomNavItems,
            selectedItemColor: Theme.of(context).colorScheme.primary,
            unselectedItemColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 8,
          ),
          floatingActionButton: _currentIndex == 0 
              ? FloatingActionButton(
                  onPressed: () {
                    if (_isDisposed) return;
                    
                    try {
                      NavigationService.trackUserEngagement('fab_create_community');
                      NavigationService.navigateToCreateCommunity();
                    } catch (e) {
                      print('Navigation error: $e');
                    }
                  },
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.add),
                  tooltip: 'Create Community',
                )
              : null,
        );
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              Text(
                'Error loading user data',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppConstants.smallPadding),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
} 