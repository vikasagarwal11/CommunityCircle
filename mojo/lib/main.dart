import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';
import 'core/logger.dart';
import 'core/navigation_service.dart';
import 'core/theme.dart';
import 'providers/auth_providers.dart';
import 'providers/notification_providers.dart';
import 'providers/offline_providers.dart';
import 'views/phone_auth_screen.dart';
import 'views/home_screen.dart';
import 'widgets/welcome_flash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive for local storage
  await Hive.initFlutter();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Crashlytics
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
  
  // Initialize NavigationService
  NavigationService.initialize();
  
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'MOJO',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: Consumer(
        builder: (context, ref, child) {
          final userAsync = ref.watch(authNotifierProvider);
          
          return userAsync.when(
            data: (user) {
              // Initialize services in background to prevent ANR
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _initializeServicesInBackground(ref);
              });
              
              if (user == null) {
                return const PhoneAuthScreen();
              }
              
              return const HomeScreen();
            },
            loading: () => const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stack) => const PhoneAuthScreen(),
          );
        },
      ),
    );
  }

  // Move heavy initialization to background
  void _initializeServicesInBackground(WidgetRef ref) {
    // Use compute or isolate for heavy operations
    Future.microtask(() async {
      try {
        // Add a small delay to ensure UI is ready
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Initialize local storage service first
        final localStorage = ref.read(localStorageServiceProvider);
        await localStorage.initialize();
        
        // Add a small delay between initializations
        await Future.delayed(const Duration(milliseconds: 50));
        
        // Initialize offline sync service
        await ref.read(offlineSyncNotifierProvider.notifier).initialize();
        
        // Initialize notification service in background
        await ref.read(notificationNotifierProvider.notifier).initialize();
        
        // Track app session in background
        // ref.read(analyticsServiceProvider).trackAppSessionStart();
        
        if (ref.read(authNotifierProvider).value != null) {
          // ref.read(analyticsServiceProvider).trackUserEngagement('authenticated_session_start');
        }
      } catch (e) {
        // Log error but don't crash the app
        print('Background initialization error: $e');
      }
    });
  }
}
