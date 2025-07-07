import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../models/community_model.dart';
import '../models/user_model.dart';
import 'database_service.dart';

class CommunityService {
  final DatabaseService _databaseService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();

  CommunityService(this._databaseService);

  // Query Methods
  Future<List<CommunityModel>> getPublicCommunities() async {
    try {
      _logger.d('Fetching public communities');
      final querySnapshot = await _firestore
          .collection('communities')
          .where('visibility', isEqualTo: 'public')
          .orderBy('createdAt', descending: true)
          .get();

      final communities = querySnapshot.docs.map((doc) {
        return CommunityModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();

      _logger.i('Found ${communities.length} public communities');
      return communities;
    } catch (e) {
      _logger.e('Error fetching public communities: $e');
      rethrow;
    }
  }

  Future<List<CommunityModel>> getUserCommunities(String userId) async {
    try {
      _logger.d('Fetching communities for user: $userId');
      final querySnapshot = await _firestore
          .collection('communities')
          .where('members', arrayContains: userId)
          .orderBy('createdAt', descending: true)
          .get();

      final communities = querySnapshot.docs.map((doc) {
        return CommunityModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();

      _logger.i('Found ${communities.length} communities for user');
      return communities;
    } catch (e) {
      _logger.e('Error fetching user communities: $e');
      rethrow;
    }
  }

  Future<List<CommunityModel>> getBusinessCommunities() async {
    try {
      _logger.d('Fetching business communities');
      final querySnapshot = await _firestore
          .collection('communities')
          .where('isBusiness', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      final communities = querySnapshot.docs.map((doc) {
        return CommunityModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();

      _logger.i('Found ${communities.length} business communities');
      return communities;
    } catch (e) {
      _logger.e('Error fetching business communities: $e');
      rethrow;
    }
  }

  Future<List<CommunityModel>> searchCommunities(String query) async {
    try {
      _logger.d('Searching communities with query: $query');
      final querySnapshot = await _firestore
          .collection('communities')
          .where('visibility', isEqualTo: 'public')
          .get();

      final communities = querySnapshot.docs.map((doc) {
        return CommunityModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).where((community) {
        return community.name.toLowerCase().contains(query.toLowerCase()) ||
            community.description.toLowerCase().contains(query.toLowerCase());
      }).toList();

      _logger.i('Found ${communities.length} communities matching query');
      return communities;
    } catch (e) {
      _logger.e('Error searching communities: $e');
      rethrow;
    }
  }

  // Business Logic Methods
  Future<String> createCommunity({
    required String name,
    required String description,
    required String adminUid,
    String? coverImage,
    String visibility = 'public',
    bool approvalRequired = false,
    bool isBusiness = false,
  }) async {
    try {
      _logger.d('Creating community: $name');
      
      final community = CommunityModel(
        id: '', // Will be set by Firestore
        name: name,
        description: description,
        coverImage: coverImage,
        adminUid: adminUid,
        visibility: visibility,
        approvalRequired: approvalRequired,
        isBusiness: isBusiness,
        members: [adminUid], // Admin is automatically a member
        bannedUsers: [],
        pinnedItems: [],
        createdAt: DateTime.now(),
      );

      final communityId = await _databaseService.createCommunity(community);
      
      // Update the community with the correct ID
      final updatedCommunity = community.copyWith(id: communityId);
      await _databaseService.updateCommunity(updatedCommunity);

      _logger.i('Community created successfully: $name with ID: $communityId');
      return communityId;
    } catch (e) {
      _logger.e('Error creating community: $e');
      rethrow;
    }
  }

  Future<void> joinCommunity(String communityId, String userId) async {
    try {
      _logger.d('User $userId joining community $communityId');
      
      final community = await _databaseService.getCommunity(communityId);
      if (community == null) {
        throw Exception('Community not found');
      }

      if (community.isBanned(userId)) {
        throw Exception('User is banned from this community');
      }

      if (community.isMember(userId)) {
        _logger.w('User is already a member of this community');
        return;
      }

      final updatedMembers = List<String>.from(community.members)..add(userId);
      final updatedCommunity = community.copyWith(members: updatedMembers);
      
      await _databaseService.updateCommunity(updatedCommunity);
      _logger.i('User joined community successfully');
    } catch (e) {
      _logger.e('Error joining community: $e');
      rethrow;
    }
  }

  Future<void> leaveCommunity(String communityId, String userId) async {
    try {
      _logger.d('User $userId leaving community $communityId');
      
      final community = await _databaseService.getCommunity(communityId);
      if (community == null) {
        throw Exception('Community not found');
      }

      if (!community.isMember(userId)) {
        _logger.w('User is not a member of this community');
        return;
      }

      if (community.isAdmin(userId)) {
        throw Exception('Admin cannot leave community. Transfer admin role first.');
      }

      final updatedMembers = List<String>.from(community.members)..remove(userId);
      final updatedCommunity = community.copyWith(members: updatedMembers);
      
      await _databaseService.updateCommunity(updatedCommunity);
      _logger.i('User left community successfully');
    } catch (e) {
      _logger.e('Error leaving community: $e');
      rethrow;
    }
  }

  Future<void> banUser(String communityId, String adminUid, String userIdToBan) async {
    try {
      _logger.d('Admin $adminUid banning user $userIdToBan from community $communityId');
      
      final community = await _databaseService.getCommunity(communityId);
      if (community == null) {
        throw Exception('Community not found');
      }

      if (!community.isAdmin(adminUid)) {
        throw Exception('Only admins can ban users');
      }

      if (community.isAdmin(userIdToBan)) {
        throw Exception('Cannot ban admin user');
      }

      final updatedBannedUsers = List<String>.from(community.bannedUsers)..add(userIdToBan);
      final updatedMembers = List<String>.from(community.members)..remove(userIdToBan);
      
      final updatedCommunity = community.copyWith(
        bannedUsers: updatedBannedUsers,
        members: updatedMembers,
      );
      
      await _databaseService.updateCommunity(updatedCommunity);
      _logger.i('User banned successfully');
    } catch (e) {
      _logger.e('Error banning user: $e');
      rethrow;
    }
  }

  Future<void> unbanUser(String communityId, String adminUid, String userIdToUnban) async {
    try {
      _logger.d('Admin $adminUid unbanning user $userIdToUnban from community $communityId');
      
      final community = await _databaseService.getCommunity(communityId);
      if (community == null) {
        throw Exception('Community not found');
      }

      if (!community.isAdmin(adminUid)) {
        throw Exception('Only admins can unban users');
      }

      if (!community.isBanned(userIdToUnban)) {
        _logger.w('User is not banned from this community');
        return;
      }

      final updatedBannedUsers = List<String>.from(community.bannedUsers)..remove(userIdToUnban);
      final updatedCommunity = community.copyWith(bannedUsers: updatedBannedUsers);
      
      await _databaseService.updateCommunity(updatedCommunity);
      _logger.i('User unbanned successfully');
    } catch (e) {
      _logger.e('Error unbanning user: $e');
      rethrow;
    }
  }

  Future<void> transferAdminRole(String communityId, String currentAdminUid, String newAdminUid) async {
    try {
      _logger.d('Transferring admin role from $currentAdminUid to $newAdminUid in community $communityId');
      
      final community = await _databaseService.getCommunity(communityId);
      if (community == null) {
        throw Exception('Community not found');
      }

      if (!community.isAdmin(currentAdminUid)) {
        throw Exception('Only current admin can transfer admin role');
      }

      if (!community.isMember(newAdminUid)) {
        throw Exception('New admin must be a member of the community');
      }

      final updatedCommunity = community.copyWith(adminUid: newAdminUid);
      await _databaseService.updateCommunity(updatedCommunity);
      
      _logger.i('Admin role transferred successfully');
    } catch (e) {
      _logger.e('Error transferring admin role: $e');
      rethrow;
    }
  }

  Future<void> updateCommunitySettings({
    required String communityId,
    required String adminUid,
    String? name,
    String? description,
    String? coverImage,
    String? visibility,
    bool? approvalRequired,
  }) async {
    try {
      _logger.d('Updating community settings for $communityId');
      
      final community = await _databaseService.getCommunity(communityId);
      if (community == null) {
        throw Exception('Community not found');
      }

      if (!community.isAdmin(adminUid)) {
        throw Exception('Only admins can update community settings');
      }

      final updatedCommunity = community.copyWith(
        name: name ?? community.name,
        description: description ?? community.description,
        coverImage: coverImage ?? community.coverImage,
        visibility: visibility ?? community.visibility,
        approvalRequired: approvalRequired ?? community.approvalRequired,
      );
      
      await _databaseService.updateCommunity(updatedCommunity);
      _logger.i('Community settings updated successfully');
    } catch (e) {
      _logger.e('Error updating community settings: $e');
      rethrow;
    }
  }

  // Analytics Methods
  Future<Map<String, dynamic>> getCommunityStats(String communityId) async {
    try {
      _logger.d('Getting stats for community: $communityId');
      
      final community = await _databaseService.getCommunity(communityId);
      if (community == null) {
        throw Exception('Community not found');
      }

      // Get event count
      final eventsQuery = await _firestore
          .collection('events')
          .where('communityId', isEqualTo: communityId)
          .get();

      // Get message count
      final messagesQuery = await _firestore
          .collection('messages')
          .where('communityId', isEqualTo: communityId)
          .get();

      // Get moment count
      final momentsQuery = await _firestore
          .collection('moments')
          .where('communityId', isEqualTo: communityId)
          .get();

      final stats = {
        'memberCount': community.members.length,
        'eventCount': eventsQuery.docs.length,
        'messageCount': messagesQuery.docs.length,
        'momentCount': momentsQuery.docs.length,
        'bannedUserCount': community.bannedUsers.length,
        'createdAt': community.createdAt,
      };

      _logger.i('Community stats retrieved successfully');
      return stats;
    } catch (e) {
      _logger.e('Error getting community stats: $e');
      rethrow;
    }
  }
} 