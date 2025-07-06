import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String phoneNumber;
  final String? displayName;
  final String? email;
  final String? profilePictureUrl;
  final DateTime createdAt;
  final DateTime lastSeen;
  final bool isOnline;
  final List<String> communityIds;
  final Map<String, dynamic>? preferences;

  UserModel({
    required this.id,
    required this.phoneNumber,
    this.displayName,
    this.email,
    this.profilePictureUrl,
    required this.createdAt,
    required this.lastSeen,
    this.isOnline = false,
    this.communityIds = const [],
    this.preferences,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      displayName: map['displayName'],
      email: map['email'],
      profilePictureUrl: map['profilePictureUrl'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastSeen: (map['lastSeen'] as Timestamp).toDate(),
      isOnline: map['isOnline'] ?? false,
      communityIds: List<String>.from(map['communityIds'] ?? []),
      preferences: map['preferences'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'phoneNumber': phoneNumber,
      'displayName': displayName,
      'email': email,
      'profilePictureUrl': profilePictureUrl,
      'createdAt': createdAt,
      'lastSeen': lastSeen,
      'isOnline': isOnline,
      'communityIds': communityIds,
      'preferences': preferences,
    };
  }

  UserModel copyWith({
    String? id,
    String? phoneNumber,
    String? displayName,
    String? email,
    String? profilePictureUrl,
    DateTime? createdAt,
    DateTime? lastSeen,
    bool? isOnline,
    List<String>? communityIds,
    Map<String, dynamic>? preferences,
  }) {
    return UserModel(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      createdAt: createdAt ?? this.createdAt,
      lastSeen: lastSeen ?? this.lastSeen,
      isOnline: isOnline ?? this.isOnline,
      communityIds: communityIds ?? this.communityIds,
      preferences: preferences ?? this.preferences,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, phoneNumber: $phoneNumber, displayName: $displayName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 