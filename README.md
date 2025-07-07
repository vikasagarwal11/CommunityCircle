# MOJO Community App

## Project Vision
Develop a cross-platform mobile app (iOS/Android/Web) using Flutter and Firebase to disrupt Meetup, WhatsApp, Meta, Slack, and Circle. The app manages interest-based communities with a modern, sleek, beautiful, and intuitive UI/UX, advanced chat, robust event management, and Live Moments (ephemeral media/polls) to drive real-time engagement. It supports local businesses/realtors with public communities/events (e.g., "Free Ice Cream Day") and Dynamic Community Challenges with discount codes. Use phone number authentication as the primary signup/login method. Target ~1,000 users within Firebase's free tier, ensuring fast performance, minimal controls (1–2 buttons per screen), and a delightful experience to encourage platform switching.

## Tech Stack
- **Frontend:** Flutter (Dart), Material 3
- **Backend:** Firebase (Authentication, Firestore, Storage, Analytics, Crashlytics, FCM, Cloud Functions)
- **State Management:** Riverpod (`flutter_riverpod`, `hooks_riverpod`)
- **UI/UX:** Material 3, Google Fonts, playful minimalism, centralized theming
- **Tools:** Firebase Emulators, Cursor, Lottie, Table Calendar, Logger

## Project Structure
```
lib/
  core/        # constants.dart, theme.dart, navigation.dart
  models/      # User, Community, Event, Message, Moment
  services/    # AuthService, FirestoreService, MomentService
  views/       # phone_auth_screen.dart, chat_screen.dart, moments_screen.dart
  widgets/     # chat_bubble_widget.dart, event_card_widget.dart, moment_card_widget.dart
  routes/      # named routes
  providers/   # Riverpod providers
  main.dart
```

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