import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/logger.dart';
import '../models/personal_message_model.dart';

class GroupChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger('GroupChatService');

  // Convert a 1:1 chat to a group chat
  Future<void> convertToGroupChat({
    required String chatId,
    required String groupName,
    required String groupDescription,
    required List<String> newParticipants,
  }) async {
    try {
      _logger.i('Converting chat $chatId to group chat');
      
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get current chat data
      final chatDoc = await _firestore
          .collection('personal_chats')
          .doc(chatId)
          .get();

      if (!chatDoc.exists) {
        throw Exception('Chat not found');
      }

      final chatData = chatDoc.data()!;
      final currentParticipants = [chatData['user1Id'], chatData['user2Id']];
      final allParticipants = [...currentParticipants, ...newParticipants];

      // Update chat to group chat
      await _firestore
          .collection('personal_chats')
          .doc(chatId)
          .update({
        'isGroupChat': true,
        'groupName': groupName,
        'groupDescription': groupDescription,
        'participants': allParticipants,
        'createdBy': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Add system message about group creation
      await _firestore
          .collection('personal_chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'senderId': 'system',
        'receiverId': '',
        'text': '$groupName group created by ${user.displayName ?? 'User'}',
        'timestamp': FieldValue.serverTimestamp(),
        'readBy': allParticipants,
        'reactions': {},
        'metadata': {
          'type': 'system',
          'action': 'group_created',
          'groupName': groupName,
          'createdBy': user.uid,
        },
      });

      // Add participants added message
      if (newParticipants.isNotEmpty) {
        await _firestore
            .collection('personal_chats')
            .doc(chatId)
            .collection('messages')
            .add({
          'senderId': 'system',
          'receiverId': '',
          'text': '${newParticipants.length} participant(s) added to the group',
          'timestamp': FieldValue.serverTimestamp(),
          'readBy': allParticipants,
          'reactions': {},
          'metadata': {
            'type': 'system',
            'action': 'participants_added',
            'addedParticipants': newParticipants,
            'addedBy': user.uid,
          },
        });
      }

      _logger.i('Chat converted to group successfully');
    } catch (e) {
      _logger.e('Error converting to group chat: $e');
      throw Exception('Failed to convert to group chat');
    }
  }

  // Add participants to an existing group chat
  Future<void> addParticipantsToGroup({
    required String chatId,
    required List<String> newParticipants,
  }) async {
    try {
      _logger.i('Adding ${newParticipants.length} participants to group $chatId');
      
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get current chat data
      final chatDoc = await _firestore
          .collection('personal_chats')
          .doc(chatId)
          .get();

      if (!chatDoc.exists) {
        throw Exception('Chat not found');
      }

      final chatData = chatDoc.data()!;
      if (!chatData['isGroupChat']) {
        throw Exception('Chat is not a group chat');
      }

      final currentParticipants = List<String>.from(chatData['participants'] ?? []);
      final updatedParticipants = [...currentParticipants, ...newParticipants];

      // Update participants list
      await _firestore
          .collection('personal_chats')
          .doc(chatId)
          .update({
        'participants': updatedParticipants,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': user.uid,
      });

      // Add system message about new participants
      await _firestore
          .collection('personal_chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'senderId': 'system',
        'receiverId': '',
        'text': '${newParticipants.length} participant(s) added to the group',
        'timestamp': FieldValue.serverTimestamp(),
        'readBy': updatedParticipants,
        'reactions': {},
        'metadata': {
          'type': 'system',
          'action': 'participants_added',
          'addedParticipants': newParticipants,
          'addedBy': user.uid,
        },
      });

      _logger.i('Participants added successfully');
    } catch (e) {
      _logger.e('Error adding participants: $e');
      throw Exception('Failed to add participants');
    }
  }

  // Remove participants from a group chat
  Future<void> removeParticipantsFromGroup({
    required String chatId,
    required List<String> participantsToRemove,
  }) async {
    try {
      _logger.i('Removing ${participantsToRemove.length} participants from group $chatId');
      
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get current chat data
      final chatDoc = await _firestore
          .collection('personal_chats')
          .doc(chatId)
          .get();

      if (!chatDoc.exists) {
        throw Exception('Chat not found');
      }

      final chatData = chatDoc.data()!;
      if (!chatData['isGroupChat']) {
        throw Exception('Chat is not a group chat');
      }

      final currentParticipants = List<String>.from(chatData['participants'] ?? []);
      final updatedParticipants = currentParticipants
          .where((id) => !participantsToRemove.contains(id))
          .toList();

      // Update participants list
      await _firestore
          .collection('personal_chats')
          .doc(chatId)
          .update({
        'participants': updatedParticipants,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': user.uid,
      });

      // Add system message about removed participants
      await _firestore
          .collection('personal_chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'senderId': 'system',
        'receiverId': '',
        'text': '${participantsToRemove.length} participant(s) removed from the group',
        'timestamp': FieldValue.serverTimestamp(),
        'readBy': updatedParticipants,
        'reactions': {},
        'metadata': {
          'type': 'system',
          'action': 'participants_removed',
          'removedParticipants': participantsToRemove,
          'removedBy': user.uid,
        },
      });

      _logger.i('Participants removed successfully');
    } catch (e) {
      _logger.e('Error removing participants: $e');
      throw Exception('Failed to remove participants');
    }
  }

  // Update group information
  Future<void> updateGroupInfo({
    required String chatId,
    String? groupName,
    String? groupDescription,
    String? groupAvatarUrl,
  }) async {
    try {
      _logger.i('Updating group info for chat $chatId');
      
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': user.uid,
      };

      if (groupName != null) updates['groupName'] = groupName;
      if (groupDescription != null) updates['groupDescription'] = groupDescription;
      if (groupAvatarUrl != null) updates['groupAvatarUrl'] = groupAvatarUrl;

      await _firestore
          .collection('personal_chats')
          .doc(chatId)
          .update(updates);

      // Add system message about group update
      await _firestore
          .collection('personal_chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'senderId': 'system',
        'receiverId': '',
        'text': 'Group information updated',
        'timestamp': FieldValue.serverTimestamp(),
        'readBy': [],
        'reactions': {},
        'metadata': {
          'type': 'system',
          'action': 'group_updated',
          'updatedBy': user.uid,
          'updates': updates,
        },
      });

      _logger.i('Group info updated successfully');
    } catch (e) {
      _logger.e('Error updating group info: $e');
      throw Exception('Failed to update group info');
    }
  }

  // Get group chat participants
  Future<List<String>> getGroupParticipants(String chatId) async {
    try {
      final chatDoc = await _firestore
          .collection('personal_chats')
          .doc(chatId)
          .get();

      if (!chatDoc.exists) {
        return [];
      }

      final chatData = chatDoc.data()!;
      if (!chatData['isGroupChat']) {
        return [chatData['user1Id'], chatData['user2Id']];
      }

      return List<String>.from(chatData['participants'] ?? []);
    } catch (e) {
      _logger.e('Error getting group participants: $e');
      return [];
    }
  }
} 