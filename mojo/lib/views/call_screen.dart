import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/auth_providers.dart';
import '../providers/call_providers.dart';
import '../providers/database_providers.dart';
import '../models/user_model.dart';
import '../core/constants.dart';
import '../core/navigation_service.dart';
import '../widgets/loading_widget.dart';
import 'dart:async';

class CallScreen extends HookConsumerWidget {
  final String callId;
  final String chatId;
  final String callType; // 'audio' or 'video'
  final bool isIncoming;

  const CallScreen({
    super.key,
    required this.callId,
    required this.chatId,
    required this.callType,
    this.isIncoming = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(authNotifierProvider);
    
    // State variables
    final callDuration = useState<int>(0);
    final isCallActive = useState<bool>(true);
    
    // Timer for call duration
    useEffect(() {
      Timer? timer;
      if (isCallActive.value) {
        timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          callDuration.value++;
        });
      }
      return () => timer?.cancel();
    }, [isCallActive.value]);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: currentUserAsync.when(
          data: (currentUser) {
            if (currentUser == null) {
              return const Center(
                child: Text(
                  'User not authenticated',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            return Column(
              children: [
                _buildHeader(context, ref, currentUserAsync),
                Expanded(
                  child: _buildMainContent(context, ref, currentUserAsync, callDuration),
                ),
                _buildCallControls(context, ref, callDuration, isCallActive),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
          error: (_, __) => const Center(
            child: Text(
              'Error loading user',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, AsyncValue<UserModel?> userAsync) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  callType == 'video' ? 'Video Call' : 'Audio Call',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Call in progress',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, WidgetRef ref, AsyncValue<UserModel?> userAsync, ValueNotifier<int> callDuration) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Call type icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              callType == 'video' ? Icons.videocam : Icons.call,
              size: 60,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          
          // Call status
          Text(
            isIncoming ? 'Incoming Call' : 'Call in Progress',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          // Call duration
          Text(
            _formatDuration(callDuration.value),
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallControls(BuildContext context, WidgetRef ref, ValueNotifier<int> callDuration, ValueNotifier<bool> isCallActive) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Mute button
          _buildControlButton(
            icon: Icons.mic_off,
            label: 'Mute',
            onPressed: () {
              // TODO: Implement mute functionality
            },
          ),
          
          // End call button
          _buildControlButton(
            icon: Icons.call_end,
            label: 'End',
            backgroundColor: Colors.red,
            onPressed: () {
              // TODO: Implement end call functionality
              Navigator.pop(context);
            },
          ),
          
          // Speaker button
          _buildControlButton(
            icon: Icons.volume_up,
            label: 'Speaker',
            onPressed: () {
              // TODO: Implement speaker functionality
            },
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? backgroundColor,
  }) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

 