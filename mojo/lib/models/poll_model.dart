import 'package:cloud_firestore/cloud_firestore.dart';

class PollModel {
  final String id;
  final String communityId;
  final String question;
  final List<PollOption> options;
  final String creatorUid;
  final DateTime createdAt;
  final DateTime? expiresAt; // Optional expiration
  final Map<String, String> votes; // userId -> optionId
  final bool isActive;
  final Map<String, dynamic>? metadata;

  PollModel({
    required this.id,
    required this.communityId,
    required this.question,
    required this.options,
    required this.creatorUid,
    required this.createdAt,
    this.expiresAt,
    required this.votes,
    required this.isActive,
    this.metadata,
  });

  factory PollModel.fromMap(Map<String, dynamic> map, String id) {
    // Helper function to safely convert dynamic to String
    String safeString(dynamic value) {
      if (value == null) return '';
      if (value is String) return value;
      return value.toString();
    }

    // Helper function to safely convert dynamic to List<PollOption>
    List<PollOption> safeOptionList(dynamic value) {
      if (value == null) return [];
      if (value is List) {
        return value.map((item) => PollOption.fromMap(item)).toList();
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

    return PollModel(
      id: id,
      communityId: safeString(map['communityId']),
      question: safeString(map['question']),
      options: safeOptionList(map['options']),
      creatorUid: safeString(map['creatorUid']),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: map['expiresAt'] != null 
          ? (map['expiresAt'] as Timestamp?)?.toDate() 
          : null,
      votes: safeStringMap(map['votes']),
      isActive: map['isActive'] == true,
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'communityId': communityId,
      'question': question,
      'options': options.map((option) => option.toMap()).toList(),
      'creatorUid': creatorUid,
      'createdAt': createdAt,
      'expiresAt': expiresAt,
      'votes': votes,
      'isActive': isActive,
      'metadata': metadata,
    };
  }

  PollModel copyWith({
    String? id,
    String? communityId,
    String? question,
    List<PollOption>? options,
    String? creatorUid,
    DateTime? createdAt,
    DateTime? expiresAt,
    Map<String, String>? votes,
    bool? isActive,
    Map<String, dynamic>? metadata,
  }) {
    return PollModel(
      id: id ?? this.id,
      communityId: communityId ?? this.communityId,
      question: question ?? this.question,
      options: options ?? this.options,
      creatorUid: creatorUid ?? this.creatorUid,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      votes: votes ?? this.votes,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
    );
  }

  // Helper methods
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get isActiveAndNotExpired => isActive && !isExpired;
  bool isCreator(String userId) => creatorUid == userId;
  bool hasVoted(String userId) => votes.containsKey(userId);
  String? userVote(String userId) => votes[userId];
  int get totalVotes => votes.length;

  // Vote helpers
  void addVote(String userId, String optionId) {
    votes[userId] = optionId;
  }

  void removeVote(String userId) {
    votes.remove(userId);
  }

  void changeVote(String userId, String optionId) {
    votes[userId] = optionId;
  }

  // Option helpers
  PollOption? getOption(String optionId) {
    try {
      return options.firstWhere((option) => option.id == optionId);
    } catch (e) {
      return null;
    }
  }

  int getOptionVoteCount(String optionId) {
    return votes.values.where((vote) => vote == optionId).length;
  }

  double getOptionPercentage(String optionId) {
    if (totalVotes == 0) return 0.0;
    return (getOptionVoteCount(optionId) / totalVotes) * 100;
  }

  List<PollOption> get sortedOptions {
    final sorted = List<PollOption>.from(options);
    sorted.sort((a, b) => getOptionVoteCount(b.id).compareTo(getOptionVoteCount(a.id)));
    return sorted;
  }

  @override
  String toString() {
    return 'PollModel(id: $id, question: $question, communityId: $communityId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PollModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class PollOption {
  final String id;
  final String text;
  final String? imageUrl;

  PollOption({
    required this.id,
    required this.text,
    this.imageUrl,
  });

  factory PollOption.fromMap(Map<String, dynamic> map) {
    // Helper function to safely convert dynamic to String
    String safeString(dynamic value) {
      if (value == null) return '';
      if (value is String) return value;
      return value.toString();
    }

    return PollOption(
      id: safeString(map['id']),
      text: safeString(map['text']),
      imageUrl: map['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'imageUrl': imageUrl,
    };
  }

  @override
  String toString() {
    return 'PollOption(id: $id, text: $text)';
  }
} 