import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
  final String? category; // Event category: "meeting", "workshop", "social", "webinar", "hackathon"

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
    this.category,
  });

  factory EventModel.fromMap(Map<String, dynamic> map, String id) {
    // Helper function to safely convert dynamic to String
    String safeString(dynamic value) {
      if (value == null) return '';
      if (value is String) return value;
      return value.toString();
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

    // Helper function to safely convert dynamic to Map<String, DateTime>
    Map<String, DateTime> safeDateTimeMap(dynamic value) {
      if (value == null) return {};
      if (value is Map) {
        return Map<String, DateTime>.fromEntries(
          value.entries.map((entry) => MapEntry(
            safeString(entry.key),
            (entry.value as Timestamp?)?.toDate() ?? DateTime.now(),
          )),
        );
      }
      return {};
    }

    return EventModel(
      id: id,
      communityId: safeString(map['communityId']),
      title: safeString(map['title']),
      description: safeString(map['description']),
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: map['endDate'] != null ? (map['endDate'] as Timestamp?)?.toDate() : null,
      location: safeString(map['location']),
      creatorUid: safeString(map['creatorUid']),
      posterUrl: map['posterUrl'],
      visibility: safeString(map['visibility']),
      approvalRequired: map['approvalRequired'] == true,
      maxSpots: map['maxSpots'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      rsvps: safeStringMap(map['rsvps']),
      checkIns: safeDateTimeMap(map['checkIns']),
      metadata: map['metadata'],
      category: map['category'],
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
      'category': category,
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
    String? category,
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
      category: category ?? this.category,
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

  // Event Categories
  static const String categoryMeeting = 'meeting';
  static const String categoryWorkshop = 'workshop';
  static const String categorySocial = 'social';
  static const String categoryWebinar = 'webinar';
  static const String categoryHackathon = 'hackathon';

  // Category helper methods
  static List<String> get availableCategories => [
    categoryMeeting,
    categoryWorkshop,
    categorySocial,
    categoryWebinar,
    categoryHackathon,
  ];

  static String getCategoryDisplayName(String category) {
    switch (category) {
      case categoryMeeting:
        return 'Meeting';
      case categoryWorkshop:
        return 'Workshop';
      case categorySocial:
        return 'Social';
      case categoryWebinar:
        return 'Webinar';
      case categoryHackathon:
        return 'Hackathon';
      default:
        return 'Other';
    }
  }

  static IconData getCategoryIcon(String category) {
    switch (category) {
      case categoryMeeting:
        return Icons.meeting_room_rounded;
      case categoryWorkshop:
        return Icons.workspace_premium_rounded;
      case categorySocial:
        return Icons.people_rounded;
      case categoryWebinar:
        return Icons.video_call_rounded;
      case categoryHackathon:
        return Icons.code_rounded;
      default:
        return Icons.event_rounded;
    }
  }

  static Color getCategoryColor(String category) {
    switch (category) {
      case categoryMeeting:
        return Colors.blue;
      case categoryWorkshop:
        return Colors.green;
      case categorySocial:
        return Colors.orange;
      case categoryWebinar:
        return Colors.purple;
      case categoryHackathon:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Instance methods for category
  String get categoryDisplayName => category != null 
      ? getCategoryDisplayName(category!) 
      : 'Other';
  
  IconData get categoryIcon => category != null 
      ? getCategoryIcon(category!) 
      : Icons.event_rounded;
  
  Color get categoryColor => category != null 
      ? getCategoryColor(category!) 
      : Colors.grey;

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