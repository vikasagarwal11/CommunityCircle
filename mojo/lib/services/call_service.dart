import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/logger.dart';

class CallService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger('CallService');

  // Start a call
  Future<void> startCall({
    required String chatId,
    required String callType, // 'audio' or 'video'
    required List<String> participants,
  }) async {
    try {
      _logger.i('Starting $callType call in chat: $chatId');
      
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final callData = {
        'callId': '${chatId}_${DateTime.now().millisecondsSinceEpoch}',
        'chatId': chatId,
        'callType': callType,
        'initiatorId': user.uid,
        'participants': participants,
        'status': 'incoming',
        'startTime': FieldValue.serverTimestamp(),
        'endTime': null,
        'duration': 0,
      };

      // Create call document
      await _firestore
          .collection('calls')
          .doc(callData['callId'] as String)
          .set(callData);

      // Add call message to chat
      await _firestore
          .collection('personal_chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'senderId': user.uid,
        'receiverId': participants.firstWhere((id) => id != user.uid),
        'text': 'Incoming $callType call',
        'timestamp': FieldValue.serverTimestamp(),
        'readBy': [user.uid],
        'reactions': {},
        'callType': callType,
        'callStatus': 'outgoing',
        'callDuration': null,
      });

      _logger.i('Call started successfully');
    } catch (e) {
      _logger.e('Error starting call: $e');
      throw Exception('Failed to start call');
    }
  }

  // Answer a call
  Future<void> answerCall({
    required String callId,
    required String chatId,
  }) async {
    try {
      _logger.i('Answering call: $callId');
      
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore
          .collection('calls')
          .doc(callId)
          .update({
        'status': 'active',
        'answeredBy': user.uid,
        'answeredAt': FieldValue.serverTimestamp(),
      });

      // Add call answered message
      await _firestore
          .collection('personal_chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'senderId': user.uid,
        'receiverId': '', // Will be set by the system
        'text': 'Call answered',
        'timestamp': FieldValue.serverTimestamp(),
        'readBy': [user.uid],
        'reactions': {},
        'callType': 'audio', // Will be updated from call data
        'callStatus': 'answered',
        'callDuration': null,
      });

      _logger.i('Call answered successfully');
    } catch (e) {
      _logger.e('Error answering call: $e');
      throw Exception('Failed to answer call');
    }
  }

  // End a call
  Future<void> endCall({
    required String callId,
    required String chatId,
    required int duration,
  }) async {
    try {
      _logger.i('Ending call: $callId');
      
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore
          .collection('calls')
          .doc(callId)
          .update({
        'status': 'ended',
        'endTime': FieldValue.serverTimestamp(),
        'duration': duration,
        'endedBy': user.uid,
      });

      // Add call ended message
      await _firestore
          .collection('personal_chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'senderId': user.uid,
        'receiverId': '', // Will be set by the system
        'text': 'Call ended',
        'timestamp': FieldValue.serverTimestamp(),
        'readBy': [user.uid],
        'reactions': {},
        'callType': 'audio', // Will be updated from call data
        'callStatus': 'ended',
        'callDuration': duration,
      });

      _logger.i('Call ended successfully');
    } catch (e) {
      _logger.e('Error ending call: $e');
      throw Exception('Failed to end call');
    }
  }

  // Decline a call
  Future<void> declineCall({
    required String callId,
    required String chatId,
  }) async {
    try {
      _logger.i('Declining call: $callId');
      
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore
          .collection('calls')
          .doc(callId)
          .update({
        'status': 'declined',
        'declinedBy': user.uid,
        'declinedAt': FieldValue.serverTimestamp(),
      });

      // Add call declined message
      await _firestore
          .collection('personal_chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'senderId': user.uid,
        'receiverId': '', // Will be set by the system
        'text': 'Call declined',
        'timestamp': FieldValue.serverTimestamp(),
        'readBy': [user.uid],
        'reactions': {},
        'callType': 'audio', // Will be updated from call data
        'callStatus': 'declined',
        'callDuration': null,
      });

      _logger.i('Call declined successfully');
    } catch (e) {
      _logger.e('Error declining call: $e');
      throw Exception('Failed to decline call');
    }
  }

  // Get active calls for a user
  Stream<QuerySnapshot> getActiveCalls(String userId) {
    return _firestore
        .collection('calls')
        .where('participants', arrayContains: userId)
        .where('status', whereIn: ['incoming', 'active'])
        .snapshots();
  }

  // Get call history for a chat
  Stream<QuerySnapshot> getCallHistory(String chatId) {
    return _firestore
        .collection('calls')
        .where('chatId', isEqualTo: chatId)
        .orderBy('startTime', descending: true)
        .limit(20)
        .snapshots();
  }
} 