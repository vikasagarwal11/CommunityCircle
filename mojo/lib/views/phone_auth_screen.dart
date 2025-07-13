import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/auth_providers.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../core/navigation_service.dart';

String sanitizePhoneNumber(String input, {String defaultCountryCode = '+1'}) {
  String digits = input.replaceAll(RegExp(r'\D'), '');
  if (input.trim().startsWith('+')) {
    return '+$digits';
  } else {
    return '$defaultCountryCode$digits';
  }
}

class PhoneAuthScreen extends HookConsumerWidget {
  const PhoneAuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phoneController = useTextEditingController();
    final otpController = useTextEditingController();
    final isOtpSent = useState(false);
    final isLoading = ref.watch(authLoadingProvider);
    final error = ref.watch(authErrorProvider);
    final phoneError = useState<String?>(null);

    // Listen to auth state changes
    ref.listen(authNotifierProvider, (previous, next) {
      next.whenData((user) {
        if (user != null && user.role != 'anonymous') {
          // Navigate to home screen when authenticated (not guest)
          NavigationService.navigateToHome(role: user.role);
        }
        // For anonymous users, do not navigate; AuthWrapper will show PublicHomeScreen
      });
    });

    // Show error if any
    useEffect(() {
      if (error != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        });
      }
      return null;
    }, [error]);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Phone Authentication'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        leading: BackButton(
          onPressed: () {
            ref.read(authLoadingProvider.notifier).state = false;
            Navigator.of(context).maybePop();
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.phone_android,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: AppConstants.smallPadding),
                  Text(
                    'Welcome to MOJO',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: AppConstants.smallPadding),
                  Text(
                    'Enter your phone number to get started',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.largePadding * 2),

            if (!isOtpSent.value) ...[
              // Phone Number Input
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'e.g. 1234567890 or +1 234 567 8900',
                  prefixIcon: Icon(Icons.phone),
                  errorText: phoneError.value,
                ),
                onChanged: (value) {
                  phoneError.value = null; // Clear error on change
                  if (error != null) {
                    ref.read(authErrorProvider.notifier).state = null;
                  }
                },
              ),
              const SizedBox(height: AppConstants.largePadding),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final phoneNumber = phoneController.text.trim();
                          if (phoneNumber.isEmpty) {
                            phoneError.value = 'Please enter a phone number';
                            return;
                          }
                          final sanitized = sanitizePhoneNumber(phoneNumber);
                          if (sanitized.length < 12) { // +1 + 10 digits = 12
                            phoneError.value = 'Please enter a valid phone number';
                            return;
                          }
                          ref.read(phoneNumberProvider.notifier).state = sanitized;
                          await ref.read(authNotifierProvider.notifier).sendOtp(sanitized);
                          isOtpSent.value = true;
                        },
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Send OTP'),
                ),
              ),
            ] else ...[
              // OTP Input
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'Enter OTP',
                  hintText: '123456',
                  prefixIcon: Icon(Icons.security),
                  counterText: '',
                ),
                onChanged: (value) {
                  // Clear error when user types
                  if (error != null) {
                    ref.read(authErrorProvider.notifier).state = null;
                  }
                },
              ),
              const SizedBox(height: AppConstants.largePadding),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final otp = otpController.text.trim();
                          if (otp.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Please enter the OTP'),
                                backgroundColor: Theme.of(context).colorScheme.error,
                              ),
                            );
                            return;
                          }

                          await ref.read(authNotifierProvider.notifier).verifyOtp(otp);
                        },
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Verify OTP'),
                ),
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              TextButton(
                onPressed: () {
                  isOtpSent.value = false;
                  otpController.clear();
                  ref.read(authErrorProvider.notifier).state = null;
                  ref.read(authLoadingProvider.notifier).state = false;
                },
                child: const Text('Change Phone Number'),
              ),
            ],

            // Anonymous Login Section
            const SizedBox(height: AppConstants.largePadding),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Want to explore first?',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Continue as guest to browse public communities. Sign up anytime for full access!',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isLoading
                    ? null
                    : () async {
                        try {
                          await ref.read(authNotifierProvider.notifier).signInAnonymously();
                          // Optionally: show a Lottie animation or snackbar
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to sign in as guest: $e'),
                              backgroundColor: Theme.of(context).colorScheme.error,
                            ),
                          );
                        }
                      },
                icon: const Icon(Icons.person_outline),
                label: const Text('Continue as Guest'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ], // Single closing bracket for the Column's children
        ),
      ),
    );
  }
}