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
    return PersonalChatModel(
      id: id,
      user1Id: map['user1Id'] ?? '',
      user2Id: map['user2Id'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      isGroupChat: map['isGroupChat'] ?? false,
      groupName: map['groupName'],
      groupDescription: map['groupDescription'],
      groupAvatarUrl: map['groupAvatarUrl'],
      lastMessage: map['lastMessage'] != null 
          ? PersonalMessageModel.fromMap(map['lastMessage'], '')
          : null,
      lastMessageTime: (map['lastMessageTime'] as Timestamp).toDate(),
      unreadCount: map['unreadCount'] ?? 0,
      user1Data: Map<String, dynamic>.from(map['user1Data'] ?? {}),
      user2Data: Map<String, dynamic>.from(map['user2Data'] ?? {}),
      participantData: map['participantData'] != null 
          ? Map<String, dynamic>.from(map['participantData'])
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