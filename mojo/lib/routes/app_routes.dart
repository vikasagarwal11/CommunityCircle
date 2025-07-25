import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/auth_providers.dart';
import '../views/phone_auth_screen.dart';
import '../views/home_screen.dart';
import '../views/community_details_screen.dart';
import '../views/edit_community_screen.dart';
import '../views/search_screen.dart';
import '../views/public_home_screen.dart';
import '../views/create_community_screen.dart';
import '../views/profile_screen.dart';
import '../views/chat_screen.dart';
import '../views/personal_chat_screen.dart';
import '../views/message_search_screen.dart';
import '../views/admin_management_screen.dart';
import '../views/join_requests_review_screen.dart';
import '../views/add_participants_screen.dart';
import '../views/group_selection_screen.dart';
import '../views/call_screen.dart';
import '../views/mock_call_screen.dart';
import '../views/event_list_screen.dart';
import '../views/create_event_screen.dart';
import '../views/event_details_screen.dart';
import '../views/calendar_screen.dart';
import '../views/event_communication_screen.dart';
import '../views/rsvp_management_screen.dart';
import '../views/notification_preferences_screen.dart';
import '../models/community_model.dart';
import '../models/event_model.dart';
import '../views/edit_event_screen.dart';
import '../widgets/error_widget.dart';
import '../views/main_navigation_screen.dart';


class AppRoutes {
  // Main routes
  static const String auth = '/auth';
  static const String home = '/home';
  static const String adminHome = '/admin-home';
  static const String businessHome = '/business-home';
  static const String moderatorHome = '/moderator-home';
  static const String publicHome = '/public-home';
  static const String phoneAuth = '/phone-auth';
  static const String splash = '/splash';
  static const String loading = '/loading';
  static const String onboarding = '/onboarding';
  static const String welcome = '/welcome';
  
  // Community routes
  static const String communityDetails = '/community-details';
  static const String createCommunity = '/create-community';
  static const String editCommunity = '/edit-community';
  static const String adminManagement = '/admin-management';
  static const String joinRequestsReview = '/join-requests-review';
  static const String editEvent = '/edit-event';
  
  // Chat routes
  static const String chat = '/chat';
  static const String personalChat = '/personal-chat';
  static const String messageSearch = '/message-search';
  static const String addParticipants = '/add-participants';
  static const String groupSelection = '/group-selection';
  static const String call = '/call';
  
  // Event routes
  static const String eventList = '/event-list';
  static const String eventDetails = '/event-details';
  static const String createEvent = '/create-event';
  static const String calendar = '/calendar';
  static const String eventCommunication = '/event-communication';
  static const String rsvpManagement = '/rsvp-management';
  static const String notificationPreferences = '/notification-preferences';
  
  // Moment routes
  static const String momentDetails = '/moment-details';
  static const String createMoment = '/create-moment';
  
  // Challenge routes
  static const String challengeDetails = '/challenge-details';
  static const String createChallenge = '/create-challenge';
  
  // Poll routes
  static const String pollDetails = '/poll-details';
  static const String createPoll = '/create-poll';
  
  // Gallery routes
  static const String gallery = '/gallery';
  
  // Member routes
  static const String members = '/members';
  
  // Profile routes
  static const String profile = '/profile';
  
  // Search routes
  static const String search = '/search';
  
  // Settings routes
  static const String settings = '/settings';
  
  // Notification routes
  static const String notifications = '/notifications';
  
  // Help routes
  static const String help = '/help';
  static const String about = '/about';
  static const String privacyPolicy = '/privacy-policy';
  static const String termsOfService = '/terms-of-service';
  static const String contact = '/contact';
  static const String feedback = '/feedback';
  
  // Social routes
  static const String inviteFriends = '/invite-friends';
  static const String shareApp = '/share-app';
  static const String rateApp = '/rate-app';
  
  // Developer routes
  static const String developerInfo = '/developer-info';
  static const String debug = '/debug';
  static const String test = '/test';
  static const String demo = '/demo';
  
