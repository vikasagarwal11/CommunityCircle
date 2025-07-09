import 'package:flutter/material.dart' as material;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import '../models/community_model.dart';
import '../models/user_model.dart';
import '../routes/app_routes.dart';

class NavigationService {
  static final material.GlobalKey<material.NavigatorState> navigatorKey = 
      material.GlobalKey<material.NavigatorState>();
  
  static material.NavigatorState? get navigator => navigatorKey.currentState;
  static material.BuildContext? get context => navigatorKey.currentContext;

  // Push named route
  static Future<T?> pushNamed<T>(String routeName, {Object? arguments}) {
    final ctx = context;
    if (ctx == null) return Future.value(null);
    
    return material.Navigator.of(ctx).pushNamed<T>(routeName, arguments: arguments);
  }

  // Push replacement named route
  static Future<T?> pushReplacementNamed<T>(String routeName, {Object? arguments}) {
    final ctx = context;
    if (ctx == null) return Future.value(null);
    
    return material.Navigator.of(ctx).pushReplacementNamed<T, void>(routeName, arguments: arguments);
  }

  // Push and remove until
  static Future<T?> pushNamedAndRemoveUntil<T>(String routeName, {Object? arguments}) {
    final ctx = context;
    if (ctx == null) return Future.value(null);
    
    return material.Navigator.of(ctx).pushNamedAndRemoveUntil<T>(
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  // Push with fade transition
  static Future<T?> pushWithFade<T>(material.Widget page, {Object? arguments}) {
    final ctx = context;
    if (ctx == null) return Future.value(null);
    
    return material.Navigator.of(ctx).push<T>(
      material.PageRouteBuilder<T>(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return material.FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  // Go back
  static void goBack<T>([T? result]) {
    final ctx = context;
    if (ctx == null) return;
    
    material.Navigator.of(ctx).pop<T>(result);
  }

  // Can go back
  static bool canGoBack() {
    final ctx = context;
    if (ctx == null) return false;
    
    return material.Navigator.of(ctx).canPop();
  }

  // Show general dialog
  static Future<T?> showGeneralDialog<T>({
    required material.Widget child,
    bool barrierDismissible = true,
    material.Color? barrierColor,
    String? barrierLabel,
  }) {
    final ctx = context;
    if (ctx == null) return Future.value(null);
    
    return material.showGeneralDialog<T>(
      context: ctx,
      pageBuilder: (context, animation, secondaryAnimation) => child,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor ?? material.Colors.black54,
      barrierLabel: barrierLabel,
    );
  }

  // Show bottom sheet
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
  }) {
    final ctx = context;
    if (ctx == null) return Future.value(null);
    
    return material.showModalBottomSheet<T>(
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
  }

  // Show snackbar
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
    if (ctx == null) return;
    
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
  }

  // Show error dialog
  static Future<T?> showErrorDialog<T>({
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    final ctx = context;
    if (ctx == null) return Future.value(null);
    
    return material.showDialog<T>(
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
  }

  // Show confirmation dialog
  static Future<bool?> showConfirmationDialog({
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
  }) {
    final ctx = context;
    if (ctx == null) return Future.value(null);
    
    return material.showDialog<bool>(
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
  }

  // Show loading dialog
  static Future<T?> showLoadingDialog<T>({
    String? message,
    bool barrierDismissible = false,
  }) {
    final ctx = context;
    if (ctx == null) return Future.value(null);
    
    return material.showDialog<T>(
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
  }

  // Hide loading dialog
  static void hideLoadingDialog() {
    goBack();
  }

  // Get route arguments safely
  static T? getRouteArguments<T>(material.BuildContext context) {
    final args = material.ModalRoute.of(context)?.settings.arguments;
    if (args is T) {
      return args;
    }
    return null;
  }

  // Get community ID from route arguments
  static String? getCommunityIdFromArgs(material.BuildContext context) {
    final args = getRouteArguments<dynamic>(context);
    if (args is String) {
      return args;
    } else if (args is Map<String, dynamic>) {
      return args['communityId'] as String?;
    }
    return null;
  }

  // Get user from route arguments
  static UserModel? getUserFromArgs(material.BuildContext context) {
    final args = getRouteArguments<dynamic>(context);
    if (args is UserModel) {
      return args;
    } else if (args is Map<String, dynamic>) {
      final userData = args['user'] as Map<String, dynamic>?;
      if (userData != null) {
        return UserModel.fromMap(userData);
      }
    }
    return null;
  }

  // Get community from route arguments
  static CommunityModel? getCommunityFromArgs(material.BuildContext context) {
    final args = getRouteArguments<dynamic>(context);
    if (args is CommunityModel) {
      return args;
    } else if (args is Map<String, dynamic>) {
      final communityData = args['community'] as Map<String, dynamic>?;
      if (communityData != null) {
        return CommunityModel.fromMap(communityData, '');
      }
    }
    return null;
  }

  // Navigate to phone auth
  static Future<T?> navigateToPhoneAuth<T>() {
    return pushNamed<T>(AppRoutes.phoneAuth);
  }

  // Navigate to community details
  static Future<T?> navigateToCommunityDetails<T>(String communityId, {CommunityModel? community}) {
    if (community != null) {
      return pushNamed<T>(AppRoutes.communityDetails, arguments: {
        'communityId': communityId,
        'community': community.toMap(),
      });
    }
    return pushNamed<T>(AppRoutes.communityDetails, arguments: communityId);
  }

  // Navigate to admin management
  static Future<T?> navigateToAdminManagement<T>(CommunityModel community) {
    return pushNamed<T>(AppRoutes.adminManagement, arguments: community);
  }

  // Navigate to home with role-based routing
  static Future<T?> navigateToHome<T>({String? role}) {
    if (role == null || role.isEmpty) {
      return pushNamedAndRemoveUntil<T>(AppRoutes.publicHome);
    }
    
    switch (role.toLowerCase()) {
      case 'admin':
        return pushNamedAndRemoveUntil<T>(AppRoutes.adminHome);
      case 'business':
        return pushNamedAndRemoveUntil<T>(AppRoutes.businessHome);
      case 'moderator':
        return pushNamedAndRemoveUntil<T>(AppRoutes.moderatorHome);
      default:
        return pushNamedAndRemoveUntil<T>(AppRoutes.home);
    }
  }

  // Navigate to profile
  static Future<T?> navigateToProfile<T>({UserModel? user}) {
    if (user != null) {
      return pushNamed<T>(AppRoutes.profile, arguments: {
        'user': user.toMap(),
      });
    }
    return pushNamed<T>(AppRoutes.profile);
  }

  // Navigate to chat
  static Future<T?> navigateToChat<T>(String communityId, {String? channelId}) {
    return pushNamed<T>(AppRoutes.chat, arguments: {
      'communityId': communityId,
      'channelId': channelId,
    });
  }

  // Navigate to create community
  static Future<T?> navigateToCreateCommunity<T>() {
    return pushNamed<T>(AppRoutes.createCommunity);
  }

  // Navigate to search
  static Future<T?> navigateToSearch<T>({String? initialQuery}) {
    return pushNamed<T>(AppRoutes.search, arguments: initialQuery);
  }

  // Navigate to settings
  static Future<T?> navigateToSettings<T>() {
    return pushNamed<T>(AppRoutes.settings);
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