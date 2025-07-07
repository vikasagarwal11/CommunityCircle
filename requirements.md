# Cursor Prompt: Flutter Community App with Disruptive UI/UX, Advanced Chat, Event Management, and Live Moments

## Project Overview
Develop a cross-platform mobile app (iOS/Android) using Flutter and Firebase to disrupt Meetup, WhatsApp, Meta, Slack, and Circle. The app manages interest-based communities with a **modern, sleek, beautiful, and intuitive UI/UX**, **advanced chat**, **robust event management**, and **Live Moments** (ephemeral media/polls) to drive real-time engagement. It supports local businesses/realtors with public communities/events (e.g., “Free Ice Cream Day”) and **Dynamic Community Challenges** with discount codes. Use **phone number authentication** as the primary signup/login method. Target ~1,000 users within Firebase’s free tier, ensuring fast performance, minimal controls (1–2 buttons per screen), and a delightful experience to encourage platform switching.

## Tech Stack
- **Frontend**: Flutter (Dart), Material 3.
- **Backend**: Firebase (Authentication, Firestore, Storage, Analytics, Crashlytics, FCM, Cloud Functions).
- **Tools**: Firebase Emulators, Cursor.

## Setup Instructions
1. Create a Flutter project: `flutter create community_app`.
2. Configure Firebase:
   - Run `flutterfire configure` for iOS/Android.
   - Enable Authentication (Phone, Anonymous), Firestore, Storage, Analytics, Crashlytics, FCM, Cloud Functions.
   - Apply provided Firestore security rules (see Firestore Security Rules section).
3. Add dependencies in `pubspec.yaml`:
   ```yaml
   dependencies:
     flutter:
       sdk: flutter
     firebase_core: latest
     firebase_auth: latest
     cloud_firestore: latest
     firebase_storage: latest
     firebase_analytics: latest
     firebase_crashlytics: latest
     firebase_messaging: latest
     cloud_functions: latest
     flutter_riverpod: latest
     hooks_riverpod: latest
     lottie: latest
     table_calendar: latest
     logger: latest
   ```
4. Set up Firebase Emulators for local testing.
5. Structure project:
   ```
   lib/
     core/ # constants.dart, theme.dart, navigation.dart
     models/ # User, Community, Event, Message, Moment
     services/ # AuthService, FirestoreService, MomentService
     views/ # phone_auth_screen.dart, chat_screen.dart, moments_screen.dart
     widgets/ # chat_bubble_widget.dart, event_card_widget.dart, moment_card_widget.dart
     routes/ # named routes
     providers/ # Riverpod providers
     main.dart
   ```

## Functional Requirements
Implement all features with a focus on **phone number authentication**, **advanced chat**, **event management**, **Live Moments**, and **business features**, adhering to provided project rules.

### 1. User Authentication
- **1.1 Sign Up**: Phone number authentication (SMS OTP verification) or optional anonymous login. Store in Firestore (`users/{uid}`: `phone_number`, `display_name`, `profile_picture`, `points`, `badges`, `created_at`, `role`, `is_business`).
  - **Roles**: `admin` (community/event admins), `member` (authenticated users), `anonymous` (limited access), `business` (business owners with dashboard access).
  - **Fields**:
    - `phone_number`: string (required for non-anonymous, null for anonymous).
    - `display_name`: string (optional, default "Guest" for anonymous).
    - `profile_picture`: string (URL, max 2MB, optional).
    - `points`: number (default 0, for gamification).
    - `badges`: array<string> (default [], for gamification).
    - `created_at`: timestamp.
    - `role`: string (`admin`, `member`, `anonymous`, default `member` for phone auth, `anonymous` for anonymous login).
    - `is_business`: boolean (default false, true for business users).
- **1.2 Log In**: Phone number (OTP) or anonymous login. Redirect authenticated users (`member`, `admin`, `business`) to Home Screen, anonymous users to Public Home Screen.
- **1.3 Profile Management**: Edit `display_name`, `profile_picture` (max 2MB), delete account (remove `users/{uid}`, associated data). Only authenticated users (`member`, `admin`, `business`) can edit/delete.
- **1.4 Log Out**: Clear session, redirect to Phone Auth Screen.
- **1.5 Route Protection**:
  - Private routes (e.g., Community Details, Chat, Moments, Admin Management): Accessible to `member`, `admin`, `business` roles.
  - Admin routes (e.g., Admin Management Screen): Accessible only to `admin` or `business` roles where `user.uid == communities/{community_id}.admin_uid`.
  - Business routes (e.g., Business Dashboard): Accessible only to `business` role.
  - Redirect unauthenticated or `anonymous` users to Phone Auth Screen.
