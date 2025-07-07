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

// App Routes
class AppRoutes {
  static const String phoneAuth = '/phone_auth';
  static const String home = '/home';
  static const String publicHome = '/public_home';
  static const String createCommunity = '/create_community';
  static const String communityDetails = '/community_details';
  static const String adminManagement = '/admin_management';
  static const String profile = '/profile';
  static const String settings = '/settings';
}

// App Colors
class AppColors {
  static const int primaryGreen = 0xFF4CAF50;
  static const int primaryBlue = 0xFF2196F3;
  static const int primaryOrange = 0xFFFF9800;
  static const int primaryRed = 0xFFF44336;
  static const int primaryPurple = 0xFF9C27B0;
} 