import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../core/logger.dart';
import '../services/mock_call_service.dart';

class MockCallScreen extends ConsumerStatefulWidget {
  final String callId;
  final String chatId;
  final String callType; // 'audio' or 'video'
  final String chatType; // 'personal' or 'community'
  final List<String> participants;

  const MockCallScreen({
    super.key,
    required this.callId,
    required this.chatId,
    required this.callType,
    required this.chatType,
    required this.participants,
  });

  @override
  ConsumerState<MockCallScreen> createState() => _MockCallScreenState();
}

class _MockCallScreenState extends ConsumerState<MockCallScreen> {
  final MockCallService _mockCallService = MockCallService();
  final Logger _logger = Logger('MockCallScreen');
  
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isSpeakerOn = false;
  String _callStatus = 'connecting';
  int _callDuration = 0;

  @override
  void initState() {
    super.initState();
    _initializeCall();
    _setupStreams();
  }

  void _initializeCall() {
    _logger.i('🎬 Initializing mock call: ${widget.callId}');
    _mockCallService.startCall(
      chatId: widget.chatId,
      callType: widget.callType,
      participants: widget.participants,
      chatType: widget.chatType,
    );
  }

  void _setupStreams() {
    _mockCallService.callStatusStream.listen((status) {
      setState(() {
        _callStatus = status;
      });
      _logger.i('🎬 Call status changed: $status');
    });

    _mockCallService.durationStream.listen((duration) {
      setState(() {
        _callDuration = duration;
      });
    });
  }

  @override
  void dispose() {
    _mockCallService.dispose();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header with call info
            _buildHeader(),
            
            // Main content area
            Expanded(
              child: Container(
                width: double.infinity,
                child: _buildMainContent(),
              ),
            ),
            
            // Call controls
            _buildCallControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Call status and duration
          Text(
            _callStatus.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatDuration(_callDuration),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          
          // Call type indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.callType == 'video' ? Icons.videocam : Icons.call,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.callType.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Mock video/audio indicator
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.callType == 'video' ? Icons.videocam : Icons.mic,
                  color: Colors.white,
                  size: 60,
                ),
                const SizedBox(height: 16),
                Text(
                  widget.callType == 'video' ? 'Mock Video Call' : 'Mock Audio Call',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Simulator Mode',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Call status message
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: Colors.blue.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Text(
              _getStatusMessage(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusMessage() {
    switch (_callStatus) {
      case 'connecting':
        return '🎬 Connecting to mock call...';
      case 'connected':
        return '🎬 Mock call connected! (Simulator mode)';
      case 'answered':
        return '🎬 Call answered! (Simulator mode)';
      case 'ended':
        return '🎬 Call ended (Simulator mode)';
      case 'declined':
        return '🎬 Call declined (Simulator mode)';
      default:
        return '🎬 Mock call in progress...';
    }
  }

  Widget _buildCallControls() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Main call controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Mute button
              _buildControlButton(
                icon: _isMuted ? Icons.mic_off : Icons.mic,
                backgroundColor: _isMuted ? Colors.red : Colors.white.withValues(alpha: 0.2),
                onPressed: () {
                  setState(() {
                    _isMuted = !_isMuted;
                  });
                  _mockCallService.toggleMute();
                },
              ),
              
              // End call button
              _buildControlButton(
                icon: Icons.call_end,
                backgroundColor: Colors.red,
                onPressed: () {
                  _endCall();
                },
              ),
              
              // Camera toggle (for video calls)
              if (widget.callType == 'video')
                _buildControlButton(
                  icon: _isCameraOff ? Icons.videocam_off : Icons.videocam,
                  backgroundColor: _isCameraOff ? Colors.red : Colors.white.withValues(alpha: 0.2),
                  onPressed: () {
                    setState(() {
                      _isCameraOff = !_isCameraOff;
                    });
                    _mockCallService.toggleCamera();
                  },
                ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Secondary controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Speaker button
              _buildControlButton(
                icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                backgroundColor: _isSpeakerOn ? Colors.blue : Colors.white.withValues(alpha: 0.2),
                onPressed: () {
                  setState(() {
                    _isSpeakerOn = !_isSpeakerOn;
                  });
                },
              ),
              
              // Switch camera (for video calls)
              if (widget.callType == 'video')
                _buildControlButton(
                  icon: Icons.switch_camera,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  onPressed: () {
                    _mockCallService.switchCamera();
                  },
                ),
            ],
          ),
          
          const SizedBox(height: 30),
          
          // Test buttons for simulator
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '🎬 Simulator Test Controls',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: ElevatedButton(
                          onPressed: () {
                            _mockCallService.answerCall(
                              callId: widget.callId,
                              chatId: widget.chatId,
                              chatType: widget.chatType,
                            );
                          },
                          child: const Text('Answer'),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: ElevatedButton(
                          onPressed: () {
                            _mockCallService.declineCall(
                              callId: widget.callId,
                              chatId: widget.chatId,
                              chatType: widget.chatType,
                            );
                          },
                          child: const Text('Decline'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color backgroundColor,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  void _endCall() async {
    _logger.i('🎬 Ending mock call');
    await _mockCallService.endCall(
      callId: widget.callId,
      chatId: widget.chatId,
      chatType: widget.chatType,
    );
    
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
} 