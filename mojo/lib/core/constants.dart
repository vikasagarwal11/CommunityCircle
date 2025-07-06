class AppConstants {
  // App Info
  static const String appName = 'MOJO';
  static const String appVersion = '1.0.0';
  
  // Firebase Collections
  static const String usersCollection = 'users';
  static const String communitiesCollection = 'communities';
  static const String messagesCollection = 'messages';
  static const String eventsCollection = 'events';
  
  // Storage Paths
  static const String profilePicturesPath = 'profile_pictures';
  static const String eventImagesPath = 'event_images';
  
  // Validation
  static const int minPhoneLength = 10;
  static const int maxPhoneLength = 15;
  static const int minPasswordLength = 6;
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 8.0;
  static const double cardElevation = 2.0;
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // Error Messages
  static const String networkError = 'Network error. Please check your connection.';
  static const String authError = 'Authentication failed. Please try again.';
  static const String generalError = 'Something went wrong. Please try again.';
  static const String invalidPhoneNumber = 'Please enter a valid phone number.';
  static const String invalidOtp = 'Please enter a valid OTP.';
} 