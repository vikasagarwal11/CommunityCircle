import 'package:flutter/material.dart';

class AppNavigation {
  // Route names
  static const String auth = '/auth';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String communities = '/communities';
  static const String events = '/events';
  static const String chat = '/chat';
  static const String moments = '/moments';
  static const String settings = '/settings';

  // Navigation methods
  static void navigateToAuth(BuildContext context) {
    Navigator.of(context).pushReplacementNamed(auth);
  }

  static void navigateToHome(BuildContext context) {
    Navigator.of(context).pushReplacementNamed(home);
  }

  static void navigateToProfile(BuildContext context) {
    Navigator.of(context).pushNamed(profile);
  }

  static void navigateToCommunities(BuildContext context) {
    Navigator.of(context).pushNamed(communities);
  }

  static void navigateToEvents(BuildContext context) {
    Navigator.of(context).pushNamed(events);
  }

  static void navigateToChat(BuildContext context, {String? communityId}) {
    Navigator.of(context).pushNamed(chat, arguments: communityId);
  }

  static void navigateToMoments(BuildContext context) {
    Navigator.of(context).pushNamed(moments);
  }

  static void navigateToSettings(BuildContext context) {
    Navigator.of(context).pushNamed(settings);
  }

  // Go back
  static void goBack(BuildContext context) {
    Navigator.of(context).pop();
  }

  // Go back to root
  static void goBackToRoot(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  // Show custom dialog
  static Future<T?> showCustomDialog<T>({
    required BuildContext context,
    required Widget child,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => child,
    );
  }

  // Show bottom sheet
  static Future<T?> showBottomSheet<T>({
    required BuildContext context,
    required Widget child,
    bool isScrollControlled = false,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => child,
    );
  }
} 