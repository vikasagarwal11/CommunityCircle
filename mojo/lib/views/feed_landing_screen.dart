import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../models/event_model.dart';
import '../models/community_model.dart';
import '../providers/event_providers.dart';
import '../providers/community_providers.dart';
import '../core/constants.dart';
import '../core/navigation_service.dart';
import '../widgets/loading_widget.dart';

class FeedLandingScreen extends HookConsumerWidget {
  const FeedLandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = useState(0);
    final eventsAsync = ref.watch(liveEventsProvider);
    final communitiesAsync = ref.watch(trendingCommunitiesProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Main feed content
          PageView.builder(
            itemCount: 10, // Mock count for demo
            onPageChanged: (index) => currentIndex.value = index,
            itemBuilder: (context, index) {
              return _buildFeedItem(context, ref, index);
            },
          ),
          
          // Top navigation bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'MOJO',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.white),
                    onPressed: () => NavigationService.navigateToSearch(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.person, color: Colors.white),
                    onPressed: () => NavigationService.navigateToProfile(),
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom navigation
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(context, Icons.home, 'Home', true),
                  _buildNavItem(context, Icons.explore, 'Explore', false),
                  _buildNavItem(context, Icons.add_circle, 'Create', false),
                  _buildNavItem(context, Icons.chat, 'Chat', false),
                  _buildNavItem(context, Icons.person, 'Profile', false),
                ],
              ),
            ),
          ),
          
          // Page indicator
          Positioned(
            top: 100,
            right: 16,
            child: Column(
              children: List.generate(5, (index) => Container(
                margin: const EdgeInsets.symmetric(vertical: 2),
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: currentIndex.value == index 
                      ? Colors.white 
                      : Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedItem(BuildContext context, WidgetRef ref, int index) {
    // Mock data for demo
    final mockEvent = EventModel(
      id: 'event_$index',
      communityId: 'community_$index',
      title: 'Amazing Event ${index + 1}',
      description: 'Join us for an incredible experience with amazing people!',
      date: DateTime.now().add(Duration(days: index)),
      location: 'Virtual Event',
      creatorUid: 'user_$index',
      visibility: 'public',
      approvalRequired: false,
      createdAt: DateTime.now(),
      rsvps: {},
      checkIns: {},
      category: EventModel.categoryMeeting,
    );

    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          // Background video/image placeholder
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.blue.withOpacity(0.3),
                  Colors.purple.withOpacity(0.3),
                ],
              ),
            ),
            child: Center(
              child: Icon(
                Icons.play_circle_filled,
                size: 80,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ),
          
          // Content overlay
          Positioned(
            bottom: 100,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Community name
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: Text(
                        'C',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Community ${index + 1}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.favorite_border, color: Colors.white),
                      onPressed: () {},
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Event title
                Text(
                  mockEvent.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 4),
                
                // Event description
                Text(
                  mockEvent.description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 12),
                
                // Action buttons
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => NavigationService.navigateToEventDetails(mockEvent.id),
                      icon: const Icon(Icons.event),
                      label: const Text('Join Event'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => NavigationService.navigateToCommunityDetails(mockEvent.communityId),
                      icon: const Icon(Icons.group),
                      label: const Text('View Community'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label, bool isActive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: isActive ? Colors.white : Colors.white.withOpacity(0.6),
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
} 