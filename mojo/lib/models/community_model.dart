import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityModel {
  final String id;
  final String name;
  final String description;
  final String? coverImage;
  final String adminUid;
  final String visibility; // "public", "private_open", "private_invite"
  final bool approvalRequired;
  final bool isBusiness;
  final List<String> members;
  final List<String> bannedUsers;
  final List<String> pinnedItems;
  final DateTime createdAt;
  final Map<String, dynamic>? theme;
  final Map<String, dynamic>? metadata;

  CommunityModel({
    required this.id,
    required this.name,
    required this.description,
    this.coverImage,
    required this.adminUid,
    required this.visibility,
    required this.approvalRequired,
    required this.isBusiness,
    required this.members,
    required this.bannedUsers,
    required this.pinnedItems,
    required this.createdAt,
    this.theme,
    this.metadata,
  });

  factory CommunityModel.fromMap(Map<String, dynamic> map, String id) {
    return CommunityModel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      coverImage: map['coverImage'],
      adminUid: map['adminUid'] ?? '',
      visibility: map['visibility'] ?? 'public',
      approvalRequired: map['approvalRequired'] ?? false,
      isBusiness: map['isBusiness'] ?? false,
      members: List<String>.from(map['members'] ?? []),
      bannedUsers: List<String>.from(map['bannedUsers'] ?? []),
      pinnedItems: List<String>.from(map['pinnedItems'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      theme: map['theme'],
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'coverImage': coverImage,
      'adminUid': adminUid,
      'visibility': visibility,
      'approvalRequired': approvalRequired,
      'isBusiness': isBusiness,
      'members': members,
      'bannedUsers': bannedUsers,
      'pinnedItems': pinnedItems,
      'createdAt': createdAt,
      'theme': theme,
      'metadata': metadata,
    };
  }

  CommunityModel copyWith({
    String? id,
    String? name,
    String? description,
    String? coverImage,
    String? adminUid,
    String? visibility,
    bool? approvalRequired,
    bool? isBusiness,
    List<String>? members,
    List<String>? bannedUsers,
    List<String>? pinnedItems,
    DateTime? createdAt,
    Map<String, dynamic>? theme,
    Map<String, dynamic>? metadata,
  }) {
    return CommunityModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      coverImage: coverImage ?? this.coverImage,
      adminUid: adminUid ?? this.adminUid,
      visibility: visibility ?? this.visibility,
      approvalRequired: approvalRequired ?? this.approvalRequired,
      isBusiness: isBusiness ?? this.isBusiness,
      members: members ?? this.members,
      bannedUsers: bannedUsers ?? this.bannedUsers,
      pinnedItems: pinnedItems ?? this.pinnedItems,
      createdAt: createdAt ?? this.createdAt,
      theme: theme ?? this.theme,
      metadata: metadata ?? this.metadata,
    );
  }

  // Helper methods
  bool get isPublic => visibility == 'public';
  bool get isPrivateOpen => visibility == 'private_open';
  bool get isPrivateInvite => visibility == 'private_invite';
  bool get isMember(String userId) => members.contains(userId);
  bool get isBanned(String userId) => bannedUsers.contains(userId);
  bool get isAdmin(String userId) => adminUid == userId;

  @override
  String toString() {
    return 'CommunityModel(id: $id, name: $name, adminUid: $adminUid, visibility: $visibility)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CommunityModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 