import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/auth_providers.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../core/navigation.dart';

class PhoneAuthScreen extends HookConsumerWidget {
  const PhoneAuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phoneController = useTextEditingController();
    final otpController = useTextEditingController();
    final isOtpSent = useState(false);
    final isLoading = ref.watch(authLoadingProvider);
    final error = ref.watch(authErrorProvider);

    // Listen to auth state changes
    ref.listen(authNotifierProvider, (previous, next) {
      next.whenData((user) {
        if (user != null) {
          // Navigate to home screen when authenticated
          AppNavigation.navigateToHome(context);
        }
      });
    });

    // Show error if any
    useEffect(() {
      if (error != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error!),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        });
      }
      return null;
    }, [error]);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to MOJO'),
        backgroundColor: AppTheme.neutralWhite,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo/Title
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.phone_android,
                size: 80,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: AppConstants.largePadding),
            Text(
              AppConstants.appName,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              'Sign in with your phone number',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.onSurfaceColor.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: AppConstants.largePadding * 2),

            if (!isOtpSent.value) ...[
              // Phone Number Input
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: '+1 234 567 8900',
                  prefixIcon: Icon(Icons.phone),
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
                          final phoneNumber = phoneController.text.trim();
                          if (phoneNumber.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter a phone number'),
                                backgroundColor: AppTheme.errorColor,
                              ),
                            );
                            return;
                          }

                          ref.read(phoneNumberProvider.notifier).state = phoneNumber;
                          await ref.read(authNotifierProvider.notifier).sendOtp(phoneNumber);
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
                              const SnackBar(
                                content: Text('Please enter the OTP'),
                                backgroundColor: AppTheme.errorColor,
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
                },
                child: const Text('Change Phone Number'),
              ),
            ],
            
            // Anonymous Login Section
            const SizedBox(height: AppConstants.largePadding),
            const Divider(),
            const SizedBox(height: AppConstants.defaultPadding),
            
            Text(
              'Or continue as guest',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.onSurfaceColor.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isLoading
                    ? null
                    : () async {
                        try {
                          await ref.read(authNotifierProvider.notifier).signInAnonymously();
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to sign in as guest: $e'),
                              backgroundColor: AppTheme.errorColor,
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
          ],
        ),
      ),
    );
  }
} 