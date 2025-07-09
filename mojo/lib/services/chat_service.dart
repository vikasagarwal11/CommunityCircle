import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../core/constants.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();

  // Get messages stream for a community
  Stream<List<MessageModel>> getMessagesStream(String communityId) {
    return _firestore
        .collection(AppConstants.messagesCollection)
        .where('communityId', isEqualTo: communityId)
        .orderBy('timestamp', descending: true)
        .limit(50) // Limit for performance
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get thread messages
  Stream<List<MessageModel>> getThreadMessages(String threadId) {
    return _firestore
        .collection(AppConstants.messagesCollection)
        .where('threadId', isEqualTo: threadId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Send a new message
  Future<void> sendMessage({
    required String communityId,
    required String userId,
    required String text,
    String? mediaUrl,
    String? mediaType,
    String? threadId,
    List<String> mentions = const [],
  }) async {
    try {
      _logger.i('Sending message to community: $communityId');
      
      final message = MessageModel(
        id: '', // Will be set by Firestore
        communityId: communityId,
        userId: userId,
        text: text,
        mediaUrl: mediaUrl,
        mediaType: mediaType,
        threadId: threadId,
        timestamp: DateTime.now(),
        reactions: {},
        mentions: mentions,
        metadata: {
          'edited': false,
          'editedAt': null,
        },
      );

      await _firestore
          .collection(AppConstants.messagesCollection)
          .add(message.toMap());

      _logger.i('Message sent successfully');
    } catch (e) {
      _logger.e('Error sending message: $e');
      throw Exception('Failed to send message');
    }
  }

  // Edit a message
  Future<void> editMessage({
    required String messageId,
    required String newText,
    String? mediaUrl,
    String? mediaType,
  }) async {
    try {
      _logger.i('Editing message: $messageId');
      
      final updates = <String, dynamic>{
        'text': newText,
        'mediaUrl': mediaUrl,
        'mediaType': mediaType,
        'metadata.edited': true,
        'metadata.editedAt': DateTime.now(),
      };

      await _firestore
          .collection(AppConstants.messagesCollection)
          .doc(messageId)
          .update(updates);

      _logger.i('Message edited successfully');
    } catch (e) {
      _logger.e('Error editing message: $e');
      throw Exception('Failed to edit message');
    }
  }

  // Delete a message
  Future<void> deleteMessage(String messageId) async {
    try {
      _logger.i('Deleting message: $messageId');
      
      await _firestore
          .collection(AppConstants.messagesCollection)
          .doc(messageId)
          .delete();

      _logger.i('Message deleted successfully');
    } catch (e) {
      _logger.e('Error deleting message: $e');
      throw Exception('Failed to delete message');
    }
  }

  // Add reaction to a message
  Future<void> addReaction({
    required String messageId,
    required String emoji,
    required String userId,
  }) async {
    try {
      _logger.i('Adding reaction $emoji to message: $messageId');
      
      await _firestore
          .collection(AppConstants.messagesCollection)
          .doc(messageId)
          .update({
        'reactions.$emoji': FieldValue.arrayUnion([userId]),
      });

      _logger.i('Reaction added successfully');
    } catch (e) {
      _logger.e('Error adding reaction: $e');
      throw Exception('Failed to add reaction');
    }
  }

  // Remove reaction from a message
  Future<void> removeReaction({
    required String messageId,
    required String emoji,
    required String userId,
  }) async {
    try {
      _logger.i('Removing reaction $emoji from message: $messageId');
      
      await _firestore
          .collection(AppConstants.messagesCollection)
          .doc(messageId)
          .update({
        'reactions.$emoji': FieldValue.arrayRemove([userId]),
      });

      _logger.i('Reaction removed successfully');
    } catch (e) {
      _logger.e('Error removing reaction: $e');
      throw Exception('Failed to remove reaction');
    }
  }

  // Mark message as read
  Future<void> markAsRead({
    required String messageId,
    required String userId,
  }) async {
    try {
      await _firestore
          .collection(AppConstants.messagesCollection)
          .doc(messageId)
          .update({
        'readBy': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      _logger.e('Error marking message as read: $e');
    }
  }

  // Get unread message count for a user in a community
  Stream<int> getUnreadCount(String communityId, String userId) {
    return _firestore
        .collection(AppConstants.messagesCollection)
        .where('communityId', isEqualTo: communityId)
        .where('timestamp', isGreaterThan: DateTime.now().subtract(const Duration(days: 7)))
        .snapshots()
        .map((snapshot) {
      int count = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final readBy = List<String>.from(data['readBy'] ?? []);
        if (!readBy.contains(userId)) {
          count++;
        }
      }
      return count;
    });
  }

  // Search messages in a community
  Stream<List<MessageModel>> searchMessages({
    required String communityId,
    required String query,
  }) {
    return _firestore
        .collection(AppConstants.messagesCollection)
        .where('communityId', isEqualTo: communityId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
            .where((message) => message.text.toLowerCase().contains(query.toLowerCase()))
            .toList());
  }

  // Get message statistics for a community
  Future<Map<String, dynamic>> getMessageStats(String communityId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.messagesCollection)
          .where('communityId', isEqualTo: communityId)
          .get();

      int totalMessages = snapshot.docs.length;
      int totalReactions = 0;
      int totalThreads = 0;
      Set<String> uniqueUsers = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final reactions = data['reactions'] as Map<String, dynamic>? ?? {};
        final threadId = data['threadId'];
        final userId = data['userId'];

        // Count reactions
        for (var reaction in reactions.values) {
          totalReactions += (reaction as List).length;
        }

        // Count threads
        if (threadId != null) {
          totalThreads++;
        }

        // Count unique users
        uniqueUsers.add(userId);
      }

      return {
        'totalMessages': totalMessages,
        'totalReactions': totalReactions,
        'totalThreads': totalThreads,
        'uniqueUsers': uniqueUsers.length,
        'avgReactionsPerMessage': totalMessages > 0 ? totalReactions / totalMessages : 0,
      };
    } catch (e) {
      _logger.e('Error getting message stats: $e');
      return {};
    }
  }

  // Upload media file (placeholder for Firebase Storage integration)
  Future<String?> uploadMedia({
    required String filePath,
    required String communityId,
    required String mediaType,
  }) async {
    try {
      _logger.i('Uploading media file: $filePath');
      
      // TODO: Implement Firebase Storage upload
      // For now, return a placeholder URL
      await Future.delayed(const Duration(seconds: 2)); // Simulate upload
      
      final fileName = filePath.split('/').last;
      final mediaUrl = 'https://storage.googleapis.com/mojo-media/$communityId/$fileName';
      
      _logger.i('Media uploaded successfully: $mediaUrl');
      return mediaUrl;
    } catch (e) {
      _logger.e('Error uploading media: $e');
      return null;
    }
  }

  // Get typing indicators
  Stream<List<String>> getTypingUsers(String communityId) {
    return _firestore
        .collection('typing_indicators')
        .doc(communityId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return [];
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return [];
      
      final now = DateTime.now();
      final typingUsers = <String>[];
      
      for (var entry in data.entries) {
        final userId = entry.key;
        final timestamp = (entry.value as Timestamp).toDate();
        
        // Remove users who stopped typing more than 5 seconds ago
        if (now.difference(timestamp).inSeconds < 5) {
          typingUsers.add(userId);
        }
      }
      
      return typingUsers;
    });
  }

  // Set typing indicator
  Future<void> setTypingIndicator({
    required String communityId,
    required String userId,
    required bool isTyping,
  }) async {
    try {
      if (isTyping) {
        await _firestore
            .collection('typing_indicators')
            .doc(communityId)
            .set({
          userId: FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        await _firestore
            .collection('typing_indicators')
            .doc(communityId)
            .update({
          userId: FieldValue.delete(),
        });
      }
    } catch (e) {
      _logger.e('Error setting typing indicator: $e');
    }
  }
} 