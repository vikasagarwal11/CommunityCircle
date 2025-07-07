import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String communityId;
  final String userId;
  final String text;
  final String? mediaUrl;
  final String? mediaType; // "image", "video", "audio", "document"
  final String? threadId; // For threaded replies
  final DateTime timestamp;
  final Map<String, List<String>> reactions; // emoji -> [userId1, userId2, ...]
  final List<String> mentions; // userIds mentioned with @
  final Map<String, dynamic>? metadata;

  MessageModel({
    required this.id,
    required this.communityId,
    required this.userId,
    required this.text,
    this.mediaUrl,
    this.mediaType,
    this.threadId,
    required this.timestamp,
    required this.reactions,
    required this.mentions,
    this.metadata,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map, String id) {
    return MessageModel(
      id: id,
      communityId: map['communityId'] ?? '',
      userId: map['userId'] ?? '',
      text: map['text'] ?? '',
      mediaUrl: map['mediaUrl'],
      mediaType: map['mediaType'],
      threadId: map['threadId'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      reactions: (map['reactions'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, List<String>.from(value)),
          ) ?? {},
      mentions: List<String>.from(map['mentions'] ?? []),
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'communityId': communityId,
      'userId': userId,
      'text': text,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'threadId': threadId,
      'timestamp': timestamp,
      'reactions': reactions,
      'mentions': mentions,
      'metadata': metadata,
    };
  }

  MessageModel copyWith({
    String? id,
    String? communityId,
    String? userId,
    String? text,
    String? mediaUrl,
    String? mediaType,
    String? threadId,
    DateTime? timestamp,
    Map<String, List<String>>? reactions,
    List<String>? mentions,
    Map<String, dynamic>? metadata,
  }) {
    return MessageModel(
      id: id ?? this.id,
      communityId: communityId ?? this.communityId,
      userId: userId ?? this.userId,
      text: text ?? this.text,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      threadId: threadId ?? this.threadId,
      timestamp: timestamp ?? this.timestamp,
      reactions: reactions ?? this.reactions,
      mentions: mentions ?? this.mentions,
      metadata: metadata ?? this.metadata,
    );
  }

  // Helper methods
  bool get hasMedia => mediaUrl != null;
  bool get isThreadReply => threadId != null;
  bool get hasReactions => reactions.isNotEmpty;
  bool get hasMentions => mentions.isNotEmpty;
  int get reactionCount => reactions.values.fold(0, (sum, users) => sum + users.length);
  int get mentionCount => mentions.length;

  // Reaction helpers
  bool hasReaction(String emoji, String userId) {
    return reactions[emoji]?.contains(userId) ?? false;
  }

  void addReaction(String emoji, String userId) {
    if (!reactions.containsKey(emoji)) {
      reactions[emoji] = [];
    }
    if (!reactions[emoji]!.contains(userId)) {
      reactions[emoji]!.add(userId);
    }
  }

  void removeReaction(String emoji, String userId) {
    reactions[emoji]?.remove(userId);
    if (reactions[emoji]?.isEmpty ?? false) {
      reactions.remove(emoji);
    }
  }

  int getReactionCount(String emoji) {
    return reactions[emoji]?.length ?? 0;
  }

  @override
  String toString() {
    return 'MessageModel(id: $id, text: $text, userId: $userId, communityId: $communityId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MessageModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 