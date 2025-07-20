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

    // Helper function to safely convert dynamic to Map<String, List<String>>
    Map<String, List<String>> safeStringListMap(dynamic value) {
      if (value == null) return {};
      if (value is Map) {
        return Map<String, List<String>>.fromEntries(
          value.entries.map((entry) => MapEntry(
            safeString(entry.key),
            safeStringList(entry.value),
          )),
        );
      }
      return {};
    }

    // Helper function to safely convert dynamic to List<MomentComment>
    List<MomentComment> safeCommentList(dynamic value) {
      if (value == null) return [];
      if (value is List) {
        return value.map((item) => MomentComment.fromMap(item)).toList();
      }
      return [];
    }

    return MomentModel(
      id: id,
      communityId: safeString(map['communityId']),
      userId: safeString(map['userId']),
      mediaId: map['mediaId'],
      mediaUrl: map['mediaUrl'],
      mediaType: safeString(map['mediaType']),
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (map['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now().add(Duration(hours: 24)),
      reactions: safeStringListMap(map['reactions']),
      comments: safeCommentList(map['comments']),
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
    // Helper function to safely convert dynamic to String
    String safeString(dynamic value) {
      if (value == null) return '';
      if (value is String) return value;
      return value.toString();
    }

    return MomentComment(
      id: safeString(map['id']),
      userId: safeString(map['userId']),
      text: safeString(map['text']),
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
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