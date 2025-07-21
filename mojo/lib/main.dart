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
import 'routes/app_routes.dart';
import 'providers/auth_providers.dart';
import 'providers/notification_providers.dart';
import 'providers/offline_providers.dart';
import 'views/phone_auth_screen.dart';
import 'views/main_navigation_screen.dart';
import 'widgets/welcome_flash_screen.dart';

// Error boundary widget to catch ValueNotifier disposal errors
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  
  const ErrorBoundary({super.key, required this.child});

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  bool _hasError = false;
  String _errorMessage = '';

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _hasError = false;
                        _errorMessage = '';
                      });
                    },
                    child: const Text('Try Again'),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton(
                    onPressed: () {
                      // Force restart by navigating to auth screen
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const PhoneAuthScreen(),
                        ),
                        (route) => false,
                      );
                    },
                    child: const Text('Restart App'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return widget.child;
  }

  @override
  void initState() {
    super.initState();
    
    // Catch Flutter errors
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exception.toString().contains('ValueNotifier') && 
          details.exception.toString().contains('disposed')) {
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorMessage = 'App state error. Please restart the app.';
          });
        }
      }
    };
  }

  @override
  void dispose() {
    // Reset the error handler
    FlutterError.onError = FlutterError.presentError;
    super.dispose();
  }
}

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
      navigatorKey: NavigationService.navigatorKey,
      onGenerateRoute: AppRoutes.generateRoute,
      home: ErrorBoundary(
        child: Consumer(
          builder: (context, ref, child) {
            final userAsync = ref.watch(authNotifierProvider);
            
            return userAsync.when(
              data: (user) {
                // Initialize services in background to prevent ANR
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  // Add a longer delay to ensure UI is fully built
                  Future.delayed(const Duration(milliseconds: 500), () {
                    _initializeServicesInBackground(ref);
                  });
                });
                
                if (user == null) {
                  return const PhoneAuthScreen();
                }
                
                return const MainNavigationScreen();
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
      ),
    );
  }

  // Move heavy initialization to background
  void _initializeServicesInBackground(WidgetRef ref) {
    // Use compute or isolate for heavy operations
    Future.microtask(() async {
      try {
        // Add a small delay to ensure UI is ready
        await Future.delayed(const Duration(milliseconds: 200));
        
        // Initialize local storage service first
        try {
          final localStorage = ref.read(localStorageServiceProvider);
          await localStorage.initialize();
        } catch (e) {
          print('Local storage initialization error: $e');
        }
        
        // Add a small delay between initializations
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Initialize offline sync service
        try {
          await ref.read(offlineSyncNotifierProvider.notifier).initialize();
        } catch (e) {
          print('Offline sync initialization error: $e');
        }
        
        // Add a small delay
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Initialize notification service in background
        try {
          await ref.read(notificationNotifierProvider.notifier).initialize();
        } catch (e) {
          print('Notification service initialization error: $e');
        }
        
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
