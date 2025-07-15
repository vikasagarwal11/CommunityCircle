import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// Current Firebase user stream
final firebaseUserProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

// Current user model provider
final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final user = await ref.watch(firebaseUserProvider.future);
  if (user == null) return null;
  
  final authService = ref.watch(authServiceProvider);
  return await authService.getOrCreateUser(user);
});

// Auth state provider (loading, authenticated, unauthenticated)
final authStateProvider = StreamProvider<AuthState>((ref) {
  final userAsync = ref.watch(firebaseUserProvider);
  
  return userAsync.when(
    data: (user) => Stream.value(user != null ? AuthState.authenticated : AuthState.unauthenticated),
    loading: () => Stream.value(AuthState.loading),
    error: (_, __) => Stream.value(AuthState.unauthenticated),
  );
});

// Phone number provider for OTP flow
final phoneNumberProvider = StateProvider<String>((ref) => '');

// Verification ID provider for OTP flow
final verificationIdProvider = StateProvider<String?>((ref) => null);

// Loading state provider
final authLoadingProvider = StateProvider<bool>((ref) => false);

// Error state provider
final authErrorProvider = StateProvider<String?>((ref) => null);

// Auth state enum
enum AuthState {
  loading,
  authenticated,
  unauthenticated,
}

// Auth notifier for managing auth operations
class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthService _authService;
  final Ref _ref;

  AuthNotifier(this._authService, this._ref) : super(const AsyncValue.loading()) {
    _initialize();
  }

  void _initialize() {
    _authService.authStateChanges.listen((user) async {
      if (user != null) {
        final userModel = await _authService.getOrCreateUser(user);
        state = AsyncValue.data(userModel);
      } else {
        state = const AsyncValue.data(null);
      }
    });
  }

  Future<void> sendOtp(String phoneNumber) async {
    state = const AsyncValue.loading();
    _ref.read(authLoadingProvider.notifier).state = true;
    _ref.read(authErrorProvider.notifier).state = null;

    try {
      await _authService.sendOtp(
        phoneNumber: phoneNumber,
        onCodeSent: (verificationId) {
          _ref.read(verificationIdProvider.notifier).state = verificationId;
          _ref.read(authLoadingProvider.notifier).state = false;
        },
        onError: (error) {
          _ref.read(authErrorProvider.notifier).state = error;
          _ref.read(authLoadingProvider.notifier).state = false;
          state = AsyncValue.error(error, StackTrace.current);
        },
      );
    } catch (e) {
      _ref.read(authErrorProvider.notifier).state = e.toString();
      _ref.read(authLoadingProvider.notifier).state = false;
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> verifyOtp(String otp) async {
    final verificationId = _ref.read(verificationIdProvider);
    if (verificationId == null) {
      _ref.read(authErrorProvider.notifier).state = 'Verification ID not found';
      return;
    }

    _ref.read(authLoadingProvider.notifier).state = true;
    _ref.read(authErrorProvider.notifier).state = null;

    try {
      final userModel = await _authService.verifyOtp(
        verificationId: verificationId,
        otp: otp,
        onError: (error) {
          _ref.read(authErrorProvider.notifier).state = error;
          _ref.read(authLoadingProvider.notifier).state = false;
        },
      );

      if (userModel != null) {
        state = AsyncValue.data(userModel);
        _ref.read(authLoadingProvider.notifier).state = false;
        _ref.read(verificationIdProvider.notifier).state = null;
      }
    } catch (e) {
      _ref.read(authErrorProvider.notifier).state = e.toString();
      _ref.read(authLoadingProvider.notifier).state = false;
    }
  }

  Future<void> signOut() async {
    try {
      await _authService.signOut();
      state = const AsyncValue.data(null);
      _ref.read(phoneNumberProvider.notifier).state = '';
      _ref.read(verificationIdProvider.notifier).state = null;
      // Invalidate all user-dependent providers to cancel Firestore listeners
      // TODO: Uncomment when these providers are implemented
      // _ref.invalidate(messagesProvider);
      // _ref.invalidate(threadMessagesProvider);
      // _ref.invalidate(typingUsersProvider);
      // _ref.invalidate(unreadCountProvider);
      // _ref.invalidate(messageSearchProvider);
      // _ref.invalidate(messageStatsProvider);
      // _ref.invalidate(communityMessagesProvider);
      // _ref.invalidate(pendingJoinRequestsProvider);
      // Add more invalidations here if you add more user-dependent providers
    } catch (e) {
      _ref.read(authErrorProvider.notifier).state = e.toString();
    }
  }

  Future<void> updateProfile({
    String? displayName,
    String? email,
    String? profilePictureUrl,
  }) async {
    final currentUser = state.value;
    if (currentUser == null) return;

    try {
      await _authService.updateProfile(
        userId: currentUser.id,
        displayName: displayName,
        email: email,
        profilePictureUrl: profilePictureUrl,
      );

      // Update the current user state
      final updatedUser = currentUser.copyWith(
        displayName: displayName ?? currentUser.displayName,
        email: email ?? currentUser.email,
        profilePictureUrl: profilePictureUrl ?? currentUser.profilePictureUrl,
      );
      state = AsyncValue.data(updatedUser);
    } catch (e) {
      _ref.read(authErrorProvider.notifier).state = e.toString();
    }
  }

  Future<void> signInAnonymously() async {
    _ref.read(authLoadingProvider.notifier).state = true;
    _ref.read(authErrorProvider.notifier).state = null;

    try {
      final userModel = await _authService.signInAnonymously();
      if (userModel != null) {
        state = AsyncValue.data(userModel);
        _ref.read(authLoadingProvider.notifier).state = false;
      }
    } catch (e) {
      _ref.read(authErrorProvider.notifier).state = e.toString();
      _ref.read(authLoadingProvider.notifier).state = false;
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

// Auth notifier provider
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService, ref);
});

// Provider to check if user can create communities
final canCreateCommunityProvider = FutureProvider<bool>((ref) async {
  final authService = ref.watch(authServiceProvider);
  final userRole = await authService.getUserRole();
  return userRole != 'anonymous';
});

// Provider to check if user can access admin features
final canAccessAdminFeaturesProvider = FutureProvider<bool>((ref) async {
  final authService = ref.watch(authServiceProvider);
  final userRole = await authService.getUserRole();
  return userRole == 'admin' || userRole == 'business';
});

// Provider to check if user can access business features
final canAccessBusinessFeaturesProvider = FutureProvider<bool>((ref) async {
  final authService = ref.watch(authServiceProvider);
  final userRole = await authService.getUserRole();
  return userRole == 'business';
}); 