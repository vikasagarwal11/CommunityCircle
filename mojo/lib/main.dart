import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'core/theme.dart';
import 'providers/auth_providers.dart';
import 'routes/app_routes.dart';
import 'views/phone_auth_screen.dart';
import 'views/home_screen.dart';

void main() async {
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
    
    return authState.when(
      data: (state) {
        switch (state) {
          case AuthState.authenticated:
            return const HomeScreen();
          case AuthState.unauthenticated:
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
      error: (_, __) => const PhoneAuthScreen(),
    );
  }
}
