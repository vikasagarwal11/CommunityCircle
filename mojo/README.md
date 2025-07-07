# MOJO - Community Builder App

A cross-platform Flutter app for building vibrant communities with advanced chat, event management, live moments, and business features. MOJO aims to disrupt platforms like Meetup, WhatsApp, Meta, Slack, and Circle.

## 🚀 Project Status

### ✅ Completed Features
- **Authentication**: Phone number authentication with Firebase Auth
- **Database & Models**: Complete Firestore models and services
- **State Management**: Riverpod providers and state notifiers
- **Core Architecture**: Clean architecture with modular design

### 🎯 Current Progress
- **Database & Models**: ✅ Complete
- **Community Features**: 🔄 Next
- **Chat System**: 📋 Planned
- **Event Management**: 📋 Planned
- **Business Features**: 📋 Planned
- **UI/UX Enhancements**: 📋 Planned

## 🛠 Tech Stack

- **Frontend**: Flutter with Material 3
- **Backend**: Firebase (Auth, Firestore, Storage, Analytics, Crashlytics, FCM, Cloud Functions)
- **State Management**: Riverpod with hooks
- **Authentication**: Phone number authentication
- **Database**: Firestore with real-time updates
- **Logging**: Logger package with Firebase Analytics/Crashlytics

## 📱 Features

### Core Features
- **Community Management**: Create, join, and manage communities
- **Advanced Chat**: Threaded messages, reactions, mentions, media sharing
- **Event Management**: RSVP, check-ins, event discovery
- **Live Moments**: 24-hour ephemeral content with reactions
- **Polls & Challenges**: Community engagement and gamification
- **Business Tools**: Business profiles and analytics

### User Roles
- **Admin**: Full platform control
- **Member**: Standard user features
- **Anonymous**: Limited access
- **Business**: Business-specific features

## 🏗 Architecture

### Models
- `UserModel` - User profiles with roles and gamification
- `CommunityModel` - Community data with visibility controls
- `EventModel` - Events with RSVP and check-in tracking
- `MessageModel` - Chat messages with reactions and threads
- `MomentModel` - 24-hour ephemeral content
- `PollModel` - Community polls with voting
- `ChallengeModel` - Gamification with leaderboards

### Services
- `DatabaseService` - Central CRUD operations
- `CommunityService` - Community business logic
- `AuthService` - Authentication management

### Providers (Riverpod)
- Service providers for dependency injection
- Data providers for state management
- State notifiers for complex state

## 📁 Project Structure

```
lib/
├── core/           # Core utilities, constants, theme
├── models/         # Data models
├── services/       # Business logic services
├── providers/      # Riverpod providers
├── views/          # UI screens
├── widgets/        # Reusable UI components
├── routes/         # Navigation and routing
└── main.dart       # App entry point
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (latest stable)
- Firebase project with Firestore enabled
- Phone number for testing authentication

### Setup
1. Clone the repository
2. Install dependencies: `flutter pub get`
3. Configure Firebase (see Firebase setup below)
4. Run the app: `flutter run`

### Firebase Setup
1. Create a Firebase project
2. Enable Authentication (Phone provider)
3. Enable Firestore Database
4. Add test phone numbers in Firebase Console
5. Deploy Firestore rules: `firebase deploy --only firestore:rules`

## 📚 Documentation

- [Database Architecture](DATABASE.md) - Complete database documentation
- [Firebase Rules](firestore.rules) - Security rules
- [Requirements](requirements.md) - Detailed feature requirements

## 🎨 Design Principles

- **Playful Minimalism**: 1-2 buttons per screen, vibrant colors
- **Micro-interactions**: Lottie animations, smooth transitions
- **Gamification**: Progress bars, badge spins, leaderboards
- **Accessibility**: Screen reader support, high contrast
- **Performance**: Fast rendering, optimized queries

## 🔧 Development

### Code Style
- Clean architecture principles
- Stateless widgets where possible
- Final variables preferred
- Comprehensive error handling
- Logger integration for debugging

### Testing
- Unit tests for models and services
- Widget tests for UI components
- Integration tests for user flows

## 📈 Roadmap

### Phase 1: Core Features ✅
- [x] Authentication system
- [x] Database models and services
- [x] Basic navigation

### Phase 2: Community Features 🔄
- [ ] Community creation and management
- [ ] Member management
- [ ] Community discovery

### Phase 3: Chat & Communication
- [ ] Advanced chat UI
- [ ] Real-time messaging
- [ ] Media sharing

### Phase 4: Events & Activities
- [ ] Event creation and management
- [ ] RSVP system
- [ ] Event discovery

### Phase 5: Business Features
- [ ] Business profiles
- [ ] Analytics dashboard
- [ ] Monetization features

## 🤝 Contributing

1. Follow the established architecture patterns
2. Use Riverpod for state management
3. Implement proper error handling
4. Add comprehensive logging
5. Write tests for new features

## 📄 License

This project is proprietary software.

---

**MOJO** - Building communities, one moment at a time. 🚀
