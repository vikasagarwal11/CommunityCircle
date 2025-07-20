import 'package:cloud_firestore/cloud_firestore.dart';

class PersonalMessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
  final List<String> readBy;
  final Map<String, String> reactions;
  final String? replyToMessageId;
  final String? replyToText;
  final String? callType; // 'audio' or 'video'
  final String? callStatus; // 'incoming', 'outgoing', 'missed', 'ended'
  final int? callDuration; // in seconds

  PersonalMessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.timestamp,
    this.metadata,
    required this.readBy,
    required this.reactions,
    this.replyToMessageId,
    this.replyToText,
    this.callType,
    this.callStatus,
    this.callDuration,
  });

  factory PersonalMessageModel.fromMap(Map<String, dynamic> map, String id) {
    // Helper function to safely convert dynamic to String
    String safeString(dynamic value) {
      if (value == null) return '';
      if (value is String) return value;
      return value.toString();
    }

    // Helper function to safely convert dynamic to List<String>
    List<String> safeStringList(dynamic value) {
      if (value == null) return [];
      if (value is List) {
        return value.map((item) => safeString(item)).toList();
      }
      return [];
    }

    // Helper function to safely convert dynamic to Map<String, String>
    Map<String, String> safeStringMap(dynamic value) {
      if (value == null) return {};
      if (value is Map) {
        return Map<String, String>.fromEntries(
          value.entries.map((entry) => MapEntry(
            safeString(entry.key),
            safeString(entry.value),
          )),
        );
      }
      return {};
    }

    return PersonalMessageModel(
      id: id,
      senderId: safeString(map['senderId']),
      receiverId: safeString(map['receiverId']),
      text: safeString(map['text']),
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: map['metadata'],
      readBy: safeStringList(map['readBy']),
      reactions: safeStringMap(map['reactions']),
      replyToMessageId: map['replyToMessageId'],
      replyToText: map['replyToText'],
      callType: map['callType'],
      callStatus: map['callStatus'],
      callDuration: map['callDuration'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'metadata': metadata,
      'readBy': readBy,
      'reactions': reactions,
      'replyToMessageId': replyToMessageId,
      'replyToText': replyToText,
      'callType': callType,
      'callStatus': callStatus,
      'callDuration': callDuration,
    };
  }

  PersonalMessageModel copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? text,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
    List<String>? readBy,
    Map<String, String>? reactions,
    String? replyToMessageId,
    String? replyToText,
    String? callType,
    String? callStatus,
    int? callDuration,
  }) {
    return PersonalMessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
      readBy: readBy ?? this.readBy,
      reactions: reactions ?? this.reactions,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyToText: replyToText ?? this.replyToText,
      callType: callType ?? this.callType,
      callStatus: callStatus ?? this.callStatus,
      callDuration: callDuration ?? this.callDuration,
    );
  }
}

class PersonalChatModel {
  final String id;
  final String user1Id;
  final String user2Id;
  final List<String> participants; // For group chats
  final bool isGroupChat;
  final String? groupName;
  final String? groupDescription;
  final String? groupAvatarUrl;
  final PersonalMessageModel? lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final Map<String, dynamic> user1Data;
  final Map<String, dynamic> user2Data;
  final Map<String, dynamic>? participantData; // For group chats

  PersonalChatModel({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    this.participants = const [],
    this.isGroupChat = false,
    this.groupName,
    this.groupDescription,
    this.groupAvatarUrl,
    this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.user1Data,
    required this.user2Data,
    this.participantData,
  });

  factory PersonalChatModel.fromMap(Map<String, dynamic> map, String id) {
    // Helper function to safely convert dynamic to String
    String safeString(dynamic value) {
      if (value == null) return '';
      if (value is String) return value;
      return value.toString();
    }

    // Helper function to safely convert dynamic to List<String>
    List<String> safeStringList(dynamic value) {
      if (value == null) return [];
      if (value is List) {
        return value.map((item) => safeString(item)).toList();
      }
      return [];
    }

    // Helper function to safely convert dynamic to Map<String, dynamic>
    Map<String, dynamic> safeDynamicMap(dynamic value) {
      if (value == null) return {};
      if (value is Map) {
        return Map<String, dynamic>.from(value);
      }
      return {};
    }

    return PersonalChatModel(
      id: id,
      user1Id: safeString(map['user1Id']),
      user2Id: safeString(map['user2Id']),
      participants: safeStringList(map['participants']),
      isGroupChat: map['isGroupChat'] == true,
      groupName: map['groupName'],
      groupDescription: map['groupDescription'],
      groupAvatarUrl: map['groupAvatarUrl'],
      lastMessage: map['lastMessage'] != null 
          ? PersonalMessageModel.fromMap(map['lastMessage'], '')
          : null,
      lastMessageTime: (map['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unreadCount: (map['unreadCount'] as int?) ?? 0,
      user1Data: safeDynamicMap(map['user1Data']),
      user2Data: safeDynamicMap(map['user2Data']),
      participantData: map['participantData'] != null 
          ? safeDynamicMap(map['participantData'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user1Id': user1Id,
      'user2Id': user2Id,
      'participants': participants,
      'isGroupChat': isGroupChat,
      'groupName': groupName,
      'groupDescription': groupDescription,
      'groupAvatarUrl': groupAvatarUrl,
      'lastMessage': lastMessage?.toMap(),
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'unreadCount': unreadCount,
      'user1Data': user1Data,
      'user2Data': user2Data,
      'participantData': participantData,
    };
  }

  String getOtherUserId(String currentUserId) {
    if (isGroupChat) {
      return groupName ?? 'Group Chat';
    }
    return user1Id == currentUserId ? user2Id : user1Id;
  }

  Map<String, dynamic> getOtherUserData(String currentUserId) {
    if (isGroupChat) {
      return {'displayName': groupName ?? 'Group Chat'};
    }
    return user1Id == currentUserId ? user2Data : user1Data;
  }

  List<String> getAllParticipants() {
    if (isGroupChat) {
      return participants;
    }
    return [user1Id, user2Id];
  }
} 