  // Error routes
  static const String error = '/error';
  static const String maintenance = '/maintenance';
  static const String update = '/update';
  static const String forceUpdate = '/force-update';
  static const String unsupported = '/unsupported';
  static const String notFound = '/not-found';
  static const String unauthorized = '/unauthorized';
  static const String forbidden = '/forbidden';
  static const String tooManyRequests = '/too-many-requests';
  static const String serviceUnavailable = '/service-unavailable';
  static const String gatewayTimeout = '/gateway-timeout';
  static const String badGateway = '/bad-gateway';
  static const String internalServerError = '/internal-server-error';
  static const String badRequest = '/bad-request';
  static const String conflict = '/conflict';
  static const String gone = '/gone';
  static const String lengthRequired = '/length-required';
  static const String payloadTooLarge = '/payload-too-large';
  static const String uriTooLong = '/uri-too-long';
  static const String unsupportedMediaType = '/unsupported-media-type';
  static const String rangeNotSatisfiable = '/range-not-satisfiable';
  static const String expectationFailed = '/expectation-failed';
  static const String imATeapot = '/im-a-teapot';
  static const String misdirectedRequest = '/misdirected-request';
  static const String unprocessableEntity = '/unprocessable-entity';
  static const String locked = '/locked';
  static const String failedDependency = '/failed-dependency';
  static const String tooEarly = '/too-early';
  static const String upgradeRequired = '/upgrade-required';
  static const String preconditionRequired = '/precondition-required';
  static const String requestHeaderFieldsTooLarge = '/request-header-fields-too-large';
  static const String unavailableForLegalReasons = '/unavailable-for-legal-reasons';
  static const String notImplemented = '/not-implemented';
  static const String httpVersionNotSupported = '/http-version-not-supported';
  static const String variantAlsoNegotiates = '/variant-also-negotiates';
  static const String insufficientStorage = '/insufficient-storage';
  static const String loopDetected = '/loop-detected';
  static const String notExtended = '/not-extended';
  static const String networkAuthenticationRequired = '/network-authentication-required';
  static const String networkConnectTimeoutError = '/network-connect-timeout-error';
  static const String networkReadTimeoutError = '/network-read-timeout-error';
  static const String networkSendTimeoutError = '/network-send-timeout-error';
  static const String networkTimeoutError = '/network-timeout-error';
  static const String networkError = '/network-error';
  static const String serverError = '/server-error';
  static const String unknownError = '/unknown-error';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case auth:
        return MaterialPageRoute(
          builder: (_) => const PhoneAuthScreen(),
        );
      case home:
        return MaterialPageRoute(
          builder: (_) => const MainNavigationScreen(),
        );
      case adminHome:
        return MaterialPageRoute(
          builder: (_) => const MainNavigationScreen(),
        );
      case businessHome:
        return MaterialPageRoute(
          builder: (_) => const MainNavigationScreen(),
        );
      case moderatorHome:
        return MaterialPageRoute(
          builder: (_) => const MainNavigationScreen(),
        );
      case publicHome:
        return MaterialPageRoute(
          builder: (_) => const PublicHomeScreen(),
        );
      case phoneAuth:
        return MaterialPageRoute(
          builder: (_) => const PhoneAuthScreen(),
        );
      case communityDetails:
        final communityId = settings.arguments as String?;
        if (communityId == null) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(
                child: Text('Community ID is required'),
              ),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => CommunityDetailsScreen(communityId: communityId),
        );
      case search:
        final initialQuery = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => SearchScreen(initialQuery: initialQuery),
        );
      case createCommunity:
        final eventTemplate = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => CreateCommunityScreen(eventTemplate: eventTemplate),
        );
      case editCommunity:
        final args = settings.arguments;
        CommunityModel? community;
        
        if (args is CommunityModel) {
          community = args;
        } else if (args is Map<String, dynamic>) {
          final communityData = args['community'] as Map<String, dynamic>?;
          if (communityData != null) {
            community = CommunityModel.fromMap(communityData, '');
          }
        }
        
        if (community == null) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(
                child: Text('Community not found'),
              ),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => EditCommunityScreen(community: community!),
        );
      case profile:
        final userId = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => ProfileScreen(userId: userId),
        );
      case chat:
        final args = settings.arguments;
        String? communityId;
        
        if (args is String) {
          communityId = args;
        } else if (args is Map<String, dynamic>) {
          communityId = args['communityId'] as String?;
        }
        
        if (communityId == null) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(
                child: Text('Community ID is required'),
              ),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => ChatScreen(communityId: communityId!),
        );
      case personalChat:
        final args = settings.arguments;
        String? otherUserId;
        
        if (args is String) {
          otherUserId = args;
        } else if (args is Map<String, dynamic>) {
          otherUserId = args['otherUserId'] as String?;
        }
        
        if (otherUserId == null) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(
                child: Text('User ID is required'),
              ),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => PersonalChatScreen(otherUserId: otherUserId!),
        );
      case messageSearch:
        final args = settings.arguments as Map<String, dynamic>?;
        final chatId = args?['chatId'] as String?;
        final otherUserId = args?['otherUserId'] as String?;
        final otherUserName = args?['otherUserName'] as String?;
        
        if (chatId == null || otherUserId == null || otherUserName == null) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(
                child: Text('Missing required parameters'),
              ),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => MessageSearchScreen(
            chatId: chatId,
            otherUserId: otherUserId,
            otherUserName: otherUserName,
          ),
        );
      case addParticipants:
        final args = settings.arguments as Map<String, dynamic>?;
        final chatId = args?['chatId'] as String?;
        final isConvertingToGroupStr = args?['isConvertingToGroup'] as String? ?? 'false';
        final isConvertingToGroup = isConvertingToGroupStr == 'true';
        final currentGroupName = args?['currentGroupName'] as String?;
        
        if (chatId == null) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(
                child: Text('Chat ID is required'),
              ),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => AddParticipantsScreen(
            chatId: chatId,
            isConvertingToGroup: isConvertingToGroup,
            currentGroupName: currentGroupName,
          ),
        );
      case groupSelection:
        final args = settings.arguments as Map<String, dynamic>?;
        final otherUserId = args?['otherUserId'] as String?;
        final otherUserName = args?['otherUserName'] as String?;
        
        if (otherUserId == null || otherUserName == null) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(
                child: Text('User information is required'),
              ),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => GroupSelectionScreen(
            otherUserId: otherUserId,
            otherUserName: otherUserName,
          ),
        );
      case call:
        final args = settings.arguments as Map<String, dynamic>?;
        final callId = args?['callId'] as String?;
        final chatId = args?['chatId'] as String?;
        final callType = args?['callType'] as String?;
        final isIncoming = args?['isIncoming'] as bool? ?? false;
        
        if (callId == null || chatId == null || callType == null) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(
                child: Text('Missing call parameters'),
              ),
            ),
          );
        }
        
        // Use MockCallScreen for simulator testing
        return MaterialPageRoute(
          builder: (_) => MockCallScreen(
            callId: callId,
            chatId: chatId,
            callType: callType,
            chatType: 'personal', // Default to personal, can be updated
            participants: [chatId], // Simplified for mock
          ),
        );
      case adminManagement:
        final args = settings.arguments;
        CommunityModel? community;
        
        if (args is CommunityModel) {
          community = args;
        } else if (args is Map<String, dynamic>) {
          final communityData = args['community'] as Map<String, dynamic>?;
          if (communityData != null) {
            community = CommunityModel.fromMap(communityData, '');
          }
        }
        
        if (community == null) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(
                child: Text('Community not found'),
              ),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => AdminManagementScreen(community: community!),
        );
      case joinRequestsReview:
        final args = settings.arguments;
        CommunityModel? community;
        
        if (args is CommunityModel) {
          community = args;
        } else if (args is Map<String, dynamic>) {
          final communityData = args['community'] as Map<String, dynamic>?;
          if (communityData != null) {
            community = CommunityModel.fromMap(communityData, '');
          }
        }
        
        if (community == null) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(
                child: Text('Community not found'),
              ),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => JoinRequestsReviewScreen(community: community!),
        );
      case 'settings':
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: const Text('Settings'),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.construction, size: 64, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
                  const SizedBox(height: 24),
                  const Text('Coming Soon!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  const Text('This feature is under construction. Stay tuned!', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Back to Home'),
                  ),
                ],
              ),
            ),
          ),
        );
      case eventList:
        final communityId = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => EventListScreen(communityId: communityId, isTab: false),
        );
      case eventDetails:
        final args = settings.arguments as Map<String, dynamic>?;
        final eventId = args?['eventId'] as String?;
        final communityId = args?['communityId'] as String?;
        
        if (eventId == null) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(
                child: Text('Event ID is required'),
              ),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => EventDetailsScreen(eventId: eventId, communityId: communityId),
        );
      case createEvent:
        final args = settings.arguments as Map<String, dynamic>?;
        final communityId = args?['communityId'] as String?;
        final templateData = args?['templateData'] as Map<String, dynamic>?;
        
        if (communityId == null) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(
                child: Text('Community ID is required'),
              ),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => CreateEventScreen(
            communityId: communityId,
            templateData: templateData,
          ),
        );
      case calendar:
        return MaterialPageRoute(
          builder: (_) => const CalendarScreen(),
        );
      case eventCommunication:
        final args = settings.arguments as Map<String, dynamic>?;
        final eventId = args?['eventId'] as String?;
        final communityId = args?['communityId'] as String?;
        
        if (eventId == null) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(
                child: Text('Event ID is required'),
              ),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => EventCommunicationScreen(eventId: eventId, communityId: communityId),
        );
      case rsvpManagement:
        final args = settings.arguments as Map<String, dynamic>?;
        final eventId = args?['eventId'] as String?;
        final communityId = args?['communityId'] as String?;
        
        if (eventId == null) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(
                child: Text('Event ID is required'),
              ),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => RsvpManagementScreen(eventId: eventId, communityId: communityId),
        );
      case notificationPreferences:
        return MaterialPageRoute(
          builder: (_) => const NotificationPreferencesScreen(),
        );
      case notifications:
      case help:
      case about:
      case privacyPolicy:
      case termsOfService:
      case contact:
      case feedback:
      case inviteFriends:
      case shareApp:
      case rateApp:
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: Text(settings.name!.split('/').last.replaceAll('-', ' ').toUpperCase()),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.construction, size: 64, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
                  const SizedBox(height: 24),
                  const Text('Coming Soon!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  const Text('This feature is under construction. Stay tuned!', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Back to Home'),
                  ),
                ],
              ),
            ),
          ),
        );
      case editEvent:
        final args = settings.arguments as Map<String, dynamic>?;
        final event = args?['event'] as EventModel?;
        final community = args?['community'] as CommunityModel?;
        if (event != null && community != null) {
          return MaterialPageRoute(
            builder: (_) => EditEventScreen(event: event!, community: community!),
          );
        }
        return MaterialPageRoute(
          builder: (_) => ErrorWidget('Event not found'),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(
              child: Text('Route not found'),
            ),
          ),
        );
    }
  }
}

class AuthGuard extends ConsumerWidget {
  final Widget child;
  
  const AuthGuard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    
    return authState.when(
      data: (state) {
        switch (state) {
          case AuthState.authenticated:
            return child;
          case AuthState.unauthenticated:
            return const PhoneAuthScreen();
          case AuthState.loading:
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
        }
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (_, __) => const PhoneAuthScreen(),
    );
  }
} 