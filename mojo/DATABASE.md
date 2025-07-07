# MOJO Database Architecture

## Overview

MOJO uses Firebase Firestore as the primary database with a clean architecture approach. All models are immutable and follow Flutter best practices with proper serialization/deserialization.

## Database Collections

### 1. `users`
- **Purpose**: Store user profiles and authentication data
- **Key Fields**: `id`, `phoneNumber`, `displayName`, `role`, `communityIds`
- **Indexes**: `phoneNumber`, `role`, `communityIds`

### 2. `communities`
- **Purpose**: Store community information and membership
- **Key Fields**: `id`, `name`, `adminUid`, `members`, `visibility`
- **Indexes**: `visibility`, `isBusiness`, `members`, `adminUid`

### 3. `events`
- **Purpose**: Store community events and RSVPs
- **Key Fields**: `id`, `communityId`, `title`, `date`, `rsvps`
- **Indexes**: `communityId`, `date`, `creatorUid`

### 4. `messages`
- **Purpose**: Store chat messages with reactions and threads
- **Key Fields**: `id`, `communityId`, `userId`, `text`, `timestamp`
- **Indexes**: `communityId`, `timestamp`, `userId`

### 5. `moments`
- **Purpose**: Store ephemeral 24-hour content
- **Key Fields**: `id`, `communityId`, `userId`, `expiresAt`
- **Indexes**: `communityId`, `expiresAt`, `userId`

### 6. `polls`
- **Purpose**: Store community polls and voting data
- **Key Fields**: `id`, `communityId`, `question`, `votes`
- **Indexes**: `communityId`, `isActive`, `createdAt`

### 7. `challenges`
- **Purpose**: Store community challenges and leaderboards
- **Key Fields**: `id`, `communityId`, `participants`, `startDate`, `endDate`
- **Indexes**: `communityId`, `isActive`, `startDate`, `endDate`

## Models

### UserModel
```dart
class UserModel {
  final String id;
  final String phoneNumber;
  final String? displayName;
  final String role; // "admin", "member", "anonymous", "business"
  final List<String> communityIds;
  final Map<String, String> communityRoles; // communityId -> role
  final List<String> badges;
  final int totalPoints;
  // ... other fields
}
```

**Key Features:**
- Role-based access control
- Community membership tracking
- Gamification support (badges, points)
- Business profile support

### CommunityModel
```dart
class CommunityModel {
  final String id;
  final String name;
  final String adminUid;
  final String visibility; // "public", "private_open", "private_invite"
  final List<String> members;
  final List<String> bannedUsers;
  final bool isBusiness;
  // ... other fields
}
```

**Key Features:**
- Multiple visibility levels
- Member management
- Ban/unban functionality
- Business community support

### EventModel
```dart
class EventModel {
  final String id;
  final String communityId;
  final String title;
  final DateTime date;
  final Map<String, String> rsvps; // userId -> status
  final Map<String, DateTime> checkIns;
  // ... other fields
}
```

**Key Features:**
- RSVP management
- Check-in tracking
- Event visibility controls
- Past/upcoming event filtering

### MessageModel
```dart
class MessageModel {
  final String id;
  final String communityId;
  final String userId;
  final String text;
  final String? mediaUrl;
  final String? threadId;
  final Map<String, List<String>> reactions; // emoji -> [userId1, userId2, ...]
  final List<String> mentions;
  // ... other fields
}
```

**Key Features:**
- Threaded replies
- Emoji reactions
- User mentions
- Media support (images, videos, documents)

### MomentModel
```dart
class MomentModel {
  final String id;
  final String communityId;
  final String userId;
  final DateTime expiresAt; // 24 hours from creation
  final Map<String, List<String>> reactions;
  final List<MomentComment> comments;
  // ... other fields
}
```

**Key Features:**
- 24-hour expiration
- Real-time reactions
- Comment system
- Poll support within moments

### PollModel
```dart
class PollModel {
  final String id;
  final String communityId;
  final String question;
  final List<PollOption> options;
  final Map<String, String> votes; // userId -> optionId
  final DateTime? expiresAt;
  // ... other fields
}
```

