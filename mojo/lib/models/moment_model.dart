import 'package:cloud_firestore/cloud_firestore.dart';

class MomentModel {
  final String id;
  final String communityId;
  final String userId;
  final String? mediaId;
  final String? mediaUrl;
  final String mediaType; // "image", "video", "poll"
  final DateTime timestamp;
  final DateTime expiresAt; // 24 hours from creation
  final Map<String, List<String>> reactions; // emoji -> [userId1, userId2, ...]
  final List<MomentComment> comments;
  final Map<String, dynamic>? pollData; // For poll-type moments
  final Map<String, dynamic>? metadata;

  MomentModel({
    required this.id,
    required this.communityId,
    required this.userId,
    this.mediaId,
    this.mediaUrl,
    required this.mediaType,
    required this.timestamp,
    required this.expiresAt,
    required this.reactions,
    required this.comments,
    this.pollData,
    this.metadata,
  });

  factory MomentModel.fromMap(Map<String, dynamic> map, String id) {
    return MomentModel(
      id: id,
      communityId: map['communityId'] ?? '',
      userId: map['userId'] ?? '',
      mediaId: map['mediaId'],
      mediaUrl: map['mediaUrl'],
      mediaType: map['mediaType'] ?? 'image',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      expiresAt: (map['expiresAt'] as Timestamp).toDate(),
      reactions: (map['reactions'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, List<String>.from(value)),
          ) ?? {},
      comments: (map['comments'] as List<dynamic>?)?.map(
            (comment) => MomentComment.fromMap(comment),
          ).toList() ?? [],
      pollData: map['pollData'],
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'communityId': communityId,
      'userId': userId,
      'mediaId': mediaId,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'timestamp': timestamp,
      'expiresAt': expiresAt,
      'reactions': reactions,
      'comments': comments.map((comment) => comment.toMap()).toList(),
      'pollData': pollData,
      'metadata': metadata,
    };
  }

  MomentModel copyWith({
    String? id,
    String? communityId,
    String? userId,
    String? mediaId,
    String? mediaUrl,
    String? mediaType,
    DateTime? timestamp,
    DateTime? expiresAt,
    Map<String, List<String>>? reactions,
    List<MomentComment>? comments,
    Map<String, dynamic>? pollData,
    Map<String, dynamic>? metadata,
  }) {
    return MomentModel(
      id: id ?? this.id,
      communityId: communityId ?? this.communityId,
      userId: userId ?? this.userId,
      mediaId: mediaId ?? this.mediaId,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      timestamp: timestamp ?? this.timestamp,
      expiresAt: expiresAt ?? this.expiresAt,
      reactions: reactions ?? this.reactions,
      comments: comments ?? this.comments,
      pollData: pollData ?? this.pollData,
      metadata: metadata ?? this.metadata,
    );
  }

  // Helper methods
  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isActive => !isExpired;
  bool get isPoll => mediaType == 'poll';
  bool get hasMedia => mediaUrl != null;
  bool get hasReactions => reactions.isNotEmpty;
  bool get hasComments => comments.isNotEmpty;
  int get reactionCount => reactions.values.fold(0, (sum, users) => sum + users.length);
  int get commentCount => comments.length;
  Duration get timeUntilExpiry => expiresAt.difference(DateTime.now());

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

  // Comment helpers
  void addComment(MomentComment comment) {
    comments.add(comment);
  }

  @override
  String toString() {
    return 'MomentModel(id: $id, mediaType: $mediaType, userId: $userId, expiresAt: $expiresAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MomentModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class MomentComment {
  final String id;
  final String userId;
  final String text;
  final DateTime timestamp;

  MomentComment({
    required this.id,
    required this.userId,
    required this.text,
    required this.timestamp,
  });

  factory MomentComment.fromMap(Map<String, dynamic> map) {
    return MomentComment(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      text: map['text'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'text': text,
      'timestamp': timestamp,
    };
  }

  @override
  String toString() {
    return 'MomentComment(id: $id, text: $text, userId: $userId)';
  }
} 