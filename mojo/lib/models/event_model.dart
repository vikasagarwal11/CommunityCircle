import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String communityId;
  final String title;
  final String description;
  final DateTime date;
  final DateTime? endDate;
  final String location;
  final String creatorUid;
  final String? posterUrl;
  final String visibility; // "public", "private"
  final bool approvalRequired;
  final int? maxSpots; // Maximum number of attendees allowed
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
    this.endDate,
    required this.location,
    required this.creatorUid,
    this.posterUrl,
    required this.visibility,
    required this.approvalRequired,
    this.maxSpots,
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
      endDate: map['endDate'] != null ? (map['endDate'] as Timestamp).toDate() : null,
      location: map['location'] ?? '',
      creatorUid: map['creatorUid'] ?? '',
      posterUrl: map['posterUrl'],
      visibility: map['visibility'] ?? 'public',
      approvalRequired: map['approvalRequired'] ?? false,
      maxSpots: map['maxSpots'],
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
      'endDate': endDate,
      'location': location,
      'creatorUid': creatorUid,
      'posterUrl': posterUrl,
      'visibility': visibility,
      'approvalRequired': approvalRequired,
      'maxSpots': maxSpots,
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
    DateTime? endDate,
    String? location,
    String? creatorUid,
    String? posterUrl,
    String? visibility,
    bool? approvalRequired,
    int? maxSpots,
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
      endDate: endDate ?? this.endDate,
      location: location ?? this.location,
      creatorUid: creatorUid ?? this.creatorUid,
      posterUrl: posterUrl ?? this.posterUrl,
      visibility: visibility ?? this.visibility,
      approvalRequired: approvalRequired ?? this.approvalRequired,
      maxSpots: maxSpots ?? this.maxSpots,
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
  
  // Event status
  String get status {
    if (isPast) return 'completed';
    if (date.isBefore(DateTime.now().add(const Duration(hours: 1)))) return 'ongoing';
    return 'upcoming';
  }
  
  // Participants (all users who have RSVPed)
  List<String> get participants => rsvps.keys.toList();
  
  // Spots management
  bool get hasSpotsLimit => maxSpots != null;
  int get availableSpots => maxSpots != null ? maxSpots! - goingCount : 0;
  bool get hasAvailableSpots => !hasSpotsLimit || availableSpots > 0;
  String get spotsDisplayText {
    if (!hasSpotsLimit) return 'Unlimited spots';
    return '$goingCount/$maxSpots spots filled';
  }

  // RSVP Statuses
  static const String rsvpGoing = 'going';
  static const String rsvpInterested = 'interested';
  static const String rsvpNotGoing = 'not_going';
  static const String rsvpWaitlist = 'waitlist';

  // RSVP helpers
  int get goingCount => rsvps.values.where((v) => v == rsvpGoing).length;
  int get interestedCount => rsvps.values.where((v) => v == rsvpInterested).length;
  int get notGoingCount => rsvps.values.where((v) => v == rsvpNotGoing).length;
  int get waitlistCount => rsvps.values.where((v) => v == rsvpWaitlist).length;

  /// Returns userIds of users with a given RSVP status
  List<String> getUserIdsByStatus(String status) =>
      rsvps.entries.where((e) => e.value == status).map((e) => e.key).toList();

  /// Returns userIds of users on the waitlist
  List<String> get waitlistUserIds => getUserIdsByStatus(rsvpWaitlist);

  /// Returns userIds of users with confirmed spots ("going")
  List<String> get confirmedUserIds => getUserIdsByStatus(rsvpGoing);

  /// Checks if a user is on the waitlist
  bool isUserOnWaitlist(String userId) => rsvps[userId] == rsvpWaitlist;

  /// Checks if a user is confirmed ("going")
  bool isUserConfirmed(String userId) => rsvps[userId] == rsvpGoing;

  /// Returns true if the event is full (confirmed "going" >= maxSpots)
  bool get isFull => hasSpotsLimit && goingCount >= (maxSpots ?? 0);

  /// Returns the user's RSVP status, or null if not RSVPed
  String? getUserRsvpStatus(String userId) => rsvps[userId];

  /// Adds a user to the waitlist
  EventModel addToWaitlist(String userId) {
    final updatedRsvps = Map<String, String>.from(rsvps);
    updatedRsvps[userId] = rsvpWaitlist;
    return copyWith(rsvps: updatedRsvps);
  }

  /// Moves a user from waitlist to confirmed (if spot available)
  EventModel promoteFromWaitlist(String userId) {
    if (!isFull) {
      final updatedRsvps = Map<String, String>.from(rsvps);
      updatedRsvps[userId] = rsvpGoing;
      return copyWith(rsvps: updatedRsvps);
    }
    return this;
  }

  /// Removes a user from RSVP (any status)
  EventModel removeRsvp(String userId) {
    final updatedRsvps = Map<String, String>.from(rsvps);
    updatedRsvps.remove(userId);
    return copyWith(rsvps: updatedRsvps);
  }

  /// Returns the next user on the waitlist (FIFO)
  String? get nextWaitlistUser => waitlistUserIds.isNotEmpty ? waitlistUserIds.first : null;

  /// Promotes the next waitlist user to confirmed if a spot opens
  EventModel promoteNextWaitlistUser() {
    if (!isFull && nextWaitlistUser != null) {
      return promoteFromWaitlist(nextWaitlistUser!);
    }
    return this;
  }

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