- **1.6 Anonymous Access**:
  - View public communities/events (read `communities` where `visibility == "public"`, `events` where `visibility == "public"`).
  - No access to Chat, Moments, Polls, Challenges, or private content.
  - Cannot post, comment, react, or RSVP.
- **1.7 Role-Based Privileges**:
  - **Anonymous**: Read public communities/events only.
  - **Member**: Join communities, post messages, create Moments, RSVP to events, vote in polls, participate in challenges, earn points/badges.
  - **Admin**: All `member` privileges plus create/edit/delete communities/events, moderate content (delete messages, Moments, media), approve join/RSVP requests, pin items, view admin dashboard.
  - **Business**: All `admin` privileges for owned communities (`is_business == true`), access Business Dashboard (metrics: members, RSVPs, check-ins, challenge completions), create challenges with discount codes (e.g., “ICE50OFF”).

### 2. Community Creation and Management
- **2.1 Community Creation**: Authenticated users (`admin`, `business`) create communities (`communities/{community_id}`: `name`, `description`, `cover_image`, `admin_uid`, `visibility` ("public", "private_open", "private_invite"), `approval_required`, `is_business`, `members`, `banned_users`, `pinned_items`, `created_at`, `theme`).
- **2.2 Joining Communities**: Members request to join (`communities/{community_id}/requests/{request_id}`), approved by `admin_uid` if `approval_required`. Public communities auto-join.
- **2.3 Admin Management**: Admins (`admin`, `business` where `admin_uid == user.uid`) edit community details, approve requests, ban users, pin items, view dashboard (metrics: members, engagement).

### 3. Group Chat (Advanced Focus)
- **3.1 Group Chat**: Real-time chat in communities (`messages/{message_id}`: `community_id`, `user_id`, `text`, `media_url`, `media_type`, `thread_id`, `timestamp`, `reactions`, `mentions`). Supports threads, @mentions, emoji reactions (👍, ❤️, 😄, 😢, 🎉), typing indicators (<50 members).
- **3.2 Private Chat**: 1:1 chats (`private_chats/{chat_id}`: `community_id`, `user_ids`, `messages` subcollection). Same features as group chat.
- **3.3 Moderation**: Admins delete inappropriate messages, media, or Moments, ban users.

### 4. Event Management (Advanced Focus)
- **4.1 Event Creation**: Admins (`admin`, `business`) create events (`events/{event_id}`: `community_id`, `title`, `description`, `date`, `location`, `creator_uid`, `poster_url`, `visibility`, `approval_required`, `rsvps`, `check_ins`, `created_at`).
- **4.2 RSVP and Check-In**: Members RSVP (`rsvps` map), check-in with QR code (`check_ins` map). Admins approve RSVPs if `approval_required`.
- **4.3 Admin Event Management**: Edit/delete events, approve RSVPs, view metrics (RSVPs, check-ins).

### 5. Media Uploads
- **5.1 Uploads**: Photos/videos (max 10MB) to `communities/{community_id}/gallery` or `events/{event_id}/media`. Stored in Firebase Storage.
- **5.2 Moderation**: Admins delete inappropriate media.

### 6. Polls
- **6.1 Creation**: Members create polls (`communities/{community_id}/polls/{poll_id}`: `question`, `options`, `duration`, `creator_uid`, `votes`).
- **6.2 Voting**: Members vote, results visible post-duration.

### 7. Live Moments
- **7.1 Creation**: Members post ephemeral media/polls (`communities/{community_id}/moments/{moment_id}`: `media_id`, `url`, `type`, `user_id`, `timestamp`, `expires_at`, `reactions`, `comments`). Auto-deleted after 24 hours via Cloud Function.
- **7.2 Interaction**: Members react (emoji), comment. Admins moderate.

### 8. Advanced Features (Differentiators)
- **8.1 Dynamic Community Challenges**: Admins/businesses create challenges (`communities/{community_id}/challenges/{challenge_id}`: `title`, `description`, `actions`, `reward`, `duration`, `creator_uid`). Members complete actions, earn points/badges, claim rewards (e.g., “ICE50OFF”).
- **8.2 Search**: Search public communities/events by name, filter by business or interests.
- **8.3 Gamification**: Points/badges for actions (join, post, RSVP, check-in, complete challenges).
- **8.4 Notifications**: FCM for new messages, event RSVPs, Moments, challenge updates.

