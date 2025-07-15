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
  });

  factory PersonalMessageModel.fromMap(Map<String, dynamic> map, String id) {
    return PersonalMessageModel(
      id: id,
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      text: map['text'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      metadata: map['metadata'],
      readBy: List<String>.from(map['readBy'] ?? []),
      reactions: Map<String, String>.from(map['reactions'] ?? {}),
      replyToMessageId: map['replyToMessageId'],
      replyToText: map['replyToText'],
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
    );
  }
}

class PersonalChatModel {
  final String id;
  final String user1Id;
  final String user2Id;
  final PersonalMessageModel? lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final Map<String, dynamic> user1Data;
  final Map<String, dynamic> user2Data;

  PersonalChatModel({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.user1Data,
    required this.user2Data,
  });

  factory PersonalChatModel.fromMap(Map<String, dynamic> map, String id) {
    return PersonalChatModel(
      id: id,
      user1Id: map['user1Id'] ?? '',
      user2Id: map['user2Id'] ?? '',
      lastMessage: map['lastMessage'] != null 
          ? PersonalMessageModel.fromMap(map['lastMessage'], '')
          : null,
      lastMessageTime: (map['lastMessageTime'] as Timestamp).toDate(),
      unreadCount: map['unreadCount'] ?? 0,
      user1Data: Map<String, dynamic>.from(map['user1Data'] ?? {}),
      user2Data: Map<String, dynamic>.from(map['user2Data'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user1Id': user1Id,
      'user2Id': user2Id,
      'lastMessage': lastMessage?.toMap(),
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'unreadCount': unreadCount,
      'user1Data': user1Data,
      'user2Data': user2Data,
    };
  }

  String getOtherUserId(String currentUserId) {
    return user1Id == currentUserId ? user2Id : user1Id;
  }

  Map<String, dynamic> getOtherUserData(String currentUserId) {
    return user1Id == currentUserId ? user2Data : user1Data;
  }
} 