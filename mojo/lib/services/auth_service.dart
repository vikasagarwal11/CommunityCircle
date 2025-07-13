import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../models/user_model.dart';
import '../core/constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Send OTP to phone number
  Future<void> sendOtp({
    required String phoneNumber,
    required Function(String) onCodeSent,
    required Function(String) onError,
  }) async {
    try {
      _logger.i('Sending OTP to: $phoneNumber');
      
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          _logger.i('Auto verification completed');
          await _signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          _logger.e('Verification failed: ${e.message}');
          onError(e.message ?? AppConstants.authError);
        },
        codeSent: (String verificationId, int? resendToken) {
          _logger.i('OTP code sent successfully');
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _logger.w('OTP auto retrieval timeout');
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      _logger.e('Error sending OTP: $e');
      onError(AppConstants.generalError);
    }
  }

  // Verify OTP and sign in
  Future<UserModel?> verifyOtp({
    required String verificationId,
    required String otp,
    required Function(String) onError,
  }) async {
    try {
      _logger.i('Verifying OTP');
      
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      return await _signInWithCredential(credential);
    } catch (e) {
      _logger.e('Error verifying OTP: $e');
      onError(AppConstants.invalidOtp);
      return null;
    }
  }

  // Sign in with credential
  Future<UserModel?> _signInWithCredential(PhoneAuthCredential credential) async {
    try {
      UserCredential userCredential = await _auth.signInWithCredential(credential);
      User? user = userCredential.user;
      
      if (user != null) {
        _logger.i('User signed in successfully: ${user.uid}');
        return await getOrCreateUser(user);
      }
      
      return null;
    } catch (e) {
      _logger.e('Error signing in with credential: $e');
      return null;
    }
  }

  // Get or create user in Firestore
  Future<UserModel?> getOrCreateUser(User user) async {
    try {
      DocumentSnapshot userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        _logger.i('User found in Firestore');
        return UserModel.fromMap({
          'id': user.uid,
          ...userDoc.data() as Map<String, dynamic>,
        });
      } else {
        _logger.i('Creating new user in Firestore');
        return await _createNewUser(user);
      }
    } catch (e) {
      _logger.e('Error getting/creating user: $e');
      return null;
    }
  }

  // Create new user in Firestore
  Future<UserModel?> _createNewUser(User user) async {
    try {
      final now = DateTime.now();
      final userModel = UserModel(
        id: user.uid,
        phoneNumber: user.phoneNumber ?? '',
        displayName: user.displayName ?? 'User_${user.uid.substring(0, 8)}',
        email: user.email,
        role: 'member', // Default role for phone-authenticated users
        createdAt: now,
        lastSeen: now,
        isOnline: true,
        communityIds: [],
        communityRoles: {},
        badges: [],
        totalPoints: 0,
      );

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .set(userModel.toMap());

      _logger.i('New user created successfully');
      return userModel;
    } catch (e) {
      _logger.e('Error creating new user: $e');
      return null;
    }
  }

  // Update user last seen
  Future<void> updateLastSeen(String userId) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
        'lastSeen': DateTime.now(),
        'isOnline': true,
      });
    } catch (e) {
      _logger.e('Error updating last seen: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      if (currentUser != null) {
        await updateLastSeen(currentUser!.uid);
      }
      await _auth.signOut();
      _logger.i('User signed out successfully');
    } catch (e) {
      _logger.e('Error signing out: $e');
    }
  }

  // Update user profile
  Future<void> updateProfile({
    required String userId,
    String? displayName,
    String? email,
    String? profilePictureUrl,
  }) async {
    try {
      _logger.d('updateProfile called with userId: $userId, displayName: $displayName, email: $email, profilePictureUrl: $profilePictureUrl');
      Map<String, dynamic> updates = {};
      if (displayName != null) updates['displayName'] = displayName;
      if (email != null) updates['email'] = email;
      if (profilePictureUrl != null) updates['profilePictureUrl'] = profilePictureUrl;

      _logger.d('Attempting Firestore update for user $userId with: $updates');
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update(updates);

      _logger.i('Profile updated successfully for user $userId');
    } catch (e, stack) {
      _logger.e('Error updating profile for user $userId: $e\n$stack');
      throw Exception('Failed to update profile: $e');
    }
  }

  // Sign in anonymously
  Future<UserModel?> signInAnonymously() async {
    try {
      _logger.i('Signing in anonymously');
      
      UserCredential userCredential = await _auth.signInAnonymously();
      User? user = userCredential.user;
      
      if (user != null) {
        _logger.i('Anonymous user created: ${user.uid}');
        return await _createAnonymousUser(user);
      }
      
      return null;
    } catch (e) {
      _logger.e('Error signing in anonymously: $e');
      return null;
    }
  }

  // Create anonymous user
  Future<UserModel?> _createAnonymousUser(User user) async {
    try {
      final now = DateTime.now();
      final userModel = UserModel(
        id: user.uid,
        phoneNumber: '', // Anonymous users don't have phone numbers
        displayName: 'Guest',
        email: null,
        role: 'anonymous', // Set role to anonymous
        createdAt: now,
        lastSeen: now,
        isOnline: true,
        communityIds: [],
        communityRoles: {},
        badges: [],
        totalPoints: 0,
      );

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .set(userModel.toMap());

      _logger.i('Anonymous user created successfully');
      return userModel;
    } catch (e) {
      _logger.e('Error creating anonymous user: $e');
      return null;
    }
  }

  // Get user role
  Future<String> getUserRole() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot doc = await _firestore
            .collection(AppConstants.usersCollection)
            .doc(user.uid)
            .get();
        
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          return data['role'] ?? 'member';
        }
      }
      return 'anonymous';
    } catch (e) {
      _logger.e('Error getting user role: $e');
      return 'anonymous';
    }
  }

  // Check if user is business
  Future<bool> isBusinessUser() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot doc = await _firestore
            .collection(AppConstants.usersCollection)
            .doc(user.uid)
            .get();
        
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          return data['isBusiness'] ?? false;
        }
      }
      return false;
    } catch (e) {
      _logger.e('Error checking business user: $e');
      return false;
    }
  }

  // Get initial route based on user state
  Future<String> getInitialRoute() async {
    final user = currentUser;
    if (user == null) return '/phone-auth';
    
    // Get user role from Firestore
    final userDoc = await _firestore.collection(AppConstants.usersCollection).doc(user.uid).get();
    
    if (!userDoc.exists) return '/phone-auth';
    
    final role = userDoc.data()?['role'] ?? 'member';
    return role == 'anonymous' ? '/public-home' : '/home';
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(user.uid)
            .delete();
        await user.delete();
        _logger.i('Account deleted successfully');
      }
    } catch (e) {
      _logger.e('Error deleting account: $e');
      throw Exception('Failed to delete account');
    }
  }
} 