### 9. Business Features
- **9.1 Business Communities**: Businesses (`is_business == true`) create public communities/events, visible in Search/Challenge Hub.
- **9.2 Dashboard**: Metrics (members, RSVPs, check-ins, challenge completions) in Admin Management Screen.
- **9.3 Challenges**: Create challenges with discount codes (e.g., “ICE50OFF”).

### 10. Analytics and Monitoring
- **10.1 Analytics**: Log events (`post_moment`, `complete_challenge`, `login_member`, `access_business_dashboard`) in Firebase Analytics.
- **10.2 Crashlytics**: Log crashes, non-fatal errors.

## Firestore Data Model
```
users/{uid}
  - phone_number: string (required for non-anonymous, null for anonymous)
  - display_name: string (optional, default "Guest" for anonymous)
  - profile_picture: string (URL, max 2MB, optional)
  - points: number (default 0)
  - badges: array<string> (default [])
  - created_at: timestamp
  - role: string ("admin", "member", "anonymous", default "member" for phone auth, "anonymous" for anonymous login)
  - is_business: boolean (default false, true for business users)
  - owned_communities: array<string> (community IDs where user is admin, default [])
  - challenges: subcollection
    - challenges/{challenge_id}
        - community_id: string
        - actions_completed: array<string>
        - status: string ("active", "completed")
        - reward: string

communities/{community_id}
  - name: string
  - description: string
  - cover_image: string (URL)
  - admin_uid: string
  - visibility: string ("public", "private_open", "private_invite")
  - approval_required: boolean
  - is_business: boolean
  - members: array<string>
  - banned_users: array<string>
  - pinned_items: array<string>
  - created_at: timestamp
  - theme: map (color: string, banner_url: string)
  - requests: subcollection (user_id, status)
  - polls: subcollection (question, options, duration, creator_uid, votes)
  - gallery: subcollection (media_id, url, type, user_id, timestamp)
  - announcements: subcollection (text, image_url, timestamp)
  - challenges: subcollection (title, description, actions, reward, duration, creator_uid)
  - moments: subcollection (media_id, url, type, user_id, timestamp, expires_at, reactions, comments)

events/{event_id}
  - community_id: string
  - title: string
  - description: string
  - date: timestamp
  - location: string
  - creator_uid: string
  - poster_url: string (URL)
  - visibility: string ("public", "private")
  - approval_required: boolean
  - created_at: timestamp
  - rsvps: map<string, string>
  - check_ins: map<string, timestamp>
  - rsvp_requests: subcollection (user_id, status)
  - ratings: subcollection (user_id, rating, timestamp)
  - comments: subcollection (user_id, text, timestamp)
  - time_proposals: subcollection (user_id, proposed_time, status)
  - polls: subcollection (question, options, duration, creator_uid, votes)
  - media: subcollection (media_id, url, type, user_id, timestamp)
  - moments: subcollection (media_id, url, type, user_id, timestamp, expires_at, reactions, comments)

messages/{message_id}
  - community_id: string
  - user_id: string
  - text: string
  - media_url: string (optional)
  - media_type: string (optional)
  - thread_id: string (optional)
  - timestamp: timestamp
  - reactions: map<string, array<string>>
  - mentions: array<string>

private_chats/{chat_id}
  - community_id: string
  - user_ids: array<string>
  - created_at: timestamp
  - messages: subcollection (user_id, text, media_url, media_type, timestamp, reactions, mentions)

reports/{report_id}
  - community_id: string
  - message_id: string (optional)
  - media_id: string (optional)
  - moment_id: string (optional)
  - user_id: string
  - reason: string
  - timestamp: timestamp

config/inappropriate_keywords
  - keywords: array<string>
```

