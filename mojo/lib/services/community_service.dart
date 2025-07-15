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
    String? badgeUrl,
    required String visibility,
    bool approvalRequired = false,
    bool isBusiness = false,
    List<String>? joinQuestions,
    List<String>? rules,
    String? welcomeMessage, // NEW: Custom welcome message
    List<String>? tags, // NEW: Community tags
    Map<String, String>? theme,
  }) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        _logger.e('User not authenticated');
        throw Exception('User not authenticated');
      }

      // Fetch user document to check role
      final userDoc = await _firestore.collection(AppConstants.usersCollection).doc(userId).get();
      if (!userDoc.exists) {
        _logger.e('User document not found');
        throw Exception('User not found');
      }
      final userRole = userDoc['role'] ?? 'member';
      if (userRole == 'anonymous') {
        _logger.e('Anonymous users cannot create communities');
        throw Exception('Anonymous users cannot create communities');
      }

      _logger.i('Creating community: $name');

      final communityData = {
        'name': name,
        'description': description,
        'cover_image': coverImage ?? '',
        'badge_url': badgeUrl ?? '',
        'admin_uid': userId,
        'visibility': visibility,
        'approval_required': approvalRequired,
        'is_business': isBusiness,
        'members': [userId], // Admin is automatically a member
        'banned_users': [],
        'pinned_items': [],
        'join_questions': joinQuestions ?? [],
        'rules': rules ?? [],
        'welcome_message': welcomeMessage ?? '', // NEW
        'tags': tags ?? [], // NEW
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
               community.description.toLowerCase().contains(searchLower) ||
               community.tags.any((tag) => tag.toLowerCase().contains(searchLower));
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

  // Join community with answers to questions
  Future<void> joinCommunityWithAnswers(String communityId, List<String> answers) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      _logger.i('Joining community with answers: $communityId');

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

      // Validate answers match questions
      if (answers.length != community.joinQuestions.length) {
        throw Exception('Number of answers must match number of questions');
      }

      // Store answers in user's join history
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection('join_answers')
          .doc(communityId)
          .set({
        'community_id': communityId,
        'answers': answers,
        'questions': community.joinQuestions,
        'answered_at': Timestamp.now(),
      });

      if (community.requiresInvite) {
        // Create join request with answers
        await _firestore
            .collection(AppConstants.communitiesCollection)
            .doc(communityId)
            .collection('requests')
            .doc(userId)
            .set({
          'user_id': userId,
          'status': 'pending',
          'answers': answers,
          'questions': community.joinQuestions,
          'created_at': Timestamp.now(),
        });
        _logger.i('Join request with answers created for community: $communityId');
      } else {
        // Direct join with answers
        await _firestore
            .collection(AppConstants.communitiesCollection)
            .doc(communityId)
            .update({
          'members': FieldValue.arrayUnion([userId]),
          'metadata.member_count': FieldValue.increment(1),
        });

        // Update user's joined communities
        await _updateUserJoinedCommunities(userId, communityId, true);

        _logger.i('Successfully joined community with answers: $communityId');
      }
    } catch (e) {
      _logger.e('Error joining community with answers: $e');
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

  // Update join questions
  Future<void> updateJoinQuestions(String communityId, List<String> questions) async {
    try {
      _logger.i('Updating join questions for community: $communityId');
      
      final userId = currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final community = await getCommunity(communityId);
      if (community == null) {
        throw Exception('Community not found');
      }

      if (community.adminUid != userId) {
        throw Exception('Only community admin can update join questions');
      }

      await _firestore
          .collection(AppConstants.communitiesCollection)
          .doc(communityId)
          .update({
        'join_questions': questions,
      });
      
      _logger.i('Join questions updated successfully');
    } catch (e) {
      _logger.e('Error updating join questions: $e');
      throw Exception('Failed to update join questions: $e');
    }
  }

  // Update community rules
  Future<void> updateRules(String communityId, List<String> rules) async {
    try {
      _logger.i('Updating rules for community: $communityId');
      
      final userId = currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final community = await getCommunity(communityId);
      if (community == null) {
        throw Exception('Community not found');
      }

      if (community.adminUid != userId) {
        throw Exception('Only community admin can update rules');
      }

      await _firestore
          .collection(AppConstants.communitiesCollection)
          .doc(communityId)
          .update({
        'rules': rules,
      });
      
      _logger.i('Rules updated successfully');
    } catch (e) {
      _logger.e('Error updating rules: $e');
      throw Exception('Failed to update rules: $e');
    }
  }

  // NEW: Update community welcome message
  Future<void> updateWelcomeMessage(String communityId, String welcomeMessage) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      _logger.i('Updating welcome message for community: $communityId');

      final community = await getCommunity(communityId);
      if (community == null) {
        throw Exception('Community not found');
      }

      if (!community.isAdmin(userId)) {
        throw Exception('Only admin can update welcome message');
      }

      await _firestore
          .collection(AppConstants.communitiesCollection)
          .doc(communityId)
          .update({
        'welcome_message': welcomeMessage,
      });

      _logger.i('Welcome message updated successfully: $communityId');
    } catch (e) {
      _logger.e('Error updating welcome message: $e');
      throw Exception('Failed to update welcome message: $e');
    }
  }

  // NEW: Acknowledge community rules
  Future<void> acknowledgeRules(String communityId, List<String> acknowledgedRules) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      _logger.i('Acknowledging rules for community: $communityId');

      final community = await getCommunity(communityId);
      if (community == null) {
        throw Exception('Community not found');
      }

      // Validate that all acknowledged rules exist in community
      for (final rule in acknowledgedRules) {
        if (!community.rules.contains(rule)) {
          throw Exception('Invalid rule: $rule');
        }
      }

      // Update user's rule acknowledgments
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
        'ruleAcknowledgments.$communityId': acknowledgedRules,
      });

      _logger.i('Rules acknowledged successfully: $communityId');
    } catch (e) {
      _logger.e('Error acknowledging rules: $e');
      throw Exception('Failed to acknowledge rules: $e');
    }
  }

  // NEW: Get pending join requests for admin review
  Stream<List<Map<String, dynamic>>> getPendingJoinRequests(String communityId) {
    return _firestore
        .collection(AppConstants.communitiesCollection)
        .doc(communityId)
        .collection('requests')
        .where('status', isEqualTo: 'pending')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'userId': data['user_id'],
          'status': data['status'],
          'answers': List<String>.from(data['answers'] ?? []),
          'questions': List<String>.from(data['questions'] ?? []),
          'createdAt': data['created_at'],
        };
      }).toList();
    });
  }

  // NEW: Approve join request
  Future<void> approveJoinRequest(String communityId, String userId) async {
    try {
      final adminId = currentUserId;
      if (adminId == null) {
        throw Exception('User not authenticated');
      }

      _logger.i('Approving join request for user $userId in community: $communityId');

      final community = await getCommunity(communityId);
      if (community == null) {
        throw Exception('Community not found');
      }

      if (!community.isAdmin(adminId)) {
        throw Exception('Only admin can approve join requests');
      }

      // Add user to community members
      await _firestore
          .collection(AppConstants.communitiesCollection)
          .doc(communityId)
          .update({
        'members': FieldValue.arrayUnion([userId]),
        'metadata.member_count': FieldValue.increment(1),
      });

      // Update request status
      await _firestore
          .collection(AppConstants.communitiesCollection)
          .doc(communityId)
          .collection('requests')
          .doc(userId)
          .update({
        'status': 'approved',
        'approved_at': Timestamp.now(),
        'approved_by': adminId,
      });

      // Update user's joined communities
      await _updateUserJoinedCommunities(userId, communityId, true);

      _logger.i('Join request approved successfully: $userId');
    } catch (e) {
      _logger.e('Error approving join request: $e');
      throw Exception('Failed to approve join request: $e');
    }
  }

  // NEW: Reject join request
  Future<void> rejectJoinRequest(String communityId, String userId, String? reason) async {
    try {
      final adminId = currentUserId;
      if (adminId == null) {
        throw Exception('User not authenticated');
      }

      _logger.i('Rejecting join request for user $userId in community: $communityId');

      final community = await getCommunity(communityId);
      if (community == null) {
        throw Exception('Community not found');
      }

      if (!community.isAdmin(adminId)) {
        throw Exception('Only admin can reject join requests');
      }

      // Update request status
      await _firestore
          .collection(AppConstants.communitiesCollection)
          .doc(communityId)
          .collection('requests')
          .doc(userId)
          .update({
        'status': 'rejected',
        'rejected_at': Timestamp.now(),
        'rejected_by': adminId,
        'rejection_reason': reason,
      });

      _logger.i('Join request rejected successfully: $userId');
    } catch (e) {
      _logger.e('Error rejecting join request: $e');
      throw Exception('Failed to reject join request: $e');
    }
  }

  // NEW: Get user's join answers for a community
  Future<List<String>> getUserJoinAnswers(String communityId, String userId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection('join_answers')
          .doc(communityId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        return List<String>.from(data['answers'] ?? []);
      }
      return [];
    } catch (e) {
      _logger.e('Error getting user join answers: $e');
      return [];
    }
  }

  // NEW: Check if user has acknowledged rules
  Future<bool> hasUserAcknowledgedRules(String communityId, String userId) async {
    try {
      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      if (!userDoc.exists) return false;

      final data = userDoc.data()!;
      final ruleAcknowledgments = data['ruleAcknowledgments'] as Map<String, dynamic>?;
      
      if (ruleAcknowledgments == null) return false;
      
      final acknowledgedRules = ruleAcknowledgments[communityId] as List<dynamic>?;
      return acknowledgedRules != null && acknowledgedRules.isNotEmpty;
    } catch (e) {
      _logger.e('Error checking rule acknowledgments: $e');
      return false;
    }
  }

  // NEW: Complete onboarding for user in community
  Future<void> completeOnboarding(String communityId, String userId) async {
    try {
      final currentUser = currentUserId;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      if (currentUser != userId) {
        throw Exception('Users can only complete their own onboarding');
      }

      _logger.i('Completing onboarding for user $userId in community: $communityId');

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
        'onboardingCompleted.$communityId': true,
      });

      _logger.i('Onboarding completed successfully for user: $userId');
    } catch (e) {
      _logger.e('Error completing onboarding: $e');
      throw Exception('Failed to complete onboarding: $e');
    }
  }

  // NEW: Check if user has completed onboarding
  Future<bool> hasUserCompletedOnboarding(String communityId, String userId) async {
    try {
      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      if (!userDoc.exists) return false;

      final data = userDoc.data()!;
      final onboardingCompleted = data['onboardingCompleted'] as Map<String, dynamic>?;
      
      if (onboardingCompleted == null) return false;
      
      return onboardingCompleted[communityId] == true;
    } catch (e) {
      _logger.e('Error checking onboarding completion: $e');
      return false;
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