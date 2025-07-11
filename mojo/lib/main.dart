import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'core/theme.dart';
import 'core/navigation_service.dart';
import 'providers/auth_providers.dart';
import 'routes/app_routes.dart';
import 'views/phone_auth_screen.dart';
import 'views/home_screen.dart';
import 'views/public_home_screen.dart';

/*void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyA1erxrq4I9_U3Z1fduNUSO6oFC10vnDGo",
        authDomain: "mojo-b4260.firebaseapp.com",
        projectId: "mojo-b4260",
        storageBucket: "mojo-b4260.appspot.com",
        messagingSenderId: "264754676317",
        appId: "1:264754676317:web:38d5571e205f4b1fc783b4",
        measurementId: "G-NP8HRGZ6RJ",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}*/
void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Initialize NavigationService with analytics
    await NavigationService.initialize();
    
    runApp(
      const ProviderScope(
        child: MyApp(),
      ),
    );
  } catch (e) {
    // Fallback to basic app without Firebase
    runApp(
      const ProviderScope(
        child: MyApp(),
      ),
    );
  }
}
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'MOJO',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      navigatorKey: NavigationService.navigatorKey,
      onGenerateRoute: AppRoutes.generateRoute,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final userAsync = ref.watch(authNotifierProvider);
    
    return authState.when(
      data: (state) {
        switch (state) {
          case AuthState.authenticated:
            return userAsync.when(
              data: (user) {
                if (user == null) {
                  // Track anonymous session
                  NavigationService.trackAppSessionStart();
                  NavigationService.trackUserEngagement('anonymous_session_start');
                  return const PhoneAuthScreen();
                }
                
                // Track authenticated session
                NavigationService.trackAppSessionStart();
                NavigationService.trackUserEngagement('authenticated_session_start', parameters: {
                  'user_role': user.role,
                  'user_id': user.id,
                });
                
                // Role-based routing
                switch (user.role) {
                  case 'anonymous':
                    return const PublicHomeScreen();
                  case 'member':
                  case 'admin':
                  case 'business':
                    return const HomeScreen();
                  default:
                    return const PhoneAuthScreen();
                }
              },
              loading: () => const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) {
                // Track error state
                NavigationService.trackError('auth_error', error.toString(), parameters: {'error_type': 'user_load_failed'});
                return const PhoneAuthScreen();
              },
            );
          case AuthState.unauthenticated:
            // Track unauthenticated session
            NavigationService.trackAppSessionStart();
            NavigationService.trackUserEngagement('unauthenticated_session_start');
            return const PhoneAuthScreen();
          case AuthState.loading:
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
        }
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) {
        // Track error state
        NavigationService.trackError('auth_state_error', error.toString(), parameters: {'error_type': 'auth_state_failed'});
        return const PhoneAuthScreen();
      },
    );
  }
}