## Firestore Security Rules
```rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
    match /communities/{community_id} {
      allow read: if resource.data.visibility == "public" || request.auth.uid in resource.data.members;
      allow write: if request.auth != null && (request.auth.uid == resource.data.admin_uid || get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ["admin", "business"]);
      match /requests/{request_id} {
        allow read, write: if request.auth.uid == resource.data.user_id || request.auth.uid == get(/databases/$(database)/documents/communities/$(community_id)).data.admin_uid;
      }
      match /polls/{poll_id} {
        allow read, write: if request.auth != null && request.auth.uid in get(/databases/$(database)/documents/communities/$(community_id)).data.members && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role != "anonymous";
      }
      match /gallery/{media_id} {
        allow read: if request.auth.uid in get(/databases/$(database)/documents/communities/$(community_id)).data.members;
        allow write: if request.auth != null && request.auth.uid in get(/databases/$(database)/documents/communities/$(community_id)).data.members && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role != "anonymous";
      }
      match /announcements/{announcement_id} {
        allow read: if request.auth.uid in get(/databases/$(database)/documents/communities/$(community_id)).data.members;
        allow write: if request.auth.uid == get(/databases/$(database)/documents/communities/$(community_id)).data.admin_uid;
      }
      match /challenges/{challenge_id} {
        allow read: if request.auth.uid in get(/databases/$(database)/documents/communities/$(community_id)).data.members;
        allow write: if request.auth != null && (request.auth.uid == get(/databases/$(database)/documents/communities/$(community_id)).data.admin_uid || get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == "business");
      }
      match /moments/{moment_id} {
        allow read: if request.auth.uid in get(/databases/$(database)/documents/communities/$(community_id)).data.members;
        allow write: if request.auth != null && request.auth.uid in get(/databases/$(database)/documents/communities/$(community_id)).data.members && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role != "anonymous";
      }
    }
    match /events/{event_id} {
      allow read: if resource.data.visibility == "public" || request.auth.uid in get(/databases/$(database)/documents/communities/$(resource.data.community_id)).data.members;
      allow write: if request.auth != null && (request.auth.uid == resource.data.creator_uid || get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role in ["admin", "business"]);
      match /{subcollection=**} {
        allow read, write: if request.auth != null && request.auth.uid in get(/databases/$(database)/documents/communities/$(get(/databases/$(database)/documents/events/$(event_id)).data.community_id)).data.members && get(/databases/$(database Ovid:0
        allow read, write: if request.auth != null && request.auth.uid in get(/databases/$(database)/documents/communities/$(get(/databases/$(database)/documents/events/$(event_id)).data.community_id)).data.members && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role != "anonymous";
      }
    }
    match /messages/{message_id} {
      allow read, write: if request.auth != null && request.auth.uid in get(/databases/$(database)/documents/communities/$(resource.data.community_id)).data.members && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role != "anonymous";
    }
    match /private_chats/{chat_id} {
      allow read: if request.auth != null && (request.auth.uid in resource.data.user_ids || request.auth.uid == get(/databases/$(database)/documents/communities/$(resource.data.community_id)).data.admin_uid);
      allow write: if request.auth != null && request.auth.uid in resource.data.user_ids && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role != "anonymous";
      match /messages/{message_id} {
        allow read: if request.auth != null && (request.auth.uid in get(/databases/$(database)/documents/private_chats/$(chat_id)).data.user_ids || request.auth.uid == get(/databases/$(database)/documents/communities/$(get(/databases/$(database)/documents/private_chats/$(chat_id)).data.community_id)).data.admin_uid);
        allow write: if request.auth != null && request.auth.uid in get(/databases/$(database)/documents/private_chats/$(chat_id)).data.user_ids && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role != "anonymous";
      }
    }
    match /reports/{report_id} {
      allow read, write: if request.auth != null && (request.auth.uid == get(/databases/$(database)/documents/communities/$(resource.data.community_id)).data.admin_uid || request.auth.uid == resource.data.user_id);
    }
    match /config/inappropriate_keywords {
      allow read: if true;
      allow write: if false;
    }
  }
}
```

## UI/UX Implementation Notes
- **Phone Auth UI**: Clean phone number input and OTP verification with animated button states (e.g., ripple on “Send OTP”).
- **Chat UI**: Sleek, rounded bubbles (color-coded, timestamps, read receipts for <50 members), swipe-to-reply with slide-in thread view, animated emoji reactions (👍, ❤️, 😄, 😢, 🎉), typing indicators, group mentions (@username).
- **Event UI**: Large event cards (poster, title, date), animated RSVP buttons (e.g., green glow for “Yes”), confetti for check-in, clean `table_calendar` with event dots.
- **Live Moments UI**: Full-screen media viewer (photos, videos, polls), swipe navigation, minimal controls (react, comment, report), animated reactions (e.g., heart pulse).
- **Gamification UI**: Animated progress bars (`AnimatedProgressBar`) for challenges, badge spins (`Lottie`) in Profile, points counter with bounce animation.
- **Business UI**: Business dashboard in Admin Management Screen for metrics, discount code display in Challenge Details (e.g., “ICE50OFF”).
- **Micro-Interactions**: Button ripples (`InkWell`) for “Send”, “RSVP”, “Join”; Lottie animations for reactions, confetti, fireworks; `Hero` transitions for screen navigation.
- **Accessibility**: Large text (16–24pt), high-contrast colors, screen reader support, 48dp tap targets.
- **Voice Input**: Use device-native voice input (iOS/Android keyboard microphone) for text fields in Chat, Events, and Moments. Defer text-to-speech for future release.
- **Role-Based UI**: Display Admin Management Screen only for `admin`/`business` roles, Business Dashboard only for `business` role, restrict `anonymous` users to public content views.

