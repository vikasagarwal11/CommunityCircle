import 'package:flutter/material.dart' as material;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:logger/logger.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../models/community_model.dart';
import '../models/user_model.dart';
import '../routes/app_routes.dart';
import '../services/auth_service.dart';

class NavigationService {
  static final material.GlobalKey<material.NavigatorState> navigatorKey = 
      material.GlobalKey<material.NavigatorState>();
  
  static material.NavigatorState? get navigator => navigatorKey.currentState;
  static material.BuildContext? get context => navigatorKey.currentContext;

  // Logger instance for navigation events
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

  // Analytics instance
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Initialize navigation service with analytics
  static Future<void> initialize() async {
    try {
      _logger.i('🚀 Initializing NavigationService with analytics');
      
      // Enable analytics collection
      await _analytics.setAnalyticsCollectionEnabled(true);
      
      // Set user properties for better tracking
      await _analytics.setUserProperty(name: 'app_version', value: '1.0.0');
      await _analytics.setUserProperty(name: 'platform', value: 'flutter');
      
      _logger.i('✅ NavigationService initialized successfully');
    } catch (e) {
      _logger.e('❌ Failed to initialize NavigationService: $e');
    }
  }

  // Track app session start
  static Future<void> trackAppSessionStart() async {
    try {
      await _analytics.logEvent(
        name: 'app_session_start',
        parameters: {
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'session_id': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );
      _logger.i('📊 App session start tracked');
    } catch (e) {
      _logger.e('❌ Failed to track app session start: $e');
    }
  }

  // Track app session end
  static Future<void> trackAppSessionEnd() async {
    try {
      await _analytics.logEvent(
        name: 'app_session_end',
        parameters: {
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      _logger.i('📊 App session end tracked');
    } catch (e) {
      _logger.e('❌ Failed to track app session end: $e');
    }
  }

  // Track user engagement
  static Future<void> trackUserEngagement(String action, {Map<String, dynamic>? parameters}) async {
    try {
      await _analytics.logEvent(
        name: 'user_action',
        parameters: {
          'action': action,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          ...?parameters,
        },
      );
      _logger.i('📊 User engagement tracked: $action');
    } catch (e) {
      _logger.e('❌ Failed to track user engagement: $e');
    }
  }

  // Track error with crash reporting
  static Future<void> trackError(String error, String stackTrace, {Map<String, dynamic>? parameters}) async {
    try {
      await _analytics.logEvent(
        name: 'app_error',
        parameters: {
          'error': error,
          'stack_trace': stackTrace,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          ...?parameters,
        },
      );
      _logger.e('❌ Error tracked: $error');
    } catch (e) {
      _logger.e('❌ Failed to track error: $e');
    }
  }

  // Track performance metrics
  static Future<void> trackPerformance(String metric, int value, {String? unit}) async {
    try {
      await _analytics.logEvent(
        name: 'performance_metric',
        parameters: {
          'metric': metric,
          'value': value,
          'unit': unit ?? 'ms',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      _logger.i('📊 Performance tracked: $metric = $value${unit ?? 'ms'}');
    } catch (e) {
      _logger.e('❌ Failed to track performance: $e');
    }
  }

  // Track screen load time
  static Future<void> trackScreenLoadTime(String screenName, int loadTimeMs) async {
    await trackPerformance('screen_load_time', loadTimeMs);
  }

  // Track user interaction
  static Future<void> trackUserInteraction(String interaction, {Map<String, dynamic>? parameters}) async {
    try {
      await _analytics.logEvent(
        name: 'user_interaction',
        parameters: {
          'interaction': interaction,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          ...?parameters,
        },
      );
      _logger.i('👆 User interaction tracked: $interaction');
    } catch (e) {
      _logger.e('❌ Failed to track user interaction: $e');
    }
  }

  // Track feature usage
  static Future<void> trackFeatureUsage(String feature, {Map<String, dynamic>? parameters}) async {
    try {
      await _analytics.logEvent(
        name: 'feature_usage',
        parameters: {
          'feature': feature,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          ...?parameters,
        },
      );
      _logger.i('🎯 Feature usage tracked: $feature');
    } catch (e) {
      _logger.e('❌ Failed to track feature usage: $e');
    }
  }

  // Track conversion events
  static Future<void> trackConversion(String conversionType, {Map<String, dynamic>? parameters}) async {
    try {
      await _analytics.logEvent(
        name: 'conversion',
        parameters: {
          'conversion_type': conversionType,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          ...?parameters,
        },
      );
      _logger.i('🎉 Conversion tracked: $conversionType');
    } catch (e) {
      _logger.e('❌ Failed to track conversion: $e');
    }
  }

  // Track navigation event
  static Future<void> _trackNavigationEvent(String routeName, {Map<String, dynamic>? parameters}) async {
    try {
      await _analytics.logEvent(
        name: 'navigation',
        parameters: {
          'route_name': routeName,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          ...?parameters,
        },
      );
      _logger.i('📊 Navigation tracked: $routeName');
    } catch (e) {
      _logger.e('❌ Failed to track navigation event: $e');
    }
  }

  // Track navigation error
  static Future<void> _trackNavigationError(String routeName, String error, {Map<String, dynamic>? parameters}) async {
    try {
      await _analytics.logEvent(
        name: 'navigation_error',
        parameters: {
          'route_name': routeName,
          'error': error,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          ...?parameters,
        },
      );
      _logger.e('❌ Navigation error tracked: $routeName - $error');
    } catch (e) {
      _logger.e('❌ Failed to track navigation error: $e');
    }
  }

  // Push named route with logging and analytics
  static Future<T?> pushNamed<T>(String routeName, {Object? arguments}) async {
    final ctx = context;
    if (ctx == null) {
      _logger.e('❌ Navigation failed: No context available for route $routeName');
      await _trackNavigationError(routeName, 'No context available');
      return Future.value(null);
    }
    
    try {
      _logger.i('🚀 Navigating to: $routeName');
      await _trackNavigationEvent(routeName, parameters: {
        'navigation_type': 'push_named',
        'has_arguments': arguments != null ? 'true' : 'false',
      });
      
      final result = await material.Navigator.of(ctx).pushNamed<T>(routeName, arguments: arguments);
      _logger.i('✅ Navigation completed: $routeName');
      return result;
    } catch (e) {
      _logger.e('❌ Navigation error: $routeName - $e');
      await _trackNavigationError(routeName, e.toString());
      return Future.value(null);
    }
  }

  // Push replacement named route with logging and analytics
  static Future<T?> pushReplacementNamed<T>(String routeName, {Object? arguments}) async {
    final ctx = context;
    if (ctx == null) {
      _logger.e('❌ Navigation failed: No context available for route $routeName');
      await _trackNavigationError(routeName, 'No context available');
      return Future.value(null);
    }
    
    try {
      _logger.i('🔄 Replacing navigation to: $routeName');
      await _trackNavigationEvent(routeName, parameters: {
        'navigation_type': 'push_replacement_named',
        'has_arguments': arguments != null ? 'true' : 'false',
      });
      
      final result = await material.Navigator.of(ctx).pushReplacementNamed<T, void>(routeName, arguments: arguments);
      _logger.i('✅ Navigation replacement completed: $routeName');
      return result;
    } catch (e) {
      _logger.e('❌ Navigation replacement error: $routeName - $e');
      await _trackNavigationError(routeName, e.toString());
      return Future.value(null);
    }
  }

  // Push and remove until with logging and analytics
  static Future<T?> pushNamedAndRemoveUntil<T>(String routeName, {Object? arguments}) async {
    final ctx = context;
    if (ctx == null) {
      _logger.e('❌ Navigation failed: No context available for route $routeName');
      await _trackNavigationError(routeName, 'No context available');
      return Future.value(null);
    }
    
    try {
      _logger.i('🗑️ Clearing stack and navigating to: $routeName');
      await _trackNavigationEvent(routeName, parameters: {
        'navigation_type': 'push_named_and_remove_until',
        'has_arguments': arguments != null ? 'true' : 'false',
      });
      
      final result = await material.Navigator.of(ctx).pushNamedAndRemoveUntil<T>(
        routeName,
        (route) => false,
        arguments: arguments,
      );
      _logger.i('✅ Stack cleared and navigation completed: $routeName');
      return result;
    } catch (e) {
      _logger.e('❌ Navigation clear stack error: $routeName - $e');
      await _trackNavigationError(routeName, e.toString());
      return Future.value(null);
    }
  }

  // Push with fade transition with logging and analytics
  static Future<T?> pushWithFade<T>(material.Widget page, {Object? arguments}) async {
    final ctx = context;
    if (ctx == null) {
      _logger.e('❌ Navigation failed: No context available for fade transition');
      await _trackNavigationError('fade_transition', 'No context available');
      return Future.value(null);
    }
    
    try {
      _logger.i('✨ Navigating with fade transition');
      await _trackNavigationEvent('fade_transition', parameters: {
        'navigation_type': 'push_with_fade',
        'has_arguments': arguments != null ? 'true' : 'false',
      });
      
      final result = await material.Navigator.of(ctx).push<T>(
        material.PageRouteBuilder<T>(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return material.FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
      _logger.i('✅ Fade transition completed');
      return result;
    } catch (e) {
      _logger.e('❌ Fade transition error: $e');
      await _trackNavigationError('fade_transition', e.toString());
      return Future.value(null);
    }
  }

  // Go back with logging
  static void goBack<T>([T? result]) {
    final ctx = context;
    if (ctx == null) {
      _logger.e('❌ Cannot go back: No context available');
      return;
    }
    
    try {
      _logger.i('⬅️ Going back');
      material.Navigator.of(ctx).pop<T>(result);
      _logger.i('✅ Successfully went back');
    } catch (e) {
      _logger.e('❌ Error going back: $e');
    }
  }

  // Can go back with logging
  static bool canGoBack() {
    final ctx = context;
    if (ctx == null) {
      _logger.w('⚠️ Cannot check if can go back: No context available');
      return false;
    }
    
    final canPop = material.Navigator.of(ctx).canPop();
    _logger.d('🔍 Can go back: $canPop');
    return canPop;
  }

  // Show general dialog with logging and analytics
  static Future<T?> showGeneralDialog<T>({
    required material.Widget child,
    bool barrierDismissible = true,
    material.Color? barrierColor,
    String? barrierLabel,
  }) async {
    final ctx = context;
    if (ctx == null) {
      _logger.e('❌ Cannot show dialog: No context available');
      return Future.value(null);
    }
    
    try {
      _logger.i('💬 Showing general dialog');
      await _trackNavigationEvent('general_dialog', parameters: {
        'navigation_type': 'show_general_dialog',
        'barrier_dismissible': barrierDismissible ? 'true' : 'false',
      });
      
      final result = await material.showGeneralDialog<T>(
        context: ctx,
        pageBuilder: (context, animation, secondaryAnimation) => child,
        barrierDismissible: barrierDismissible,
        barrierColor: barrierColor ?? material.Colors.black54,
        barrierLabel: barrierLabel,
      );
      _logger.i('✅ General dialog completed');
      return result;
    } catch (e) {
      _logger.e('❌ General dialog error: $e');
      await _trackNavigationError('general_dialog', e.toString());
      return Future.value(null);
    }
  }

  // Show bottom sheet with logging and analytics
  static Future<T?> showBottomSheet<T>({
    required material.Widget child,
    material.Color? backgroundColor,
    double? elevation,
    material.ShapeBorder? shape,
    material.Clip? clipBehavior,
    material.Color? barrierColor,
    bool isScrollControlled = false,
    bool isDismissible = true,
    bool enableDrag = true,
    bool useSafeArea = true,
    bool useRootNavigator = true,
    material.RouteSettings? routeSettings,
    material.AnimationController? transitionAnimationController,
    material.Offset? anchorPoint,
    bool? showDragHandle,
    String? barrierLabel,
  }) async {
    final ctx = context;
    if (ctx == null) {
      _logger.e('❌ Cannot show bottom sheet: No context available');
      return Future.value(null);
    }
    
    try {
      _logger.i('📱 Showing bottom sheet');
      await _trackNavigationEvent('bottom_sheet', parameters: {
        'navigation_type': 'show_bottom_sheet',
        'is_scroll_controlled': isScrollControlled ? 'true' : 'false',
        'is_dismissible': isDismissible ? 'true' : 'false',
        'enable_drag': enableDrag ? 'true' : 'false',
      });
      
      final result = await material.showModalBottomSheet<T>(
        context: ctx,
        builder: (context) => child,
        backgroundColor: backgroundColor,
        elevation: elevation,
        shape: shape,
        clipBehavior: clipBehavior ?? material.Clip.hardEdge,
        barrierColor: barrierColor,
        isScrollControlled: isScrollControlled,
        isDismissible: isDismissible,
        enableDrag: enableDrag,
        useSafeArea: useSafeArea,
        useRootNavigator: useRootNavigator,
        routeSettings: routeSettings,
        transitionAnimationController: transitionAnimationController,
        anchorPoint: anchorPoint,
        showDragHandle: showDragHandle,
        barrierLabel: barrierLabel,
      );
      _logger.i('✅ Bottom sheet completed');
      return result;
    } catch (e) {
      _logger.e('❌ Bottom sheet error: $e');
      await _trackNavigationError('bottom_sheet', e.toString());
      return Future.value(null);
    }
  }

  // Show snackbar with logging
  static void showSnackBar({
    required String message,
    Duration? duration,
    material.SnackBarAction? action,
    material.Color? backgroundColor,
    double? width,
    material.EdgeInsetsGeometry? margin,
    material.EdgeInsetsGeometry? padding,
    double? elevation,
    material.ShapeBorder? shape,
    material.DismissDirection? dismissDirection,
    material.Animation<double>? animation,
    VoidCallback? onVisible,
    material.Clip? clipBehavior,
  }) {
    final ctx = context;
    if (ctx == null) {
      _logger.e('❌ Cannot show snackbar: No context available');
      return;
    }
    
    try {
      _logger.i('🍞 Showing snackbar: $message');
      final snackBar = material.SnackBar(
        content: material.Text(message),
        duration: duration ?? const Duration(seconds: 4),
        action: action,
        backgroundColor: backgroundColor,
        width: width,
        margin: margin,
        padding: padding,
        elevation: elevation,
        shape: shape,
        dismissDirection: dismissDirection,
        animation: animation,
        onVisible: onVisible,
        clipBehavior: clipBehavior ?? material.Clip.hardEdge,
      );

      material.ScaffoldMessenger.of(ctx).showSnackBar(snackBar);
      _logger.i('✅ Snackbar shown successfully');
    } catch (e) {
      _logger.e('❌ Snackbar error: $e');
    }
  }

  // Show error dialog with logging and analytics
  static Future<T?> showErrorDialog<T>({
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) async {
    final ctx = context;
    if (ctx == null) {
      _logger.e('❌ Cannot show error dialog: No context available');
      return Future.value(null);
    }
    
    try {
      _logger.i('⚠️ Showing error dialog: $title');
      await _trackNavigationEvent('error_dialog', parameters: {
        'navigation_type': 'show_error_dialog',
        'title': title,
        'has_cancel': cancelText != null ? 'true' : 'false',
      });
      
      final result = await material.showDialog<T>(
        context: ctx,
        builder: (context) => material.AlertDialog(
          title: material.Text(title),
          content: material.Text(message),
          actions: [
            if (cancelText != null)
              material.TextButton(
                onPressed: () {
                  goBack();
                  onCancel?.call();
                },
                child: material.Text(cancelText),
              ),
            material.TextButton(
              onPressed: () {
                goBack();
                onConfirm?.call();
              },
              child: material.Text(confirmText ?? 'OK'),
            ),
          ],
        ),
      );
      _logger.i('✅ Error dialog completed');
      return result;
    } catch (e) {
      _logger.e('❌ Error dialog error: $e');
      await _trackNavigationError('error_dialog', e.toString());
      return Future.value(null);
    }
  }

  // Show confirmation dialog with logging and analytics
  static Future<bool?> showConfirmationDialog({
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
  }) async {
    final ctx = context;
    if (ctx == null) {
      _logger.e('❌ Cannot show confirmation dialog: No context available');
      return Future.value(null);
    }
    
    try {
      _logger.i('❓ Showing confirmation dialog: $title');
      await _trackNavigationEvent('confirmation_dialog', parameters: {
        'navigation_type': 'show_confirmation_dialog',
        'title': title,
      });
      
      final result = await material.showDialog<bool>(
        context: ctx,
        builder: (context) => material.AlertDialog(
          title: material.Text(title),
          content: material.Text(message),
          actions: [
            material.TextButton(
              onPressed: () => goBack(false),
              child: material.Text(cancelText ?? 'Cancel'),
            ),
            material.TextButton(
              onPressed: () => goBack(true),
              child: material.Text(confirmText ?? 'Confirm'),
            ),
          ],
        ),
      );
      _logger.i('✅ Confirmation dialog completed with result: $result');
      return result;
    } catch (e) {
      _logger.e('❌ Confirmation dialog error: $e');
      await _trackNavigationError('confirmation_dialog', e.toString());
      return Future.value(null);
    }
  }

  // Show loading dialog with logging and analytics
  static Future<T?> showLoadingDialog<T>({
    String? message,
    bool barrierDismissible = false,
  }) async {
    final ctx = context;
    if (ctx == null) {
      _logger.e('❌ Cannot show loading dialog: No context available');
      return Future.value(null);
    }
    
    try {
      _logger.i('⏳ Showing loading dialog: ${message ?? 'Loading...'}');
      await _trackNavigationEvent('loading_dialog', parameters: {
        'navigation_type': 'show_loading_dialog',
        'has_message': message != null ? 'true' : 'false',
        'barrier_dismissible': barrierDismissible ? 'true' : 'false',
      });
      
      final result = await material.showDialog<T>(
        context: ctx,
        barrierDismissible: barrierDismissible,
        builder: (context) => material.WillPopScope(
          onWillPop: () async => barrierDismissible,
          child: material.AlertDialog(
            content: material.Row(
              children: [
                const material.CircularProgressIndicator(),
                if (message != null) ...[
                  const material.SizedBox(width: 16),
                  material.Expanded(child: material.Text(message)),
                ],
              ],
            ),
          ),
        ),
      );
      _logger.i('✅ Loading dialog completed');
      return result;
    } catch (e) {
      _logger.e('❌ Loading dialog error: $e');
      await _trackNavigationError('loading_dialog', e.toString());
      return Future.value(null);
    }
  }

  // Hide loading dialog with logging
  static void hideLoadingDialog() {
    _logger.i('⏹️ Hiding loading dialog');
    goBack();
  }

  // Get route arguments safely with logging
  static T? getRouteArguments<T>(material.BuildContext context) {
    try {
      final args = material.ModalRoute.of(context)?.settings.arguments;
      if (args is T) {
        _logger.d('📋 Retrieved route arguments of type ${T.toString()}');
        return args;
      }
      _logger.w('⚠️ Route arguments not found or wrong type for ${T.toString()}');
      return null;
    } catch (e) {
      _logger.e('❌ Error getting route arguments: $e');
      return null;
    }
  }

  // Get community ID from route arguments with logging
  static String? getCommunityIdFromArgs(material.BuildContext context) {
    try {
      final args = getRouteArguments<dynamic>(context);
      if (args is String) {
        _logger.d('🏘️ Retrieved community ID from string args: $args');
        return args;
      } else if (args is Map<String, dynamic>) {
        final communityId = args['communityId'] as String?;
        _logger.d('🏘️ Retrieved community ID from map args: $communityId');
        return communityId;
      }
      _logger.w('⚠️ Community ID not found in route arguments');
      return null;
    } catch (e) {
      _logger.e('❌ Error getting community ID from args: $e');
      return null;
    }
  }

  // Get user from route arguments with logging
  static UserModel? getUserFromArgs(material.BuildContext context) {
    try {
      final args = getRouteArguments<dynamic>(context);
      if (args is UserModel) {
        _logger.d('👤 Retrieved user from direct args');
        return args;
      } else if (args is Map<String, dynamic>) {
        final userData = args['user'] as Map<String, dynamic>?;
        if (userData != null) {
          final user = UserModel.fromMap(userData);
          _logger.d('👤 Retrieved user from map args: ${user.id}');
          return user;
        }
      }
      _logger.w('⚠️ User not found in route arguments');
      return null;
    } catch (e) {
      _logger.e('❌ Error getting user from args: $e');
      return null;
    }
  }

  // Get community from route arguments with logging
  static CommunityModel? getCommunityFromArgs(material.BuildContext context) {
    try {
      final args = getRouteArguments<dynamic>(context);
      if (args is CommunityModel) {
        _logger.d('🏘️ Retrieved community from direct args: ${args.id}');
        return args;
      } else if (args is Map<String, dynamic>) {
        final communityData = args['community'] as Map<String, dynamic>?;
        if (communityData != null) {
          final community = CommunityModel.fromMap(communityData, '');
          _logger.d('🏘️ Retrieved community from map args: ${community.id}');
          return community;
        }
      }
      _logger.w('⚠️ Community not found in route arguments');
      return null;
    } catch (e) {
      _logger.e('❌ Error getting community from args: $e');
      return null;
    }
  }

  // Generic navigation method for dynamic routes
  static Future<T?> navigateTo<T>(String route, {Object? arguments}) async {
    try {
      _logger.i('🧭 Navigating to: $route');
      await _trackNavigationEvent('dynamic_navigation', parameters: {
        'navigation_type': 'navigate_to',
        'route': route,
        'has_arguments': (arguments != null).toString(),
      });
      return await pushNamed<T>(route, arguments: arguments);
    } catch (e) {
      _logger.e('❌ Error navigating to $route: $e');
      await _trackNavigationError('dynamic_navigation', e.toString(), parameters: {
        'route': route,
      });
      return Future.value(null);
    }
  }

  // Navigate to phone auth with logging and analytics
  static Future<T?> navigateToPhoneAuth<T>() async {
    try {
      _logger.i('📱 Navigating to phone authentication');
      await _trackNavigationEvent('phone_auth', parameters: {
        'navigation_type': 'navigate_to_phone_auth',
      });
      return await pushNamed<T>(AppRoutes.phoneAuth);
    } catch (e) {
      _logger.e('❌ Error navigating to phone auth: $e');
      await _trackNavigationError('phone_auth', e.toString());
      return Future.value(null);
    }
  }

  // Navigate to community details with logging and analytics
  static Future<T?> navigateToCommunityDetails<T>(String communityId, {CommunityModel? community}) async {
    try {
      _logger.i('🏘️ Navigating to community details: $communityId');
      await _trackNavigationEvent('community_details', parameters: {
        'navigation_type': 'navigate_to_community_details',
        'community_id': communityId,
        'has_community_data': (community != null).toString(), // Fix: must be string
      });
      
      if (community != null) {
        return await pushNamed<T>(AppRoutes.communityDetails, arguments: communityId); // Pass only ID
      }
      return await pushNamed<T>(AppRoutes.communityDetails, arguments: communityId);
    } catch (e) {
      _logger.e('❌ Error navigating to community details: $e');
      await _trackNavigationError('community_details', e.toString(), parameters: {
        'community_id': communityId,
      });
      return Future.value(null);
    }
  }

  // Navigate to admin management with logging and analytics
  static Future<T?> navigateToAdminManagement<T>(CommunityModel community) async {
    try {
      _logger.i('👑 Navigating to admin management: ${community.id}');
      await _trackNavigationEvent('admin_management', parameters: {
        'navigation_type': 'navigate_to_admin_management',
        'community_id': community.id,
        'community_name': community.name,
      });
      return await pushNamed<T>(AppRoutes.adminManagement, arguments: community);
    } catch (e) {
      _logger.e('❌ Error navigating to admin management: $e');
      await _trackNavigationError('admin_management', e.toString(), parameters: {
        'community_id': community.id,
      });
      return Future.value(null);
    }
  }

  // NEW: Navigate to join requests review with logging and analytics
  static Future<T?> navigateToJoinRequestsReview<T>(CommunityModel community) async {
    try {
      _logger.i('📋 Navigating to join requests review: ${community.id}');
      await _trackNavigationEvent('join_requests_review', parameters: {
        'navigation_type': 'navigate_to_join_requests_review',
        'community_id': community.id,
        'community_name': community.name,
        'has_join_questions': community.hasJoinQuestions.toString(),
        'approval_required': community.approvalRequired.toString(),
      });
      return await pushNamed<T>(AppRoutes.joinRequestsReview, arguments: community);
    } catch (e) {
      _logger.e('❌ Error navigating to join requests review: $e');
      await _trackNavigationError('join_requests_review', e.toString(), parameters: {
        'community_id': community.id,
      });
      return Future.value(null);
    }
  }

  // Navigate to home with role-based routing and logging/analytics
  static Future<T?> navigateToHome<T>({String? role}) async {
    try {
      _logger.i('🏠 Navigating to home with role: ${role ?? 'default'}');
      await _trackNavigationEvent('home', parameters: {
        'navigation_type': 'navigate_to_home',
        'role': role ?? 'default',
      });
      
      if (role == null || role.isEmpty) {
        return await pushNamedAndRemoveUntil<T>(AppRoutes.publicHome);
      }
      
      String targetRoute;
      switch (role.toLowerCase()) {
        case 'admin':
          targetRoute = AppRoutes.adminHome;
          break;
        case 'business':
          targetRoute = AppRoutes.businessHome;
          break;
        case 'moderator':
          targetRoute = AppRoutes.moderatorHome;
          break;
        default:
          targetRoute = AppRoutes.home;
      }
      
      _logger.i('🎯 Target home route: $targetRoute');
      return await pushNamedAndRemoveUntil<T>(targetRoute);
    } catch (e) {
      _logger.e('❌ Error navigating to home: $e');
      await _trackNavigationError('home', e.toString(), parameters: {
        'role': role ?? 'default',
      });
      return Future.value(null);
    }
  }

  // Navigate to profile with logging and analytics
  static Future<T?> navigateToProfile<T>({UserModel? user}) async {
    try {
      _logger.i('👤 Navigating to profile');
      await _trackNavigationEvent('profile', parameters: {
        'navigation_type': 'navigate_to_profile',
        'has_user_data': (user != null).toString(), // Fix: must be string
      });
      
      if (user != null) {
        return await pushNamed<T>(AppRoutes.profile, arguments: {
          'user': user.toMap(),
        });
      }
      return await pushNamed<T>(AppRoutes.profile);
    } catch (e) {
      _logger.e('❌ Error navigating to profile: $e');
      await _trackNavigationError('profile', e.toString());
      return Future.value(null);
    }
  }

  // Navigate to chat with logging and analytics
  static Future<T?> navigateToChat<T>(String communityId, {String? channelId}) async {
    try {
      _logger.i('💬 Navigating to community chat: $communityId${channelId != null ? ' (channel: $channelId)' : ''}');
      await _trackNavigationEvent('chat', parameters: {
        'navigation_type': 'navigate_to_community_chat',
        'community_id': communityId,
        'has_channel_id': (channelId != null).toString(), // Fix: must be string
      });
      
      return await pushNamed<T>(AppRoutes.chat, arguments: {
        'communityId': communityId,
        'channelId': channelId,
      });
    } catch (e) {
      _logger.e('❌ Error navigating to chat: $e');
      await _trackNavigationError('chat', e.toString(), parameters: {
        'community_id': communityId,
      });
      return Future.value(null);
    }
  }

  // Navigate to personal chat with logging and analytics
  static Future<T?> navigateToPersonalChat<T>(String otherUserId) async {
    try {
      _logger.i('💬 Navigating to personal chat with user: $otherUserId');
      await _trackNavigationEvent('personal_chat', parameters: {
        'navigation_type': 'navigate_to_personal_chat',
        'other_user_id': otherUserId,
      });
      
      return await pushNamed<T>(AppRoutes.personalChat, arguments: {
        'otherUserId': otherUserId,
      });
    } catch (e) {
      _logger.e('❌ Error navigating to personal chat: $e');
      await _trackNavigationError('personal_chat', e.toString(), parameters: {
        'other_user_id': otherUserId,
      });
      return Future.value(null);
    }
  }

  // Navigate to message search with logging and analytics
  static Future<T?> navigateToMessageSearch<T>({
    required String chatId,
    required String otherUserId,
    required String otherUserName,
  }) async {
    try {
      _logger.i('🔍 Navigating to message search in chat: $chatId');
      await _trackNavigationEvent('message_search', parameters: {
        'navigation_type': 'navigate_to_message_search',
        'chat_id': chatId,
        'other_user_id': otherUserId,
      });
      
      return await pushNamed<T>(AppRoutes.messageSearch, arguments: {
        'chatId': chatId,
        'otherUserId': otherUserId,
        'otherUserName': otherUserName,
      });
    } catch (e) {
      _logger.e('❌ Error navigating to message search: $e');
      await _trackNavigationError('message_search', e.toString(), parameters: {
        'chat_id': chatId,
        'other_user_id': otherUserId,
      });
      return Future.value(null);
    }
  }

  // Navigate to add participants
  static Future<T?> navigateToAddParticipants<T>({
    required String chatId,
    bool isConvertingToGroup = false,
    String? currentGroupName,
  }) async {
    try {
      _logger.i('👥 Navigating to add participants');
      await _trackNavigationEvent('add_participants', parameters: {
        'navigation_type': 'navigate_to_add_participants',
        'chat_id': chatId,
        'is_converting_to_group': isConvertingToGroup.toString(),
      });
      return await pushNamed<T>(AppRoutes.addParticipants, arguments: {
        'chatId': chatId,
        'isConvertingToGroup': isConvertingToGroup.toString(),
        'currentGroupName': currentGroupName,
      });
    } catch (e) {
      _logger.e('❌ Error navigating to add participants: $e');
      await _trackNavigationError('add_participants', e.toString());
      return Future.value(null);
    }
  }

  // Navigate to group selection
  static Future<T?> navigateToGroupSelection<T>({
    required String otherUserId,
    required String otherUserName,
  }) async {
    try {
      _logger.i('👥 Navigating to group selection');
      await _trackNavigationEvent('group_selection', parameters: {
        'navigation_type': 'navigate_to_group_selection',
        'other_user_id': otherUserId,
      });
      return await pushNamed<T>(AppRoutes.groupSelection, arguments: {
        'otherUserId': otherUserId,
        'otherUserName': otherUserName,
      });
    } catch (e) {
      _logger.e('❌ Error navigating to group selection: $e');
      await _trackNavigationError('group_selection', e.toString());
      return Future.value(null);
    }
  }

  // Navigate to call screen
  static Future<T?> navigateToCall<T>({
    required String callId,
    required String chatId,
    required String callType,
    bool isIncoming = false,
  }) async {
    try {
      _logger.i('📞 Navigating to call screen: $callType call');
      await _trackNavigationEvent('call_screen', parameters: {
        'navigation_type': 'navigate_to_call',
        'call_id': callId,
        'chat_id': chatId,
        'call_type': callType,
        'is_incoming': isIncoming.toString(),
      });
      
      return await pushNamed<T>(AppRoutes.call, arguments: {
        'callId': callId,
        'chatId': chatId,
        'callType': callType,
        'isIncoming': isIncoming,
      });
    } catch (e) {
      _logger.e('❌ Error navigating to call screen: $e');
      await _trackNavigationError('call_screen', e.toString(), parameters: {
        'call_id': callId,
        'chat_id': chatId,
        'call_type': callType,
      });
      return Future.value(null);
    }
  }

  // Navigate to create community with logging and analytics
  static Future<T?> navigateToCreateCommunity<T>() async {
    try {
      _logger.i('➕ Navigating to create community');
      
      // Check user authentication and role
      final authService = AuthService();
      final userRole = await authService.getUserRole();
      
      if (userRole == 'anonymous') {
        _logger.w('🚫 Anonymous user attempted to create community - access denied');
        await _trackNavigationEvent('create_community_denied', parameters: {
          'navigation_type': 'navigate_to_create_community',
          'reason': 'anonymous_user',
          'user_role': userRole,
        });
        
        // Show access denied dialog
        if (context != null) {
          material.showDialog(
            context: context!,
            builder: (context) => material.AlertDialog(
              title: const material.Text('Access Denied'),
              content: const material.Text(
                'Anonymous users cannot create communities. Please sign in with your phone number to continue.',
              ),
              actions: [
                material.TextButton(
                  onPressed: () => material.Navigator.of(context).pop(),
                  child: const material.Text('Cancel'),
                ),
                material.TextButton(
                  onPressed: () {
                    material.Navigator.of(context).pop();
                    navigateToPhoneAuth();
                  },
                  child: const material.Text('Sign In'),
                ),
              ],
            ),
          );
        }
        
        return Future.value(null);
      }
      
      await _trackNavigationEvent('create_community', parameters: {
        'navigation_type': 'navigate_to_create_community',
        'user_role': userRole,
      });
      return await pushNamed<T>(AppRoutes.createCommunity);
    } catch (e) {
      _logger.e('❌ Error navigating to create community: $e');
      await _trackNavigationError('create_community', e.toString());
      return Future.value(null);
    }
  }

  // Navigate to search with logging and analytics
  static Future<T?> navigateToSearch<T>({String? initialQuery}) async {
    try {
      _logger.i('🔍 Navigating to search${initialQuery != null ? ' with query: $initialQuery' : ''}');
      await _trackNavigationEvent('search', parameters: {
        'navigation_type': 'navigate_to_search',
        'has_initial_query': (initialQuery != null).toString(),
      });
      return await pushNamed<T>(AppRoutes.search, arguments: initialQuery);
    } catch (e) {
      _logger.e('❌ Error navigating to search: $e');
      await _trackNavigationError('search', e.toString());
      return Future.value(null);
    }
  }

  // Navigate to settings with logging and analytics
  static Future<T?> navigateToSettings<T>() async {
    try {
      _logger.i('⚙️ Navigating to settings');
      await _trackNavigationEvent('settings', parameters: {
        'navigation_type': 'navigate_to_settings',
      });
      return await pushNamed<T>(AppRoutes.settings);
    } catch (e) {
      _logger.e('❌ Error navigating to settings: $e');
      await _trackNavigationError('settings', e.toString());
      return Future.value(null);
    }
  }

  // Navigate to event list
  static Future<T?> navigateToEventList<T>({String? communityId}) {
    return pushNamed<T>(AppRoutes.eventList, arguments: communityId);
  }

  // Navigate to event details
  static Future<T?> navigateToEventDetails<T>(String eventId, {String? communityId}) {
    return pushNamed<T>(AppRoutes.eventDetails, arguments: {
      'eventId': eventId,
      'communityId': communityId,
    });
  }

  // Navigate to create event
  static Future<T?> navigateToCreateEvent<T>(String communityId) {
    return pushNamed<T>(AppRoutes.createEvent, arguments: communityId);
  }

  // Navigate to calendar
  static Future<T?> navigateToCalendar<T>({String? communityId}) {
    return pushNamed<T>(AppRoutes.calendar, arguments: communityId);
  }

  // Navigate to event communication
  static Future<T?> navigateToEventCommunication<T>(String eventId, {String? communityId}) {
    return pushNamed<T>(AppRoutes.eventCommunication, arguments: {
      'eventId': eventId,
      'communityId': communityId,
    });
  }

  // Navigate to moment details
  static Future<T?> navigateToMomentDetails<T>(String momentId) {
    return pushNamed<T>(AppRoutes.momentDetails, arguments: momentId);
  }

  // Navigate to create moment
  static Future<T?> navigateToCreateMoment<T>(String communityId) {
    return pushNamed<T>(AppRoutes.createMoment, arguments: communityId);
  }

  // Navigate to challenge details
  static Future<T?> navigateToChallengeDetails<T>(String challengeId) {
    return pushNamed<T>(AppRoutes.challengeDetails, arguments: challengeId);
  }

  // Navigate to create challenge
  static Future<T?> navigateToCreateChallenge<T>(String communityId) {
    return pushNamed<T>(AppRoutes.createChallenge, arguments: communityId);
  }

  // Navigate to poll details
  static Future<T?> navigateToPollDetails<T>(String pollId) {
    return pushNamed<T>(AppRoutes.pollDetails, arguments: pollId);
  }

  // Navigate to create poll
  static Future<T?> navigateToCreatePoll<T>(String communityId) {
    return pushNamed<T>(AppRoutes.createPoll, arguments: communityId);
  }

  // Navigate to gallery
  static Future<T?> navigateToGallery<T>(String communityId) {
    return pushNamed<T>(AppRoutes.gallery, arguments: communityId);
  }

  // Navigate to members
  static Future<T?> navigateToMembers<T>(String communityId) {
    return pushNamed<T>(AppRoutes.members, arguments: communityId);
  }

  // Navigate to notifications
  static Future<T?> navigateToNotifications<T>() {
    return pushNamed<T>(AppRoutes.notifications);
  }

  // Navigate to help
  static Future<T?> navigateToHelp<T>() {
    return pushNamed<T>(AppRoutes.help);
  }

  // Navigate to about
  static Future<T?> navigateToAbout<T>() {
    return pushNamed<T>(AppRoutes.about);
  }

  // Navigate to privacy policy
  static Future<T?> navigateToPrivacyPolicy<T>() {
    return pushNamed<T>(AppRoutes.privacyPolicy);
  }

  // Navigate to terms of service
  static Future<T?> navigateToTermsOfService<T>() {
    return pushNamed<T>(AppRoutes.termsOfService);
  }

  // Navigate to contact
  static Future<T?> navigateToContact<T>() {
    return pushNamed<T>(AppRoutes.contact);
  }

  // Navigate to feedback
  static Future<T?> navigateToFeedback<T>() {
    return pushNamed<T>(AppRoutes.feedback);
  }

  // Navigate to invite friends
  static Future<T?> navigateToInviteFriends<T>() {
    return pushNamed<T>(AppRoutes.inviteFriends);
  }

  // Navigate to share app
  static Future<T?> navigateToShareApp<T>() {
    return pushNamed<T>(AppRoutes.shareApp);
  }

  // Navigate to rate app
  static Future<T?> navigateToRateApp<T>() {
    return pushNamed<T>(AppRoutes.rateApp);
  }

  // Navigate to developer info
  static Future<T?> navigateToDeveloperInfo<T>() {
    return pushNamed<T>(AppRoutes.developerInfo);
  }

  // Navigate to debug
  static Future<T?> navigateToDebug<T>() {
    return pushNamed<T>(AppRoutes.debug);
  }

  // Navigate to test
  static Future<T?> navigateToTest<T>() {
    return pushNamed<T>(AppRoutes.test);
  }

  // Navigate to demo
  static Future<T?> navigateToDemo<T>() {
    return pushNamed<T>(AppRoutes.demo);
  }

  // Navigate to onboarding
  static Future<T?> navigateToOnboarding<T>() {
    return pushNamed<T>(AppRoutes.onboarding);
  }

  // Navigate to welcome
  static Future<T?> navigateToWelcome<T>() {
    return pushNamed<T>(AppRoutes.welcome);
  }

  // Navigate to splash
  static Future<T?> navigateToSplash<T>() {
    return pushNamed<T>(AppRoutes.splash);
  }

  // Navigate to loading
  static Future<T?> navigateToLoading<T>() {
    return pushNamed<T>(AppRoutes.loading);
  }

  // Navigate to error
  static Future<T?> navigateToError<T>({String? message}) {
    return pushNamed<T>(AppRoutes.error, arguments: message);
  }

  // Navigate to maintenance
  static Future<T?> navigateToMaintenance<T>() {
    return pushNamed<T>(AppRoutes.maintenance);
  }

  // Navigate to update
  static Future<T?> navigateToUpdate<T>() {
    return pushNamed<T>(AppRoutes.update);
  }

  // Navigate to force update
  static Future<T?> navigateToForceUpdate<T>() {
    return pushNamed<T>(AppRoutes.forceUpdate);
  }

  // Navigate to unsupported
  static Future<T?> navigateToUnsupported<T>() {
    return pushNamed<T>(AppRoutes.unsupported);
  }

  // Navigate to not found
  static Future<T?> navigateToNotFound<T>() {
    return pushNamed<T>(AppRoutes.notFound);
  }

  // Navigate to unauthorized
  static Future<T?> navigateToUnauthorized<T>() {
    return pushNamed<T>(AppRoutes.unauthorized);
  }

  // Navigate to forbidden
  static Future<T?> navigateToForbidden<T>() {
    return pushNamed<T>(AppRoutes.forbidden);
  }

  // Navigate to too many requests
  static Future<T?> navigateToTooManyRequests<T>() {
    return pushNamed<T>(AppRoutes.tooManyRequests);
  }

  // Navigate to service unavailable
  static Future<T?> navigateToServiceUnavailable<T>() {
    return pushNamed<T>(AppRoutes.serviceUnavailable);
  }

  // Navigate to gateway timeout
  static Future<T?> navigateToGatewayTimeout<T>() {
    return pushNamed<T>(AppRoutes.gatewayTimeout);
  }

  // Navigate to bad gateway
  static Future<T?> navigateToBadGateway<T>() {
    return pushNamed<T>(AppRoutes.badGateway);
  }

  // Navigate to internal server error
  static Future<T?> navigateToInternalServerError<T>() {
    return pushNamed<T>(AppRoutes.internalServerError);
  }

  // Navigate to bad request
  static Future<T?> navigateToBadRequest<T>() {
    return pushNamed<T>(AppRoutes.badRequest);
  }

  // Navigate to conflict
  static Future<T?> navigateToConflict<T>() {
    return pushNamed<T>(AppRoutes.conflict);
  }

  // Navigate to gone
  static Future<T?> navigateToGone<T>() {
    return pushNamed<T>(AppRoutes.gone);
  }

  // Navigate to length required
  static Future<T?> navigateToLengthRequired<T>() {
    return pushNamed<T>(AppRoutes.lengthRequired);
  }

  // Navigate to payload too large
  static Future<T?> navigateToPayloadTooLarge<T>() {
    return pushNamed<T>(AppRoutes.payloadTooLarge);
  }

  // Navigate to URI too long
  static Future<T?> navigateToUriTooLong<T>() {
    return pushNamed<T>(AppRoutes.uriTooLong);
  }

  // Navigate to unsupported media type
  static Future<T?> navigateToUnsupportedMediaType<T>() {
    return pushNamed<T>(AppRoutes.unsupportedMediaType);
  }

  // Navigate to range not satisfiable
  static Future<T?> navigateToRangeNotSatisfiable<T>() {
    return pushNamed<T>(AppRoutes.rangeNotSatisfiable);
  }

  // Navigate to expectation failed
  static Future<T?> navigateToExpectationFailed<T>() {
    return pushNamed<T>(AppRoutes.expectationFailed);
  }

  // Navigate to I'm a teapot
  static Future<T?> navigateToImATeapot<T>() {
    return pushNamed<T>(AppRoutes.imATeapot);
  }

  // Navigate to misdirected request
  static Future<T?> navigateToMisdirectedRequest<T>() {
    return pushNamed<T>(AppRoutes.misdirectedRequest);
  }

  // Navigate to unprocessable entity
  static Future<T?> navigateToUnprocessableEntity<T>() {
    return pushNamed<T>(AppRoutes.unprocessableEntity);
  }

  // Navigate to locked
  static Future<T?> navigateToLocked<T>() {
    return pushNamed<T>(AppRoutes.locked);
  }

  // Navigate to failed dependency
  static Future<T?> navigateToFailedDependency<T>() {
    return pushNamed<T>(AppRoutes.failedDependency);
  }

  // Navigate to too early
  static Future<T?> navigateToTooEarly<T>() {
    return pushNamed<T>(AppRoutes.tooEarly);
  }

  // Navigate to upgrade required
  static Future<T?> navigateToUpgradeRequired<T>() {
    return pushNamed<T>(AppRoutes.upgradeRequired);
  }

  // Navigate to precondition required
  static Future<T?> navigateToPreconditionRequired<T>() {
    return pushNamed<T>(AppRoutes.preconditionRequired);
  }

  // Navigate to request header fields too large
  static Future<T?> navigateToRequestHeaderFieldsTooLarge<T>() {
    return pushNamed<T>(AppRoutes.requestHeaderFieldsTooLarge);
  }

  // Navigate to unavailable for legal reasons
  static Future<T?> navigateToUnavailableForLegalReasons<T>() {
    return pushNamed<T>(AppRoutes.unavailableForLegalReasons);
  }

  // Navigate to not implemented
  static Future<T?> navigateToNotImplemented<T>() {
    return pushNamed<T>(AppRoutes.notImplemented);
  }

  // Navigate to HTTP version not supported
  static Future<T?> navigateToHttpVersionNotSupported<T>() {
    return pushNamed<T>(AppRoutes.httpVersionNotSupported);
  }

  // Navigate to variant also negotiates
  static Future<T?> navigateToVariantAlsoNegotiates<T>() {
    return pushNamed<T>(AppRoutes.variantAlsoNegotiates);
  }

  // Navigate to insufficient storage
  static Future<T?> navigateToInsufficientStorage<T>() {
    return pushNamed<T>(AppRoutes.insufficientStorage);
  }

  // Navigate to loop detected
  static Future<T?> navigateToLoopDetected<T>() {
    return pushNamed<T>(AppRoutes.loopDetected);
  }

  // Navigate to not extended
  static Future<T?> navigateToNotExtended<T>() {
    return pushNamed<T>(AppRoutes.notExtended);
  }

  // Navigate to network authentication required
  static Future<T?> navigateToNetworkAuthenticationRequired<T>() {
    return pushNamed<T>(AppRoutes.networkAuthenticationRequired);
  }

  // Navigate to network connect timeout error
  static Future<T?> navigateToNetworkConnectTimeoutError<T>() {
    return pushNamed<T>(AppRoutes.networkConnectTimeoutError);
  }

  // Navigate to network read timeout error
  static Future<T?> navigateToNetworkReadTimeoutError<T>() {
    return pushNamed<T>(AppRoutes.networkReadTimeoutError);
  }

  // Navigate to network send timeout error
  static Future<T?> navigateToNetworkSendTimeoutError<T>() {
    return pushNamed<T>(AppRoutes.networkSendTimeoutError);
  }

  // Navigate to network timeout error
  static Future<T?> navigateToNetworkTimeoutError<T>() {
    return pushNamed<T>(AppRoutes.networkTimeoutError);
  }

  // Navigate to network error
  static Future<T?> navigateToNetworkError<T>() {
    return pushNamed<T>(AppRoutes.networkError);
  }

  // Navigate to server error
  static Future<T?> navigateToServerError<T>() {
    return pushNamed<T>(AppRoutes.serverError);
  }

  // Navigate to unknown error
  static Future<T?> navigateToUnknownError<T>() {
    return pushNamed<T>(AppRoutes.unknownError);
  }
} 