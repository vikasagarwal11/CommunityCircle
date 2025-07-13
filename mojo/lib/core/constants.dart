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
  
  // Responsive Design Constants
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 900.0;
  static const double desktopBreakpoint = 1200.0;
  
  // Device-Specific Sizing
  static const double smallScreenMaxWidth = 360.0;
  static const double mediumScreenMaxWidth = 600.0;
  static const double largeScreenMaxWidth = 900.0;
  
  // Adaptive Font Sizes
  static const double smallFontSize = 12.0;
  static const double mediumFontSize = 14.0;
  static const double largeFontSize = 16.0;
  static const double headlineFontSize = 20.0;
  static const double titleFontSize = 18.0;
  
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
  
  // Platform-Specific Constants
  static const bool isIOS = bool.fromEnvironment('dart.library.io');
  static const bool isAndroid = bool.fromEnvironment('dart.library.io');
  
  // Device Type Detection
  static bool isSmallScreen(double width) => width < mobileBreakpoint;
  static bool isMediumScreen(double width) => width >= mobileBreakpoint && width < tabletBreakpoint;
  static bool isLargeScreen(double width) => width >= tabletBreakpoint;
  static bool isTablet(double width) => width >= tabletBreakpoint;
  static bool isPhone(double width) => width < tabletBreakpoint;
} 