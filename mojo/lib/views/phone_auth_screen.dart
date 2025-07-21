import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/auth_providers.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../core/navigation_service.dart';
import '../core/logger.dart';
import 'package:flutter/foundation.dart';

String sanitizePhoneNumber(String input, {String defaultCountryCode = '+1'}) {
  String digits = input.replaceAll(RegExp(r'\D'), '');
  if (input.trim().startsWith('+')) {
    return '+$digits';
  } else {
    return '$defaultCountryCode$digits';
  }
}

void phoneAuthDebug(String message) {
  debugPrint('[PHONE_AUTH_DEBUG] ${DateTime.now().toIso8601String()}: $message');
}

class PhoneAuthScreen extends HookConsumerWidget {
  const PhoneAuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phoneController = useTextEditingController();
    final otpController = useTextEditingController();
    final isOtpSent = ref.watch(otpSentProvider); // Use Riverpod provider
    final isLoading = ref.watch(authLoadingProvider);
    final error = ref.watch(authErrorProvider);
    final phoneError = useState<String?>(null);
    final isMounted = useIsMounted();
    final isDebugMode = useState(false);
    final _logger = Logger('PhoneAuthScreen');
    final currentPhoneNumber = useState<String>('');

    phoneAuthDebug('PhoneAuthScreen build called, isOtpSent=$isOtpSent, isLoading=$isLoading');

    // Listen to auth state changes
    ref.listen(authNotifierProvider, (previous, next) {
      next.whenData((user) {
        if (user != null && user.role != 'anonymous' && isMounted()) {
          // Navigate to home screen when authenticated (not guest)
          NavigationService.navigateToHome(role: user.role);
        }
        // For anonymous users, do not navigate; AuthWrapper will show PublicHomeScreen
      });
    });

    // Show error if any
    useEffect(() {
      if (error != null && isMounted()) {
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
            if (isMounted()) Navigator.of(context).maybePop();
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

                if (!isOtpSent) ...[
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
                      if (error != null && isMounted()) {
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
                              if (!isMounted()) return;
                              phoneAuthDebug('User pressed Send OTP');
                              final phoneNumber = phoneController.text.trim();
                              if (phoneNumber.isEmpty) {
                                phoneError.value = 'Please enter a phone number';
                                phoneAuthDebug('Phone number empty');
                                return;
                              }
                              final sanitized = sanitizePhoneNumber(phoneNumber);
                              phoneAuthDebug('Sanitized number: $sanitized');
                              if (sanitized.length < 12) { // +1 + 10 digits = 12
                                phoneError.value = 'Please enter a valid phone number';
                                phoneAuthDebug('Sanitized number too short');
                                return;
                              }
                              currentPhoneNumber.value = sanitized;
                              ref.read(phoneNumberProvider.notifier).state = sanitized;
                              phoneAuthDebug('About to call sendOtp');
                              try {
                                await ref.read(authNotifierProvider.notifier).sendOtp(sanitized);
                                if (!isMounted()) return;
                                phoneAuthDebug('OTP send completed');
                                ref.read(authLoadingProvider.notifier).state = false; // Ensure loading is reset
                                phoneAuthDebug('Set isLoading to false after OTP sent');
                              } catch (e) {
                                phoneAuthDebug('Error sending OTP: $e');
                                if (isMounted()) {
                                  ref.read(authLoadingProvider.notifier).state = false;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to send OTP. Please try again.'),
                                      backgroundColor: Theme.of(context).colorScheme.error,
                                    ),
                                  );
                                }
                              }
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
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Enter the 6-digit code sent to',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          currentPhoneNumber.value,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Debug mode: Show test OTP info
                        if (isDebugMode.value) ...[
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.secondary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Test OTP: Check Firebase Console for test codes',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context).colorScheme.secondary,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        
                        TextField(
                          controller: otpController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                letterSpacing: 8,
                                fontWeight: FontWeight.bold,
                              ),
                          decoration: const InputDecoration(
                            labelText: 'Enter OTP',
                            hintText: '123456',
                            prefixIcon: Icon(Icons.security),
                            counterText: '',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            // Clear error when user types
                            if (error != null && isMounted()) {
                              ref.read(authErrorProvider.notifier).state = null;
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppConstants.largePadding),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () async {
                              if (!isMounted()) return;
                              phoneAuthDebug('User pressed Verify OTP');
                              try {
                                final otp = otpController.text.trim();
                                if (otp.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Please enter the OTP'),
                                      backgroundColor: Theme.of(context).colorScheme.error,
                                    ),
                                  );
                                  phoneAuthDebug('OTP empty');
                                  return;
                                }
                                if (otp.length != 6) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Please enter a 6-digit OTP'),
                                      backgroundColor: Theme.of(context).colorScheme.error,
                                    ),
                                  );
                                  return;
                                }

                                await ref.read(authNotifierProvider.notifier).verifyOtp(otp);
                                phoneAuthDebug('OTP verification completed');
                              } catch (e) {
                                _logger.e('OTP verification error: $e');
                                if (isMounted()) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to verify OTP. Please try again.'),
                                      backgroundColor: Theme.of(context).colorScheme.error,
                                    ),
                                  );
                                }
                              }
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {
                          if (isMounted()) {
                            ref.read(otpSentProvider.notifier).state = false;
                            phoneAuthDebug('isOtpSent.value set to false (via Riverpod)');
                            otpController.clear();
                            ref.read(authErrorProvider.notifier).state = null;
                            ref.read(authLoadingProvider.notifier).state = false;
                          }
                        },
                        child: const Text('Change Phone Number'),
                      ),
                      TextButton(
                        onPressed: isLoading
                            ? null
                            : () async {
                                final phoneNumber = currentPhoneNumber.value;
                                if (phoneNumber.isNotEmpty && isMounted()) {
                                  await ref.read(authNotifierProvider.notifier).sendOtp(phoneNumber);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('OTP resent to $phoneNumber'),
                                      backgroundColor: Theme.of(context).colorScheme.primary,
                                    ),
                                  );
                                }
                              },
                        child: const Text('Resend OTP'),
                      ),
                    ],
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
                            if (isMounted()) {
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
                
                // Debug Mode Section (only in debug builds)
                if (kDebugMode) ...[
                  const SizedBox(height: AppConstants.largePadding),
                  const Divider(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: isDebugMode.value,
                        onChanged: (value) {
                          isDebugMode.value = value ?? false;
                        },
                      ),
                      const Text('Debug Mode'),
                    ],
                  ),
                  if (isDebugMode.value) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Use test phone number for development',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Firebase Test Numbers:',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '• Use any test number configured in Firebase Console\n'
                            '• Firebase will automatically provide test OTPs\n'
                            '• No real SMS will be sent',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: phoneController,
                            decoration: const InputDecoration(
                              labelText: 'Test Phone',
                              hintText: '+1234567890',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            phoneController.text = '+1234567890';
                          },
                          child: const Text('Set Test'),
                        ),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
        );
  }
}