import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String communityId;
  final String title;
  final String description;
  final DateTime date;
  final String location;
  final String creatorUid;
  final String? posterUrl;
  final String visibility; // "public", "private"
  final bool approvalRequired;
  final DateTime createdAt;
  final Map<String, String> rsvps; // userId -> status
  final Map<String, DateTime> checkIns; // userId -> timestamp
  final Map<String, dynamic>? metadata;

  EventModel({
    required this.id,
    required this.communityId,
    required this.title,
    required this.description,
    required this.date,
    required this.location,
    required this.creatorUid,
    this.posterUrl,
    required this.visibility,
    required this.approvalRequired,
    required this.createdAt,
    required this.rsvps,
    required this.checkIns,
    this.metadata,
  });

  factory EventModel.fromMap(Map<String, dynamic> map, String id) {
    return EventModel(
      id: id,
      communityId: map['communityId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      location: map['location'] ?? '',
      creatorUid: map['creatorUid'] ?? '',
      posterUrl: map['posterUrl'],
      visibility: map['visibility'] ?? 'public',
      approvalRequired: map['approvalRequired'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      rsvps: Map<String, String>.from(map['rsvps'] ?? {}),
      checkIns: (map['checkIns'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, (value as Timestamp).toDate()),
          ) ?? {},
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'communityId': communityId,
      'title': title,
      'description': description,
      'date': date,
      'location': location,
      'creatorUid': creatorUid,
      'posterUrl': posterUrl,
      'visibility': visibility,
      'approvalRequired': approvalRequired,
      'createdAt': createdAt,
      'rsvps': rsvps,
      'checkIns': checkIns.map((key, value) => MapEntry(key, value)),
      'metadata': metadata,
    };
  }

  EventModel copyWith({
    String? id,
    String? communityId,
    String? title,
    String? description,
    DateTime? date,
    String? location,
    String? creatorUid,
    String? posterUrl,
    String? visibility,
    bool? approvalRequired,
    DateTime? createdAt,
    Map<String, String>? rsvps,
    Map<String, DateTime>? checkIns,
    Map<String, dynamic>? metadata,
  }) {
    return EventModel(
      id: id ?? this.id,
      communityId: communityId ?? this.communityId,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      location: location ?? this.location,
      creatorUid: creatorUid ?? this.creatorUid,
      posterUrl: posterUrl ?? this.posterUrl,
      visibility: visibility ?? this.visibility,
      approvalRequired: approvalRequired ?? this.approvalRequired,
      createdAt: createdAt ?? this.createdAt,
      rsvps: rsvps ?? this.rsvps,
      checkIns: checkIns ?? this.checkIns,
      metadata: metadata ?? this.metadata,
    );
  }

  // Helper methods
  bool get isPublic => visibility == 'public';
  bool get isPrivate => visibility == 'private';
  bool isCreator(String userId) => creatorUid == userId;
  bool isRsvped(String userId) => rsvps.containsKey(userId);
  bool isCheckedIn(String userId) => checkIns.containsKey(userId);
  String? rsvpStatus(String userId) => rsvps[userId];
  int get rsvpCount => rsvps.length;
  int get checkInCount => checkIns.length;
  bool get isPast => date.isBefore(DateTime.now());
  bool get isUpcoming => date.isAfter(DateTime.now());

  @override
  String toString() {
    return 'EventModel(id: $id, title: $title, communityId: $communityId, date: $date)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 