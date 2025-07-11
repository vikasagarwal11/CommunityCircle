import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityModel {
  final String id;
  final String name;
  final String description;
  final String coverImage;
  final String badgeUrl; // NEW: Community icon/logo
  final String adminUid;
  final String visibility; // 'public', 'private_open', 'private_invite'
  final bool approvalRequired;
  final bool isBusiness;
  final List<String> members;
  final List<String> bannedUsers;
  final List<String> pinnedItems;
  final List<String> joinQuestions; // NEW: Custom join questions
  final List<String> rules; // NEW: Community rules/guidelines
  final String welcomeMessage; // NEW: Custom welcome message for new members
  final DateTime createdAt;
  final Map<String, String> theme;
  final Map<String, dynamic> metadata;

  const CommunityModel({
    required this.id,
    required this.name,
    required this.description,
    required this.coverImage,
    required this.badgeUrl, // NEW
    required this.adminUid,
    required this.visibility,
    required this.approvalRequired,
    required this.isBusiness,
    required this.members,
    required this.bannedUsers,
    required this.pinnedItems,
    required this.joinQuestions, // NEW
    required this.rules, // NEW
    required this.welcomeMessage, // NEW
    required this.createdAt,
    required this.theme,
    required this.metadata,
  });

  factory CommunityModel.fromMap(Map<String, dynamic> data, String id) {
    return CommunityModel(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      coverImage: data['cover_image'] ?? '',
      badgeUrl: data['badge_url'] ?? '', // NEW
      adminUid: data['admin_uid'] ?? '',
      visibility: data['visibility'] ?? 'public',
      approvalRequired: data['approval_required'] ?? false,
      isBusiness: data['is_business'] ?? false,
      members: List<String>.from(data['members'] ?? []),
      bannedUsers: List<String>.from(data['banned_users'] ?? []),
      pinnedItems: List<String>.from(data['pinned_items'] ?? []),
      joinQuestions: List<String>.from(data['join_questions'] ?? []), // NEW
      rules: List<String>.from(data['rules'] ?? []), // NEW
      welcomeMessage: data['welcome_message'] ?? '', // NEW
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      theme: Map<String, String>.from(data['theme'] ?? {}),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'cover_image': coverImage,
      'badge_url': badgeUrl, // NEW
      'admin_uid': adminUid,
      'visibility': visibility,
      'approval_required': approvalRequired,
      'is_business': isBusiness,
      'members': members,
      'banned_users': bannedUsers,
      'pinned_items': pinnedItems,
      'join_questions': joinQuestions, // NEW
      'rules': rules, // NEW
      'welcome_message': welcomeMessage, // NEW
      'created_at': Timestamp.fromDate(createdAt),
      'theme': theme,
      'metadata': metadata,
    };
  }

  CommunityModel copyWith({
    String? id,
    String? name,
    String? description,
    String? coverImage,
    String? badgeUrl, // NEW
    String? adminUid,
    String? visibility,
    bool? approvalRequired,
    bool? isBusiness,
    List<String>? members,
    List<String>? bannedUsers,
    List<String>? pinnedItems,
    List<String>? joinQuestions, // NEW
    List<String>? rules, // NEW
    String? welcomeMessage, // NEW
    DateTime? createdAt,
    Map<String, String>? theme,
    Map<String, dynamic>? metadata,
  }) {
    return CommunityModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      coverImage: coverImage ?? this.coverImage,
      badgeUrl: badgeUrl ?? this.badgeUrl, // NEW
      adminUid: adminUid ?? this.adminUid,
      visibility: visibility ?? this.visibility,
      approvalRequired: approvalRequired ?? this.approvalRequired,
      isBusiness: isBusiness ?? this.isBusiness,
      members: members ?? this.members,
      bannedUsers: bannedUsers ?? this.bannedUsers,
      pinnedItems: pinnedItems ?? this.pinnedItems,
      joinQuestions: joinQuestions ?? this.joinQuestions, // NEW
      rules: rules ?? this.rules, // NEW
      welcomeMessage: welcomeMessage ?? this.welcomeMessage, // NEW
      createdAt: createdAt ?? this.createdAt,
      theme: theme ?? this.theme,
      metadata: metadata ?? this.metadata,
    );
  }

  // Helper methods
  bool get isPublic => visibility == 'public';
  bool get isPrivate => visibility == 'private_open' || visibility == 'private_invite';
  bool get requiresInvite => visibility == 'private_invite';
  int get memberCount => members.length;
  bool get hasMembers => members.isNotEmpty;
  bool get hasPinnedItems => pinnedItems.isNotEmpty;
  bool get hasJoinQuestions => joinQuestions.isNotEmpty; // NEW
  bool get hasRules => rules.isNotEmpty; // NEW
  bool get hasWelcomeMessage => welcomeMessage.isNotEmpty; // NEW

  // Check if user is member
  bool isMember(String userId) {
    return members.contains(userId);
  }

  // Check if user is banned
  bool isBanned(String userId) {
    return bannedUsers.contains(userId);
  }

  // Check if user is admin
  bool isAdmin(String userId) {
    return adminUid == userId;
  }

  // Check if user can join
  bool canJoin(String userId) {
    return !isBanned(userId) && !isMember(userId) && !isAdmin(userId);
  }

  // Check if user can view (for private communities)
  bool canView(String userId) {
    if (isPublic) return true;
    return isMember(userId) || isAdmin(userId);
  }

  // Get theme color
  String get themeColor => theme['color'] ?? '#2196F3';
  String get bannerUrl => theme['banner_url'] ?? '';

  @override
  String toString() {
    return 'CommunityModel(id: $id, name: $name, visibility: $visibility, members: $memberCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CommunityModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 