**Key Features:**
- Multiple choice options
- Vote tracking
- Optional expiration
- Percentage calculations

### ChallengeModel
```dart
class ChallengeModel {
  final String id;
  final String communityId;
  final String title;
  final String type; // "daily", "weekly", "monthly", "custom"
  final Map<String, ChallengeParticipant> participants;
  final List<String> rewards;
  // ... other fields
}
```

**Key Features:**
- Leaderboard system
- Participant tracking
- Reward system
- Multiple challenge types

## Services

### DatabaseService
Central service for all CRUD operations with proper error handling and logging.

**Key Methods:**
- `getUser()`, `createUser()`, `updateUser()`, `deleteUser()`
- `getCommunity()`, `createCommunity()`, `updateCommunity()`, `deleteCommunity()`
- `getEvent()`, `createEvent()`, `updateEvent()`, `deleteEvent()`
- `getMessage()`, `createMessage()`, `updateMessage()`, `deleteMessage()`
- `getMoment()`, `createMoment()`, `updateMoment()`, `deleteMoment()`
- `getPoll()`, `createPoll()`, `updatePoll()`, `deletePoll()`
- `getChallenge()`, `createChallenge()`, `updateChallenge()`, `deleteChallenge()`
- `batchWrite()` - For complex operations
- `runTransaction()` - For atomic operations

### CommunityService
Specialized service for community operations with business logic.

**Key Methods:**
- `getPublicCommunities()` - Fetch public communities
- `getUserCommunities()` - Fetch user's communities
- `getBusinessCommunities()` - Fetch business communities
- `searchCommunities()` - Search communities by name/description
- `createCommunity()` - Create new community with validation
- `joinCommunity()` - Join community with checks
- `leaveCommunity()` - Leave community with admin checks
- `banUser()` - Ban user (admin only)
- `unbanUser()` - Unban user (admin only)
- `transferAdminRole()` - Transfer admin role
- `updateCommunitySettings()` - Update community settings
- `getCommunityStats()` - Get community analytics

## Providers (Riverpod)

### Service Providers
```dart
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

final communityServiceProvider = Provider<CommunityService>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  return CommunityService(databaseService);
});
```

### Data Providers
```dart
// User providers
final userProvider = FutureProvider.family<UserModel?, String>((ref, userId) async {
  final databaseService = ref.watch(databaseServiceProvider);
  return await databaseService.getUser(userId);
});

// Community providers
final communityProvider = FutureProvider.family<CommunityModel?, String>((ref, communityId) async {
  final databaseService = ref.watch(databaseServiceProvider);
  return await databaseService.getCommunity(communityId);
});

final publicCommunitiesProvider = FutureProvider<List<CommunityModel>>((ref) async {
  final communityService = ref.watch(communityServiceProvider);
  return await communityService.getPublicCommunities();
});

// Event providers
final communityEventsProvider = FutureProvider.family<List<EventModel>, String>((ref, communityId) async {
  // ... implementation
});

// Message providers (real-time)
final communityMessagesProvider = StreamProvider.family<List<MessageModel>, String>((ref, communityId) {
  return FirebaseFirestore.instance
      .collection('messages')
      .where('communityId', isEqualTo: communityId)
      .orderBy('timestamp', descending: true)
      .limit(50)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) {
          return MessageModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }).toList();
      });
});

// Moment providers (real-time)
final communityMomentsProvider = StreamProvider.family<List<MomentModel>, String>((ref, communityId) {
  return FirebaseFirestore.instance
      .collection('moments')
      .where('communityId', isEqualTo: communityId)
      .where('expiresAt', isGreaterThan: DateTime.now())
      .orderBy('expiresAt', descending: true)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) {
          return MomentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }).toList();
      });
});
```

