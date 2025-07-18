import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/logger.dart';
import '../models/personal_message_model.dart';

class SharedChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger('SharedChatService');

  // Start a call (works for both personal and community chats)
  Future<void> startCall({
    required String chatId,
    required String callType, // 'audio' or 'video'
    required List<String> participants,
    String chatType = 'personal', // 'personal' or 'community'
  }) async {
    try {
      _logger.i('Starting $callType call in $chatType chat: $chatId');
      
      final user = _auth.currentUser;
      if (user == null) {
        _logger.e('User not authenticated');
        throw Exception('User not authenticated');
      }

      _logger.i('User authenticated: ${user.uid}');

      final callData = {
        'callId': '${chatId}_${DateTime.now().millisecondsSinceEpoch}',
        'chatId': chatId,
        'chatType': chatType,
        'callType': callType,
        'initiatorId': user.uid,
        'participants': participants,
        'status': 'incoming',
        'startTime': FieldValue.serverTimestamp(),
        'endTime': null,
        'duration': 0,
      };

      _logger.i('Creating call document with data: $callData');

      // Create call document
      await _firestore
          .collection('calls')
          .doc(callData['callId'] as String)
          .set(callData);

      _logger.i('Call document created successfully');

      // Add call message to chat
      final messageCollection = chatType == 'personal' 
          ? 'personal_chats' 
          : 'communities';
      
      _logger.i('Adding call message to $messageCollection collection');
      
      await _firestore
          .collection(messageCollection)
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
      _logger.e('Error type: ${e.runtimeType}');
      _logger.e('Error details: ${e.toString()}');
      
      // Don't throw a generic exception, let the caller handle the specific error
      rethrow;
    }
  }

  // Answer a call
  Future<void> answerCall({
    required String callId,
    required String chatId,
    String chatType = 'personal',
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
      final messageCollection = chatType == 'personal' 
          ? 'personal_chats' 
          : 'communities';
      
      await _firestore
          .collection(messageCollection)
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
    String chatType = 'personal',
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
      final messageCollection = chatType == 'personal' 
          ? 'personal_chats' 
          : 'communities';
      
      await _firestore
          .collection(messageCollection)
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
    String chatType = 'personal',
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
      final messageCollection = chatType == 'personal' 
          ? 'personal_chats' 
          : 'communities';
      
      await _firestore
          .collection(messageCollection)
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
  Stream<QuerySnapshot> getCallHistory(String chatId, {String chatType = 'personal'}) {
    return _firestore
        .collection('calls')
        .where('chatId', isEqualTo: chatId)
        .where('chatType', isEqualTo: chatType)
        .orderBy('startTime', descending: true)
        .limit(20)
        .snapshots();
  }

  // Send message with call support
  Future<void> sendMessage({
    required String chatId,
    required String text,
    String chatType = 'personal',
    String? replyToMessageId,
    String? replyToText,
    Map<String, String>? reactions,
    List<String>? readBy,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final messageData = {
        'senderId': user.uid,
        'receiverId': '', // Will be set based on chat type
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
        'readBy': readBy ?? [user.uid],
        'reactions': reactions ?? {},
        'replyToMessageId': replyToMessageId,
        'replyToText': replyToText,
      };

      final messageCollection = chatType == 'personal' 
          ? 'personal_chats' 
          : 'communities';

      // Add message to Firestore
      await _firestore
          .collection(messageCollection)
          .doc(chatId)
          .collection('messages')
          .add(messageData);

      // Update last message in chat
      try {
        await _firestore
            .collection(messageCollection)
            .doc(chatId)
            .update({
          'lastMessage': messageData,
          'lastMessageTime': FieldValue.serverTimestamp(),
        });
      } catch (updateError) {
        _logger.w('Error updating chat document: $updateError');
      }

      _logger.i('Message sent successfully');
    } catch (e) {
      _logger.e('Error sending message: $e');
      throw Exception('Failed to send message');
    }
  }

  // Mark message as read
  Future<void> markMessageAsRead({
    required String messageId,
    required String chatId,
    String chatType = 'personal',
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final messageCollection = chatType == 'personal' 
          ? 'personal_chats' 
          : 'communities';

      await _firestore
          .collection(messageCollection)
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({
        'readBy': FieldValue.arrayUnion([user.uid]),
      });
    } catch (e) {
      _logger.w('Error marking message as read: $e');
    }
  }
} 