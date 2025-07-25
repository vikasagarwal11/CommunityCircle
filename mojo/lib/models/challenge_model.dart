import 'package:cloud_firestore/cloud_firestore.dart';

class ChallengeModel {
  final String id;
  final String communityId;
  final String title;
  final String description;
  final String type; // "daily", "weekly", "monthly", "custom"
  final DateTime startDate;
  final DateTime endDate;
  final String creatorUid;
  final Map<String, ChallengeParticipant> participants;
  final List<String> rewards; // Reward descriptions
  final bool isActive;
  final Map<String, dynamic>? metadata;

  ChallengeModel({
    required this.id,
    required this.communityId,
    required this.title,
    required this.description,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.creatorUid,
    required this.participants,
    required this.rewards,
    required this.isActive,
    this.metadata,
  });

  factory ChallengeModel.fromMap(Map<String, dynamic> map, String id) {
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

    // Helper function to safely convert dynamic to Map<String, ChallengeParticipant>
    Map<String, ChallengeParticipant> safeParticipantMap(dynamic value) {
      if (value == null) return {};
      if (value is Map) {
        return Map<String, ChallengeParticipant>.fromEntries(
          value.entries.map((entry) => MapEntry(
            safeString(entry.key),
            ChallengeParticipant.fromMap(entry.value),
          )),
        );
      }
      return {};
    }

    return ChallengeModel(
      id: id,
      communityId: safeString(map['communityId']),
      title: safeString(map['title']),
      description: safeString(map['description']),
      type: safeString(map['type']),
      startDate: (map['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (map['endDate'] as Timestamp?)?.toDate() ?? DateTime.now().add(Duration(days: 7)),
      creatorUid: safeString(map['creatorUid']),
      participants: safeParticipantMap(map['participants']),
      rewards: safeStringList(map['rewards']),
      isActive: map['isActive'] == true,
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'communityId': communityId,
      'title': title,
      'description': description,
      'type': type,
      'startDate': startDate,
      'endDate': endDate,
      'creatorUid': creatorUid,
      'participants': participants.map((key, value) => MapEntry(key, value.toMap())),
      'rewards': rewards,
      'isActive': isActive,
      'metadata': metadata,
    };
  }

  ChallengeModel copyWith({
    String? id,
    String? communityId,
    String? title,
    String? description,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    String? creatorUid,
    Map<String, ChallengeParticipant>? participants,
    List<String>? rewards,
    bool? isActive,
    Map<String, dynamic>? metadata,
  }) {
    return ChallengeModel(
      id: id ?? this.id,
      communityId: communityId ?? this.communityId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      creatorUid: creatorUid ?? this.creatorUid,
      participants: participants ?? this.participants,
      rewards: rewards ?? this.rewards,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
    );
  }

  // Helper methods
  bool isCreator(String userId) => creatorUid == userId;
  bool isParticipant(String userId) => participants.containsKey(userId);
  bool get isActiveAndInDateRange => isActive && DateTime.now().isAfter(startDate) && DateTime.now().isBefore(endDate);
  bool get isUpcoming => DateTime.now().isBefore(startDate);
  bool get isPast => DateTime.now().isAfter(endDate);
  bool get isOngoing => DateTime.now().isAfter(startDate) && DateTime.now().isBefore(endDate);
  Duration get timeUntilStart => startDate.difference(DateTime.now());
  Duration get timeUntilEnd => endDate.difference(DateTime.now());
  int get participantCount => participants.length;

  // Participant helpers
  void addParticipant(String userId, ChallengeParticipant participant) {
    participants[userId] = participant;
  }

  void removeParticipant(String userId) {
    participants.remove(userId);
  }

  void updateParticipantScore(String userId, int score) {
    if (participants.containsKey(userId)) {
      participants[userId] = participants[userId]!.copyWith(score: score);
    }
  }

  ChallengeParticipant? getParticipant(String userId) {
    return participants[userId];
  }

  // Leaderboard helpers
  List<ChallengeParticipant> get leaderboard {
    final sorted = participants.values.toList();
    sorted.sort((a, b) => b.score.compareTo(a.score));
    return sorted;
  }

  List<ChallengeParticipant> get topParticipants {
    final leaderboard = this.leaderboard;
    return leaderboard.take(3).toList(); // Top 3
  }

  int getParticipantRank(String userId) {
    final leaderboard = this.leaderboard;
    for (int i = 0; i < leaderboard.length; i++) {
      if (leaderboard[i].userId == userId) {
        return i + 1;
      }
    }
    return -1; // Not found
  }

  @override
  String toString() {
    return 'ChallengeModel(id: $id, title: $title, type: $type, communityId: $communityId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChallengeModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class ChallengeParticipant {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final int score;
  final DateTime joinedAt;
  final DateTime? lastActivity;

  ChallengeParticipant({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.score,
    required this.joinedAt,
    this.lastActivity,
  });

  factory ChallengeParticipant.fromMap(Map<String, dynamic> map) {
    // Helper function to safely convert dynamic to String
    String safeString(dynamic value) {
      if (value == null) return '';
      if (value is String) return value;
      return value.toString();
    }

    return ChallengeParticipant(
      userId: safeString(map['userId']),
      displayName: safeString(map['displayName']),
      avatarUrl: map['avatarUrl'],
      score: (map['score'] as int?) ?? 0,
      joinedAt: (map['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastActivity: map['lastActivity'] != null 
          ? (map['lastActivity'] as Timestamp?)?.toDate() 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'score': score,
      'joinedAt': joinedAt,
      'lastActivity': lastActivity,
    };
  }

  ChallengeParticipant copyWith({
    String? userId,
    String? displayName,
    String? avatarUrl,
    int? score,
    DateTime? joinedAt,
    DateTime? lastActivity,
  }) {
    return ChallengeParticipant(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      score: score ?? this.score,
      joinedAt: joinedAt ?? this.joinedAt,
      lastActivity: lastActivity ?? this.lastActivity,
    );
  }

  @override
  String toString() {
    return 'ChallengeParticipant(userId: $userId, displayName: $displayName, score: $score)';
  }
} 