## Wireframe Implementation
Implement screens with minimal controls, prioritizing phone auth, chat, events, and Live Moments:

1. **Phone Auth Screen**:
   - Layout: Logo, phone number input, “Send OTP”, OTP input, “Verify”, “Continue as Guest”.
   - UI: 2 buttons, animated button states, clean form.
   - File: `lib/views/phone_auth_screen.dart`.

2. **Home Screen**:
   - Layout: Logo, search/profile icons, Challenge Hub (carousel), Public Communities (list), My Communities (list, hidden for `anonymous`), FAB for Create Community (`member`, `admin`, `business` only).
   - UI: 1 FAB, Lottie for challenges, ripple on “Join”.
   - File: `lib/views/home_screen.dart`.

3. **Create Community Screen**:
   - Layout: Back, “Save”, name/description/cover image, visibility/approval/business toggles, theme picker.
   - UI: 1 button, clean form, accessible to `admin`, `business` roles.
   - File: `lib/views/create_community_screen.dart`.

4. **Community Details Screen**:
   - Layout: Name, cover, “Leave”/“Manage” (`admin`/`business` only), tabs (Chat, Events, Moments, Gallery, Polls, Challenges, Announcements).
   - Chat: Sleek bubbles, swipe-to-reply, animated reactions, mentions (`member`, `admin`, `business`).
   - Events: Event cards, “Create Event” (`admin`, `business`), “Calendar”.
   - Moments: Full-screen media/polls, swipe navigation, animated reactions (`member`, `admin`, `business`).
   - UI: 1–2 buttons per tab, Lottie for Moments/challenges.
   - File: `lib/views/community_details_screen.dart`.

5. **Admin Management Screen**:
   - Layout: Name, back, sections (Settings, Members, Requests, Pinned Items, Reports, Business Dashboard (`business` only)).
   - UI: 1 button per item, clean list, metrics for `business` role.
   - File: `lib/views/admin_management_screen.dart`.

6. **Chat Screen**:
   - Layout: Name, back, “1:1 Chat” (`member`, `admin`, `business`), message list (bubbles with reactions, mentions), thread view, input (text, media, send).
   - UI: Sleek bubbles, swipe-to-reply, animated reactions, typing indicators.
   - File: `lib/views/chat_screen.dart`.

7. **Private Chat Screen**:
   - Layout: Member name, back, message list, input.
   - UI: Same as group chat, minimal controls, accessible to `member`, `admin`, `business`.
   - File: `lib/views/private_chat_screen.dart`.

8. **Create Event Screen**:
   - Layout: “Create Event”, back, “Save”, title/description/date/location/poster, visibility/RSVP approval/business toggles.
   - UI: 1 button, animated date picker, accessible to `admin`, `business`.
   - File: `lib/views/create_event_screen.dart`.

9. **Event Details Screen**:
   - Layout: Title, poster, back, sections (Details, RSVP, Check-In, Rating, Comments, Time Proposals, Polls, Moments, Media).
   - UI: Animated RSVP, confetti check-in, star bounce for rating, swipe Moments (`member`, `admin`, `business`).
   - File: `lib/views/event_details_screen.dart`.

10. **Calendar Screen**:
    - Layout: Name or “All Communities”, back, `table_calendar`, event list on tap.
    - UI: Clean calendar, minimal navigation, accessible to all roles.
    - File: `lib/views/calendar_screen.dart`.

11. **Profile Screen**:
    - Layout: Picture, name, back, Details, Points & Badges (animated), My Communities, “Delete Account”/“Log Out” (`member`, `admin`, `business`).
    - UI: Badge spin, 2 buttons.
    - File: `lib/views/profile_screen.dart`.

12. **Create Poll Screen**:
    - Layout: “Create Poll”, back, “Save”, question/options/duration.
    - UI: 1 button, clean form, accessible to `member`, `admin`, `business`.
    - File: `lib/views/create_poll_screen.dart`.

