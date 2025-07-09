# MOJO Community App

## Project Vision
Develop a cross-platform mobile app (iOS/Android/Web) using Flutter and Firebase to disrupt Meetup, WhatsApp, Meta, Slack, and Circle. The app manages interest-based communities with a modern, sleek, beautiful, and intuitive UI/UX, advanced chat, robust event management, and Live Moments (ephemeral media/polls) to drive real-time engagement. It supports local businesses/realtors with public communities/events (e.g., "Free Ice Cream Day") and Dynamic Community Challenges with discount codes. Use phone number authentication as the primary signup/login method. Target ~1,000 users within Firebase's free tier, ensuring fast performance, minimal controls (1–2 buttons per screen), and a delightful experience to encourage platform switching.

## 🚀 Latest Achievements (World-Class Implementation)

### ✅ **Database Integration & Real-Time Architecture**
- **CommunityService**: Complete CRUD operations with real-time Firestore streams
- **Advanced Search**: Real-time search with filters (business/community, categories)
- **Navigation Service**: Centralized navigation with proper route arguments
- **Riverpod Providers**: Real-time state management with caching and invalidation
- **Error Handling**: Comprehensive error states and user feedback

### ✅ **World-Class UI/UX Implementation**
- **HomeScreen**: Real-time community data with dynamic cards and member counts
- **CommunityDetailsScreen**: Role-based tabs with real-time updates
- **SearchScreen**: Advanced search with filters and beautiful community cards
- **Loading Widgets**: Custom loading and error widgets for seamless UX
- **Navigation**: Smooth transitions and proper route management

### ✅ **Production-Ready Features**
- **Real-Time Data Flow**: Live updates across all screens
- **Role-Based UI**: Different experiences for anonymous, member, admin, business users
- **Advanced Search**: Filter by business/community with real-time results
- **Community Management**: Join, leave, ban, unban with proper state management
- **Statistics & Analytics**: Community stats with member counts and activity

### ✅ **Technical Excellence**
- **Clean Architecture**: Separation of concerns with services, providers, models
- **Performance**: Pagination, caching, and efficient data loading
- **Security**: Proper authentication and authorization
- **Scalability**: Designed for thousands of users on Firebase free tier
- **Maintainability**: Well-documented, modular codebase

## Tech Stack
- **Frontend:** Flutter (Dart), Material 3
- **Backend:** Firebase (Authentication, Firestore, Storage, Analytics, Crashlytics, FCM, Cloud Functions)
- **State Management:** Riverpod (`flutter_riverpod`, `hooks_riverpod`)
- **UI/UX:** Material 3, Google Fonts, playful minimalism, centralized theming
- **Tools:** Firebase Emulators, Cursor, Lottie, Table Calendar, Logger

## Project Structure
```
lib/
  core/        # constants.dart, theme.dart, navigation_service.dart
  models/      # User, Community, Event, Message, Moment
  services/    # AuthService, CommunityService, DatabaseService
  views/       # home_screen.dart, community_details_screen.dart, search_screen.dart
  widgets/     # loading_widget.dart, error_widget.dart
  routes/      # app_routes.dart with proper argument handling
  providers/   # auth_providers.dart, community_providers.dart
  main.dart
```

## 🎯 **Next Strategic Steps (Founder's Roadmap)**

### **Phase 1: User Onboarding & Authentication (Week 1)**
1. **Phone Authentication Screen** - Beautiful, frictionless signup
2. **Profile Creation Flow** - Quick onboarding with role selection
3. **Anonymous Login** - Allow users to explore before committing
4. **Email Verification** - Optional but recommended for security

### **Phase 2: Community Creation & Discovery (Week 2)**
1. **Create Community Screen** - Intuitive community creation flow
2. **Community Templates** - Pre-built templates for common use cases
3. **Advanced Search** - Location-based, interest-based discovery
4. **Community Recommendations** - AI-powered suggestions

### **Phase 3: Real-Time Communication (Week 3)**
1. **Chat System** - Advanced messaging with reactions, replies
2. **Voice Messages** - Audio communication
3. **File Sharing** - Images, documents, location sharing
4. **Push Notifications** - Smart notification system

### **Phase 4: Event Management (Week 4)**
1. **Event Creation** - Rich event creation with templates
2. **RSVP System** - Advanced RSVP with reminders
3. **Event Discovery** - Location-based event recommendations
4. **Event Analytics** - Track engagement and success

### **Phase 5: Business Features & Monetization (Week 5)**
1. **Business Dashboard** - Analytics and management tools
2. **Promoted Events** - Paid promotion system
3. **Discount Codes** - Dynamic challenge system
4. **Payment Integration** - Stripe/PayPal for premium features

### **Phase 6: Advanced Features (Week 6)**
1. **Live Moments** - Ephemeral content sharing
2. **Polls & Surveys** - Community engagement tools
3. **Challenges & Gamification** - Points, badges, leaderboards
4. **Analytics Dashboard** - Comprehensive insights

## Key Technical Decisions & Best Practices
- **Clean Architecture:** Business logic in services, UI in views, models for all data structures.
- **No direct Firebase calls in widgets:** Always use service classes and providers.
- **Emulator Support:** Use Firebase Emulators for Auth, Firestore, Functions, and Storage during development.
- **Testing:** Unit tests for services/providers, widget tests for UI, integration tests for flows.
- **Performance:** Lazy loading, Firestore pagination, image/video compression, caching, offline support.
- **Security:** Firestore security rules, least-privilege, Cloud Functions for privileged actions.
- **Analytics & Crash Reporting:** Log key user actions, set up Crashlytics early.
- **Notifications:** FCM for event reminders, chat mentions, challenge updates.
- **CI/CD:** Linting, pre-commit hooks, automated tests on every PR.
- **Theming:** Centralized theming, Google Fonts, dark mode support.
- **Accessibility:** Large tap targets, high-contrast, screen reader support.
- **Internationalization:** Use `flutter_localizations` for future global scaling.

## Firebase Setup
- **Authentication:** Phone (primary), Anonymous (optional for onboarding)
- **Firestore:** Main database for users, communities, events, messages, moments
- **Storage:** For images, videos, ephemeral media
- **Analytics, Crashlytics, FCM, Cloud Functions:** Enabled and integrated
- **Emulators:** Used for local development and testing
- **Test Phone Numbers:** Configured in Firebase Console for dev/testing

## Development Workflow
- Use test phone numbers for phone auth during development (no real SMS sent)
- Use Firebase Emulators for local testing
- All migrations, rules, and backend logic are managed via project files and deployed with Firebase CLI
- All requirements, rules, and architecture are documented in this README for future reference

## How to Run
1. `cd mojo`
2. `flutter run -d chrome` (for web) or `flutter run` (for mobile)
3. Use test phone numbers for authentication

## How to Deploy Firestore Rules
1. Ensure Firebase CLI is installed (`firebase --version`)
2. Run `firebase deploy --only firestore:rules`

## How to Update Project Memory
- Add new requirements, rules, or architecture decisions to this README or a dedicated `mojorules.md` file.
- After a restart, ask the AI to "read README.md" to regain full project context.

---

*This file is auto-updated to reflect all major project decisions and technicalities discussed so far. Continue to update as the project evolves!* 