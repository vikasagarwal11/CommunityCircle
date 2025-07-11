import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import '../models/community_model.dart';
import '../models/user_model.dart';
import '../core/constants.dart';

class CommunityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger();

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Create a new community
  Future<CommunityModel?> createCommunity({
    required String name,
    required String description,
    String? coverImage,
    required String visibility,
    bool approvalRequired = false,
    bool isBusiness = false,
    Map<String, String>? theme,
  }) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        _logger.e('User not authenticated');
        throw Exception('User not authenticated');
      }

      _logger.i('Creating community: $name');

      final communityData = {
        'name': name,
        'description': description,
        'cover_image': coverImage ?? '',
        'admin_uid': userId,
        'visibility': visibility,
        'approval_required': approvalRequired,
        'is_business': isBusiness,
        'members': [userId], // Admin is automatically a member
        'banned_users': [],
        'pinned_items': [],
        'created_at': Timestamp.now(),
        'theme': theme ?? {'color': '#2196F3', 'banner_url': ''},
        'metadata': {
          'member_count': 1,
          'event_count': 0,
          'moment_count': 0,
          'last_activity': Timestamp.now(),
        },
      };

      final docRef = await _firestore
          .collection(AppConstants.communitiesCollection)
          .add(communityData);

      _logger.i('Community created successfully: ${docRef.id}');

      // Update user's owned communities
      await _updateUserOwnedCommunities(userId, docRef.id, true);

      return CommunityModel.fromMap(communityData, docRef.id);
    } catch (e) {
      _logger.e('Error creating community: $e');
      throw Exception('Failed to create community: $e');
    }
  }

  // Get community by ID with real-time updates
  Stream<CommunityModel?> getCommunityStream(String communityId) {
    return _firestore
        .collection(AppConstants.communitiesCollection)
        .doc(communityId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return CommunityModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    });
  }

  // Get community by ID (single fetch)
  Future<CommunityModel?> getCommunity(String communityId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.communitiesCollection)
          .doc(communityId)
          .get();

      if (doc.exists) {
        return CommunityModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      _logger.e('Error getting community: $e');
      throw Exception('Failed to get community: $e');
    }
  }

  // Get public communities with pagination
  Stream<List<CommunityModel>> getPublicCommunities({
    int limit = 10,
    DocumentSnapshot? lastDocument,
  }) {
    Query query = _firestore
        .collection(AppConstants.communitiesCollection)
        .where('visibility', isEqualTo: 'public')
        .orderBy('created_at', descending: true)
        .limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    // Defensive: always emit an empty list if no docs
    return query.snapshots().map((snapshot) {
      _logger.i('getPublicCommunities: snapshot docs count = ${snapshot.docs.length}');
      if (snapshot.docs.isEmpty) return <CommunityModel>[];
      return snapshot.docs.map((doc) {
        return CommunityModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // Get user's communities (joined and owned)
  Stream<List<CommunityModel>> getUserCommunities(String userId) {
    return _firestore
        .collection(AppConstants.communitiesCollection)
        .where('members', arrayContains: userId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return CommunityModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Get communities owned by user
  Stream<List<CommunityModel>> getOwnedCommunities(String userId) {
    return _firestore
        .collection(AppConstants.communitiesCollection)
        .where('admin_uid', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return CommunityModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Search communities
  Stream<List<CommunityModel>> searchCommunities({
    required String query,
    String? category,
    bool? isBusiness,
    int limit = 20,
  }) {
    Query searchQuery = _firestore
        .collection(AppConstants.communitiesCollection)
        .where('visibility', isEqualTo: 'public');

    // Add business filter if specified
    if (isBusiness != null) {
      searchQuery = searchQuery.where('is_business', isEqualTo: isBusiness);
    }

    // Add category filter if needed
    // ... (your category filter logic here)

    return searchQuery.snapshots().map((snapshot) {
      final communities = snapshot.docs.map((doc) {
        return CommunityModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      // Filter by search query
      final filtered = communities.where((community) {
        final searchLower = query.toLowerCase();
        return community.name.toLowerCase().contains(searchLower) ||
               community.description.toLowerCase().contains(searchLower);
      }).take(limit).toList();

      // Always emit a list, even if empty
      return filtered;
    });
  }

  // Join community
  Future<void> joinCommunity(String communityId) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      _logger.i('Joining community: $communityId');

      final community = await getCommunity(communityId);
      if (community == null) {
        throw Exception('Community not found');
      }

      if (community.isBanned(userId)) {
        throw Exception('You are banned from this community');
      }

      if (community.isMember(userId)) {
        throw Exception('Already a member of this community');
      }

      if (community.requiresInvite) {
        // Create join request
        await _createJoinRequest(communityId, userId);
        _logger.i('Join request created for community: $communityId');
      } else {
        // Direct join
        await _firestore
            .collection(AppConstants.communitiesCollection)
            .doc(communityId)
            .update({
          'members': FieldValue.arrayUnion([userId]),
          'metadata.member_count': FieldValue.increment(1),
        });

        // Update user's joined communities
        await _updateUserJoinedCommunities(userId, communityId, true);

        _logger.i('Successfully joined community: $communityId');
      }
    } catch (e) {
      _logger.e('Error joining community: $e');
      throw Exception('Failed to join community: $e');
    }
  }

  // Leave community
  Future<void> leaveCommunity(String communityId) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      _logger.i('Leaving community: $communityId');

      final community = await getCommunity(communityId);
      if (community == null) {
        throw Exception('Community not found');
      }

      if (community.isAdmin(userId)) {
        throw Exception('Admin cannot leave community. Transfer ownership first.');
      }

      if (!community.isMember(userId)) {
        throw Exception('Not a member of this community');
      }

      await _firestore
          .collection(AppConstants.communitiesCollection)
          .doc(communityId)
          .update({
        'members': FieldValue.arrayRemove([userId]),
        'metadata.member_count': FieldValue.increment(-1),
      });

      // Update user's joined communities
      await _updateUserJoinedCommunities(userId, communityId, false);

      _logger.i('Successfully left community: $communityId');
    } catch (e) {
      _logger.e('Error leaving community: $e');
      throw Exception('Failed to leave community: $e');
    }
  }

  // Update community
  Future<void> updateCommunity({
    required String communityId,
    String? name,
    String? description,
    String? coverImage,
    String? visibility,
    bool? approvalRequired,
    Map<String, String>? theme,
  }) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      _logger.i('Updating community: $communityId');

      final community = await getCommunity(communityId);
      if (community == null) {
        throw Exception('Community not found');
      }

      if (!community.isAdmin(userId)) {
        throw Exception('Only admin can update community');
      }

      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      if (coverImage != null) updates['cover_image'] = coverImage;
      if (visibility != null) updates['visibility'] = visibility;
      if (approvalRequired != null) updates['approval_required'] = approvalRequired;
      if (theme != null) updates['theme'] = theme;

      await _firestore
          .collection(AppConstants.communitiesCollection)
          .doc(communityId)
          .update(updates);

      _logger.i('Community updated successfully: $communityId');
    } catch (e) {
      _logger.e('Error updating community: $e');
      throw Exception('Failed to update community: $e');
    }
  }

  // Delete community
  Future<void> deleteCommunity(String communityId) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      _logger.i('Deleting community: $communityId');

      final community = await getCommunity(communityId);
      if (community == null) {
        throw Exception('Community not found');
      }

      if (!community.isAdmin(userId)) {
        throw Exception('Only admin can delete community');
      }

      // Delete all subcollections first
      await _deleteCommunitySubcollections(communityId);

      // Delete the community document
      await _firestore
          .collection(AppConstants.communitiesCollection)
          .doc(communityId)
          .delete();

      // Update user's owned communities
      await _updateUserOwnedCommunities(userId, communityId, false);

      _logger.i('Community deleted successfully: $communityId');
    } catch (e) {
      _logger.e('Error deleting community: $e');
      throw Exception('Failed to delete community: $e');
    }
  }

  // Ban user from community
  Future<void> banUser(String communityId, String userId) async {
    try {
      final adminId = currentUserId;
      if (adminId == null) {
        throw Exception('User not authenticated');
      }

      _logger.i('Banning user $userId from community: $communityId');

      final community = await getCommunity(communityId);
      if (community == null) {
        throw Exception('Community not found');
      }

      if (!community.isAdmin(adminId)) {
        throw Exception('Only admin can ban users');
      }

      await _firestore
          .collection(AppConstants.communitiesCollection)
          .doc(communityId)
          .update({
        'banned_users': FieldValue.arrayUnion([userId]),
        'members': FieldValue.arrayRemove([userId]),
        'metadata.member_count': FieldValue.increment(-1),
      });

      _logger.i('User banned successfully: $userId');
    } catch (e) {
      _logger.e('Error banning user: $e');
      throw Exception('Failed to ban user: $e');
    }
  }

  // Unban user from community
  Future<void> unbanUser(String communityId, String userId) async {
    try {
      final adminId = currentUserId;
      if (adminId == null) {
        throw Exception('User not authenticated');
      }

      _logger.i('Unbanning user $userId from community: $communityId');

      final community = await getCommunity(communityId);
      if (community == null) {
        throw Exception('Community not found');
      }

      if (!community.isAdmin(adminId)) {
        throw Exception('Only admin can unban users');
      }

      await _firestore
          .collection(AppConstants.communitiesCollection)
          .doc(communityId)
          .update({
        'banned_users': FieldValue.arrayRemove([userId]),
      });

      _logger.i('User unbanned successfully: $userId');
    } catch (e) {
      _logger.e('Error unbanning user: $e');
      throw Exception('Failed to unban user: $e');
    }
  }

  // Get community statistics
  Future<Map<String, dynamic>> getCommunityStats(String communityId) async {
    try {
      final community = await getCommunity(communityId);
      if (community == null) {
        throw Exception('Community not found');
      }

      // Get member count
      final memberCount = community.memberCount;

      // Get recent activity (last 7 days)
      final sevenDaysAgo = Timestamp.fromDate(
        DateTime.now().subtract(const Duration(days: 7)),
      );

      // Get recent messages count
      final messagesQuery = await _firestore
          .collection(AppConstants.messagesCollection)
          .where('community_id', isEqualTo: communityId)
          .where('timestamp', isGreaterThan: sevenDaysAgo)
          .count()
          .get();

      // Get recent events count
      final eventsQuery = await _firestore
          .collection(AppConstants.eventsCollection)
          .where('community_id', isEqualTo: communityId)
          .where('created_at', isGreaterThan: sevenDaysAgo)
          .count()
          .get();

      return {
        'member_count': memberCount,
        'recent_messages': messagesQuery.count,
        'recent_events': eventsQuery.count,
        'created_at': community.createdAt,
        'is_business': community.isBusiness,
        'visibility': community.visibility,
        'active_members': memberCount,
        'avg_session_minutes': 15,
        'total_revenue': 0,
        'monthly_revenue': 0,
      };
    } catch (e) {
      _logger.e('Error getting community stats: $e');
      throw Exception('Failed to get community stats: $e');
    }
  }

  // Get community members stream
  Stream<List<UserModel>> getCommunityMembersStream(String communityId) {
    return _firestore
        .collection(AppConstants.communitiesCollection)
        .doc(communityId)
        .snapshots()
        .asyncMap((doc) async {
      if (!doc.exists) return [];
      
      final data = doc.data()!;
      final memberIds = List<String>.from(data['members'] ?? []);
      
      if (memberIds.isEmpty) return [];
      
      final members = <UserModel>[];
      for (final memberId in memberIds) {
        try {
          final userDoc = await _firestore
              .collection(AppConstants.usersCollection)
              .doc(memberId)
              .get();
          
          if (userDoc.exists) {
            members.add(UserModel.fromMap(userDoc.data()!));
          }
        } catch (e) {
          _logger.e('Error fetching member $memberId: $e');
        }
      }
      
      return members;
    });
  }

  // Get community banned users stream
  Stream<List<UserModel>> getCommunityBannedUsersStream(String communityId) {
    return _firestore
        .collection(AppConstants.communitiesCollection)
        .doc(communityId)
        .snapshots()
        .asyncMap((doc) async {
      if (!doc.exists) return [];
      
      final data = doc.data()!;
      final bannedUserIds = List<String>.from(data['banned_users'] ?? []);
      
      if (bannedUserIds.isEmpty) return [];
      
      final bannedUsers = <UserModel>[];
      for (final userId in bannedUserIds) {
        try {
          final userDoc = await _firestore
              .collection(AppConstants.usersCollection)
              .doc(userId)
              .get();
          
          if (userDoc.exists) {
            bannedUsers.add(UserModel.fromMap(userDoc.data()!));
          }
        } catch (e) {
          _logger.e('Error fetching banned user $userId: $e');
        }
      }
      
      return bannedUsers;
    });
  }

  // Remove member from community
  Future<void> removeMember(String communityId, String memberId) async {
    try {
      _logger.i('Removing member $memberId from community $communityId');
      
      await _firestore
          .collection(AppConstants.communitiesCollection)
          .doc(communityId)
          .update({
        'members': FieldValue.arrayRemove([memberId]),
        'metadata.member_count': FieldValue.increment(-1),
      });
      
      _logger.i('Member removed successfully');
    } catch (e) {
      _logger.e('Error removing member: $e');
      throw Exception('Failed to remove member: $e');
    }
  }

  // Send bulk invitations
  Future<void> sendBulkInvitations(String communityId, List<String> emails) async {
    try {
      _logger.i('Sending bulk invitations to ${emails.length} emails');
      
      // TODO: Implement actual email sending
      // For now, just log the invitations
      for (final email in emails) {
        _logger.i('Invitation sent to: $email');
      }
      
      _logger.i('Bulk invitations sent successfully');
    } catch (e) {
      _logger.e('Error sending bulk invitations: $e');
      throw Exception('Failed to send invitations: $e');
    }
  }

  // Get advanced analytics
  Future<Map<String, dynamic>> getAdvancedAnalytics(String communityId) async {
    try {
      _logger.i('Getting advanced analytics for community: $communityId');
      
      final community = await getCommunity(communityId);
      if (community == null) {
        throw Exception('Community not found');
      }

      // TODO: Implement real analytics
      return {
        'engagement_rate': 0.75,
        'growth_rate': 0.12,
        'retention_rate': 0.85,
        'avg_response_time': 2.5,
        'top_contributors': [],
        'peak_activity_hours': [14, 15, 16, 20, 21],
        'content_distribution': {
          'messages': 0.4,
          'events': 0.2,
          'moments': 0.3,
          'polls': 0.1,
        },
        'member_demographics': {
          'age_groups': {'18-25': 0.3, '26-35': 0.4, '36-45': 0.2, '46+': 0.1},
          'locations': {'US': 0.6, 'UK': 0.2, 'Canada': 0.1, 'Other': 0.1},
        },
        'revenue_metrics': {
          'total_revenue': 1250.0,
          'monthly_revenue': 150.0,
          'avg_transaction': 25.0,
          'conversion_rate': 0.08,
        },
      };
    } catch (e) {
      _logger.e('Error getting advanced analytics: $e');
      return {};
    }
  }

  // Helper methods
  Future<void> _createJoinRequest(String communityId, String userId) async {
    await _firestore
        .collection(AppConstants.communitiesCollection)
        .doc(communityId)
        .collection('requests')
        .doc(userId)
        .set({
      'user_id': userId,
      'status': 'pending',
      'created_at': Timestamp.now(),
    });
  }

  Future<void> _updateUserOwnedCommunities(String userId, String communityId, bool add) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .update({
      'owned_communities': add
          ? FieldValue.arrayUnion([communityId])
          : FieldValue.arrayRemove([communityId]),
    });
  }

  Future<void> _updateUserJoinedCommunities(String userId, String communityId, bool add) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .update({
      'community_ids': add
          ? FieldValue.arrayUnion([communityId])
          : FieldValue.arrayRemove([communityId]),
    });
  }

  Future<void> _deleteCommunitySubcollections(String communityId) async {
    // Delete messages
    final messagesQuery = await _firestore
        .collection(AppConstants.messagesCollection)
        .where('community_id', isEqualTo: communityId)
        .get();
    
    for (final doc in messagesQuery.docs) {
      await doc.reference.delete();
    }

    // Delete events
    final eventsQuery = await _firestore
        .collection(AppConstants.eventsCollection)
        .where('community_id', isEqualTo: communityId)
        .get();
    
    for (final doc in eventsQuery.docs) {
      await doc.reference.delete();
    }

    // Delete other subcollections (moments, polls, etc.)
    final collections = ['moments', 'polls', 'challenges', 'requests'];
    for (final collection in collections) {
      final query = await _firestore
          .collection(AppConstants.communitiesCollection)
          .doc(communityId)
          .collection(collection)
          .get();
      
      for (final doc in query.docs) {
        await doc.reference.delete();
      }
    }
  }
} 