### State Notifiers
```dart
// Community notifier for state management
class CommunityNotifier extends StateNotifier<AsyncValue<List<CommunityModel>>> {
  final CommunityService _communityService;

  CommunityNotifier(this._communityService) : super(const AsyncValue.loading());

  Future<void> loadPublicCommunities() async {
    state = const AsyncValue.loading();
    try {
      final communities = await _communityService.getPublicCommunities();
      state = AsyncValue.data(communities);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> searchCommunities(String query) async {
    state = const AsyncValue.loading();
    try {
      final communities = await _communityService.searchCommunities(query);
      state = AsyncValue.data(communities);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final communityNotifierProvider = StateNotifierProvider<CommunityNotifier, AsyncValue<List<CommunityModel>>>((ref) {
  final communityService = ref.watch(communityServiceProvider);
  return CommunityNotifier(communityService);
});
```

## Usage Examples

### Creating a Community
```dart
class CreateCommunityScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final communityService = ref.watch(communityServiceProvider);

    return ElevatedButton(
      onPressed: () async {
        try {
          final communityId = await communityService.createCommunity(
            name: 'My Community',
            description: 'A great community',
            adminUid: currentUserId,
            visibility: 'public',
            isBusiness: false,
          );
          // Navigate to community
        } catch (e) {
          // Handle error
        }
      },
      child: Text('Create Community'),
    );
  }
}
```

### Joining a Community
```dart
class CommunityCard extends ConsumerWidget {
  final CommunityModel community;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final communityService = ref.watch(communityServiceProvider);

    return ElevatedButton(
      onPressed: () async {
        try {
          await communityService.joinCommunity(community.id, currentUserId);
          // Show success message
        } catch (e) {
          // Handle error
        }
      },
      child: Text('Join Community'),
    );
  }
}
```

### Real-time Messages
```dart
class ChatScreen extends ConsumerWidget {
  final String communityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(communityMessagesProvider(communityId));

    return messagesAsync.when(
      data: (messages) => ListView.builder(
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[index];
          return MessageBubble(message: message);
        },
      ),
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
    );
  }
}
```

### Creating an Event
```dart
class CreateEventScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventNotifier = ref.watch(eventNotifierProvider(communityId));

    return ElevatedButton(
      onPressed: () async {
        final event = EventModel(
          id: '',
          communityId: communityId,
          title: 'My Event',
          description: 'A great event',
          date: DateTime.now().add(Duration(days: 7)),
          location: 'Somewhere',
          creatorUid: currentUserId,
          visibility: 'public',
          approvalRequired: false,
          createdAt: DateTime.now(),
          rsvps: {},
          checkIns: {},
        );

        await eventNotifier.createEvent(event);
      },
      child: Text('Create Event'),
    );
  }
}
```

## Security Rules

The database uses Firestore security rules to ensure data integrity and user privacy:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Community members can read community data
    match /communities/{communityId} {
      allow read: if request.auth != null && 
        (resource.data.visibility == 'public' || 
         request.auth.uid in resource.data.members);
      allow write: if request.auth != null && 
        request.auth.uid == resource.data.adminUid;
    }
    
    // Community members can read/write messages
    match /messages/{messageId} {
      allow read, write: if request.auth != null && 
        request.auth.uid in get(/databases/$(database)/documents/communities/$(resource.data.communityId)).data.members;
    }
    
    // Similar rules for events, moments, polls, challenges
  }
}
```

## Performance Considerations

1. **Indexes**: All queries have corresponding Firestore indexes
2. **Pagination**: Messages and moments use `limit()` for pagination
3. **Real-time**: Only critical data (messages, moments) use real-time listeners
4. **Caching**: Riverpod provides automatic caching and state management
5. **Batch Operations**: Use `batchWrite()` for multiple related operations
6. **Transactions**: Use `runTransaction()` for atomic operations

## Error Handling

All services include comprehensive error handling with logging:

```dart
try {
  final user = await databaseService.getUser(userId);
  // Handle success
} catch (e) {
  logger.e('Error fetching user: $e');
  // Handle error appropriately
}
```

## Testing

Each model includes proper `==`, `hashCode`, and `toString()` methods for testing. Services can be easily mocked for unit tests using Riverpod's dependency injection. 