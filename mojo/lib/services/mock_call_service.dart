import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/logger.dart';
import '../models/user_model.dart';
import '../models/community_model.dart';

class MockCallService {
  final Logger _logger = Logger('MockCallService');
  
  // Simulated call state
  bool _isInCall = false;
  String _currentCallId = '';
  String _callType = '';
  Timer? _callTimer;
  int _callDuration = 0;
  
  // Stream controllers for real-time updates
  final StreamController<bool> _callStateController = StreamController<bool>.broadcast();
  final StreamController<int> _durationController = StreamController<int>.broadcast();
  final StreamController<String> _callStatusController = StreamController<String>.broadcast();

  // Getters
  bool get isInCall => _isInCall;
  String get currentCallId => _currentCallId;
  String get callType => _callType;
  int get callDuration => _callDuration;
  
  // Streams
  Stream<bool> get callStateStream => _callStateController.stream;
  Stream<int> get durationStream => _durationController.stream;
  Stream<String> get callStatusStream => _callStatusController.stream;

  // Start a mock call
  Future<void> startCall({
    required String chatId,
    required String callType, // 'audio' or 'video'
    required List<String> participants,
    String chatType = 'personal',
  }) async {
    try {
      _logger.i('🎬 Starting MOCK $callType call in $chatType chat: $chatId');
      _logger.i('🎬 Participants: $participants');
      
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 2));
      
      _currentCallId = '${chatId}_${DateTime.now().millisecondsSinceEpoch}';
      _callType = callType;
      _isInCall = true;
      _callDuration = 0;
      
      _callStateController.add(true);
      _callStatusController.add('connecting');
      
      _logger.i('🎬 Mock call started: $_currentCallId');
      
      // Simulate call connection
      await Future.delayed(const Duration(seconds: 3));
      _callStatusController.add('connected');
      
      // Start duration timer
      _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _callDuration++;
        _durationController.add(_callDuration);
      });
      
      _logger.i('🎬 Mock call connected successfully');
      
    } catch (e) {
      _logger.e('🎬 Error starting mock call: $e');
      rethrow;
    }
  }

  // Answer a mock call
  Future<void> answerCall({
    required String callId,
    required String chatId,
    String chatType = 'personal',
  }) async {
    try {
      _logger.i('🎬 Answering MOCK call: $callId');
      
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));
      
      _callStatusController.add('answered');
      _logger.i('🎬 Mock call answered successfully');
      
    } catch (e) {
      _logger.e('🎬 Error answering mock call: $e');
      rethrow;
    }
  }

  // End a mock call
  Future<void> endCall({
    required String callId,
    required String chatId,
    String chatType = 'personal',
  }) async {
    try {
      _logger.i('🎬 Ending MOCK call: $callId');
      
      // Stop timer
      _callTimer?.cancel();
      
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));
      
      _isInCall = false;
      _currentCallId = '';
      _callType = '';
      
      _callStateController.add(false);
      _callStatusController.add('ended');
      
      _logger.i('🎬 Mock call ended successfully. Duration: ${_callDuration}s');
      
    } catch (e) {
      _logger.e('🎬 Error ending mock call: $e');
      rethrow;
    }
  }

  // Decline a mock call
  Future<void> declineCall({
    required String callId,
    required String chatId,
    String chatType = 'personal',
  }) async {
    try {
      _logger.i('🎬 Declining MOCK call: $callId');
      
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));
      
      _callStatusController.add('declined');
      
      _logger.i('🎬 Mock call declined successfully');
      
    } catch (e) {
      _logger.e('🎬 Error declining mock call: $e');
      rethrow;
    }
  }

  // Toggle mute (mock)
  void toggleMute() {
    _logger.i('🎬 Toggle mute (mock)');
    // In real implementation, this would control audio
  }

  // Toggle camera (mock)
  void toggleCamera() {
    _logger.i('🎬 Toggle camera (mock)');
    // In real implementation, this would control video
  }

  // Switch camera (mock)
  void switchCamera() {
    _logger.i('🎬 Switch camera (mock)');
    // In real implementation, this would switch between front/back cameras
  }

  // Dispose resources
  void dispose() {
    _callTimer?.cancel();
    _callStateController.close();
    _durationController.close();
    _callStatusController.close();
  }
} 