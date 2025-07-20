import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String phoneNumber;
  final String? displayName;
  final String? email;
  final String? profilePictureUrl;
  final String role; // "admin", "member", "anonymous", "business"
  final DateTime createdAt;
  final DateTime lastSeen;
  final bool isOnline;
  final List<String> communityIds;
  final Map<String, String> communityRoles; // communityId -> role
  final Map<String, List<String>> ruleAcknowledgments; // communityId -> [rule1, rule2, ...]
  final Map<String, List<String>> joinAnswers; // communityId -> [answer1, answer2, ...]
  final Map<String, bool> onboardingCompleted; // communityId -> completed
  final Map<String, dynamic>? preferences;
  final Map<String, dynamic>? businessProfile; // For business users
  final List<String> badges; // Achievement badges
  int totalPoints; // Gamification points
  final String? fcmToken; // FCM token for push notifications
  final DateTime? lastTokenUpdate; // When FCM token was last updated
  final Map<String, dynamic>? metadata;

  UserModel({
    required this.id,
    required this.phoneNumber,
    this.displayName,
    this.email,
    this.profilePictureUrl,
    required this.role,
    required this.createdAt,
    required this.lastSeen,
    this.isOnline = false,
    this.communityIds = const [],
    this.communityRoles = const {},
    this.ruleAcknowledgments = const {},
    this.joinAnswers = const {},
    this.onboardingCompleted = const {},
    this.preferences,
    this.businessProfile,
    this.badges = const [],
    this.totalPoints = 0,
    this.fcmToken,
    this.lastTokenUpdate,
    this.metadata,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
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

    // Helper function to safely convert dynamic to Map<String, bool>
    Map<String, bool> safeBoolMap(dynamic value) {
      if (value == null) return {};
      if (value is Map) {
        return Map<String, bool>.fromEntries(
          value.entries.map((entry) => MapEntry(
            safeString(entry.key),
            entry.value == true,
          )),
        );
      }
      return {};
    }

    return UserModel(
      id: safeString(map['id']),
      phoneNumber: safeString(map['phoneNumber']),
      displayName: map['displayName'],
      email: map['email'],
      profilePictureUrl: map['profilePictureUrl'],
      role: safeString(map['role']),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastSeen: (map['lastSeen'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isOnline: map['isOnline'] == true,
      communityIds: safeStringList(map['communityIds']),
      communityRoles: safeStringMap(map['communityRoles']),
      ruleAcknowledgments: safeStringListMap(map['ruleAcknowledgments']),
      joinAnswers: safeStringListMap(map['joinAnswers']),
      onboardingCompleted: safeBoolMap(map['onboardingCompleted']),
      preferences: map['preferences'],
      businessProfile: map['businessProfile'],
      badges: safeStringList(map['badges']),
      totalPoints: (map['totalPoints'] as int?) ?? 0,
      fcmToken: map['fcmToken'],
      lastTokenUpdate: map['lastTokenUpdate'] != null 
          ? (map['lastTokenUpdate'] as Timestamp?)?.toDate() 
          : null,
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'phoneNumber': phoneNumber,
      'displayName': displayName,
      'email': email,
      'profilePictureUrl': profilePictureUrl,
      'role': role,
      'createdAt': createdAt,
      'lastSeen': lastSeen,
      'isOnline': isOnline,
      'communityIds': communityIds,
      'communityRoles': communityRoles,
      'ruleAcknowledgments': ruleAcknowledgments,
      'joinAnswers': joinAnswers,
      'onboardingCompleted': onboardingCompleted,
      'preferences': preferences,
      'businessProfile': businessProfile,
      'badges': badges,
      'totalPoints': totalPoints,
      'fcmToken': fcmToken,
      'lastTokenUpdate': lastTokenUpdate,
      'metadata': metadata,
    };
  }

  UserModel copyWith({
    String? id,
    String? phoneNumber,
    String? displayName,
    String? email,
    String? profilePictureUrl,
    String? role,
    DateTime? createdAt,
    DateTime? lastSeen,
    bool? isOnline,
    List<String>? communityIds,
    Map<String, String>? communityRoles,
    Map<String, List<String>>? ruleAcknowledgments,
    Map<String, List<String>>? joinAnswers,
    Map<String, bool>? onboardingCompleted,
    Map<String, dynamic>? preferences,
    Map<String, dynamic>? businessProfile,
    List<String>? badges,
    int? totalPoints,
    String? fcmToken,
    DateTime? lastTokenUpdate,
    Map<String, dynamic>? metadata,
  }) {
    return UserModel(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      lastSeen: lastSeen ?? this.lastSeen,
      isOnline: isOnline ?? this.isOnline,
      communityIds: communityIds ?? this.communityIds,
      communityRoles: communityRoles ?? this.communityRoles,
      ruleAcknowledgments: ruleAcknowledgments ?? this.ruleAcknowledgments,
      joinAnswers: joinAnswers ?? this.joinAnswers,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      preferences: preferences ?? this.preferences,
      businessProfile: businessProfile ?? this.businessProfile,
      badges: badges ?? this.badges,
      totalPoints: totalPoints ?? this.totalPoints,
      fcmToken: fcmToken ?? this.fcmToken,
      lastTokenUpdate: lastTokenUpdate ?? this.lastTokenUpdate,
      metadata: metadata ?? this.metadata,
    );
  }

  // Helper methods
  bool get isAdmin => role == 'admin';
  bool get isBusiness => role == 'business';
  bool get isAnonymous => role == 'anonymous';
  bool get isMember => role == 'member';
  bool get hasBusinessProfile => businessProfile != null;
  bool get hasBadges => badges.isNotEmpty;
  bool isInCommunity(String communityId) => communityIds.contains(communityId);
  String? getCommunityRole(String communityId) => communityRoles[communityId];

  // Role helpers
  bool isCommunityAdmin(String communityId) {
    return communityRoles[communityId] == 'admin';
  }

  bool isCommunityModerator(String communityId) {
    return communityRoles[communityId] == 'moderator';
  }

  bool isCommunityMember(String communityId) {
    return communityRoles[communityId] == 'member';
  }

  // NEW: Rule acknowledgment helpers
  bool hasAcknowledgedRules(String communityId) {
    return ruleAcknowledgments.containsKey(communityId) && 
           ruleAcknowledgments[communityId]!.isNotEmpty;
  }

  List<String> getAcknowledgedRules(String communityId) {
    return ruleAcknowledgments[communityId] ?? [];
  }

  void acknowledgeRule(String communityId, String rule) {
    if (!ruleAcknowledgments.containsKey(communityId)) {
      ruleAcknowledgments[communityId] = [];
    }
    if (!ruleAcknowledgments[communityId]!.contains(rule)) {
      ruleAcknowledgments[communityId]!.add(rule);
    }
  }

  // NEW: Join answers helpers
  bool hasAnsweredJoinQuestions(String communityId) {
    return joinAnswers.containsKey(communityId) && 
           joinAnswers[communityId]!.isNotEmpty;
  }

  List<String> getJoinAnswers(String communityId) {
    return joinAnswers[communityId] ?? [];
  }

  void setJoinAnswers(String communityId, List<String> answers) {
    joinAnswers[communityId] = answers;
  }

  // NEW: Onboarding helpers
  bool hasCompletedOnboarding(String communityId) {
    return onboardingCompleted[communityId] ?? false;
  }

  void completeOnboarding(String communityId) {
    onboardingCompleted[communityId] = true;
  }

  // Badge helpers
  void addBadge(String badge) {
    if (!badges.contains(badge)) {
      badges.add(badge);
    }
  }

  // Add points to user
  void addPoints(int points) {
    // This will be handled by the service layer
    // totalPoints += points;
  }

  @override
  String toString() {
    return 'UserModel(id: $id, phoneNumber: $phoneNumber, displayName: $displayName, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 