13. **Challenge Details Screen**:
    - Layout: Title, back, description, actions, reward (e.g., discount code “ICE50OFF”), progress bar, “Join”/“Claim Reward” (`member`, `admin`, `business`).
    - UI: Animated progress bar, fireworks for reward.
    - File: `lib/views/challenge_details_screen.dart`.

14. **Create Challenge Screen**:
    - Layout: “Create Challenge”, back, “Save”, title/description/actions/reward/duration.
    - UI: 1 button, clean form, accessible to `admin`, `business`.
    - File: `lib/views/create_challenge_screen.dart`.

15. **Search Screen**:
    - Layout: Search bar, back, filters (Public, Business, Events), result list.
    - UI: Minimal filters, animated results, accessible to all roles.
    - File: `lib/views/search_screen.dart`.

16. **Moments Screen**:
    - Layout: Full-screen media viewer (photos, videos, polls), swipe navigation, react/comment/report buttons (`member`, `admin`, `business`).
    - UI: Animated reactions, minimal controls.
    - File: `lib/views/moments_screen.dart`.

## Implementation Notes
- **Navigation**: `BottomNavigationBar` (Home, Calendar, Profile) with ripples.
- **Services**:
  - `lib/services/auth_service.dart`: Phone number auth, anonymous login, logout, role-based checks.
  - `lib/services/firestore_service.dart`: Communities, events, messages, challenges, role-based queries.
  - `lib/services/moment_service.dart`: Moment creation/deletion.
  - `lib/services/storage_service.dart`: Image/video uploads.
  - `lib/services/notification_service.dart`: FCM notifications.
- **Models**:
  - `lib/models/user.dart`: Phone_number, display_name, points, badges, role, is_business.
  - `lib/models/community.dart`: Name, visibility, is_business.
  - `lib/models/event.dart`: Title, date, check_ins.
  - `lib/models/message.dart`: Text, thread_id, reactions, mentions.
  - `lib/models/moment.dart`: Media, expires_at, reactions.
- **Widgets**:
  - `lib/widgets/chat_bubble_widget.dart`: Group/1:1 chats, swipe-to-reply.
  - `lib/widgets/event_card_widget.dart`: Event lists, RSVP animation.
  - `lib/widgets/moment_card_widget.dart`: Full-screen Moments, swipe navigation.
- **Cloud Functions**: Auto-delete Moments after 24 hours, process challenge rewards.
- **Firebase Usage**:
  - Authentication: Phone number (SMS OTP), anonymous login.
  - Firestore: Store users, communities, messages, events, challenges, Moments.
  - Storage: Profile pictures, covers, posters, Moments media (max 10MB).
  - FCM: Push notifications for messages, events, Moments, challenges.
- **Performance**: Lazy-load lists, cache queries, compress media.
- **Analytics**: Log `post_moment`, `complete_challenge`, etc.
- **Testing**: Use Emulators, test animations on low-end devices.
- **Error Handling**: Snackbars for errors (e.g., failed OTP verification).
- **Voice Input**: Rely on device-native voice input (iOS/Android keyboard microphone) for text fields. Defer text-to-speech (e.g., reading messages or event details aloud) to a future release for enhanced accessibility.
- **Role-Based Access**: Implement role checks in `AuthService` and UI (e.g., hide Admin Management Screen for `member` role), enforce via security rules.

## Deliverables
- Complete Flutter project with all screens, services, models.
- Firebase configuration files (`google-services.json`, `GoogleService-Info.plist`).
- Firestore security rules file (`firestore.rules`).
- Cloud Functions for Moment deletion and challenge logic.
- README with setup, testing, deployment instructions.
- Sample data: business community (“Joe’s Ice Cream”), event (“Free Ice Cream Day”), challenge (“Check in for 50 points”), Moment (event photo).

## Notes
- Prioritize phone auth, minimal controls (1–2 buttons), fast performance, and advanced chat/event/Moments UI.
- Ensure business communities/events are visible in Search/Challenge Hub, with discount codes in challenges.
- Test with beta users (5–10 businesses, 100 users) in 3-month timeline.
- Apply `mojorules.mdc` intelligently in Cursor for flexibility.
- Use device-native voice input (iOS/Android keyboard microphone) for text fields in Chat, Events, and Moments. Defer text-to-speech to a future release for accessibility.
- Implement role-based access (`admin`, `member`, `anonymous`, `business`) with explicit privileges in UI and Firestore security rules, ensuring `anonymous` users are restricted to public content, `admin`/`business` users access management screens, and `business` users see dashboards.
- Use `https://cloud.google.com/firestore/docs/security/rules` for Firestore security rules reference.