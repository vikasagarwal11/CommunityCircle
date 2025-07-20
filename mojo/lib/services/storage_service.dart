import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'dart:ui' as ui;
import 'dart:async';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  final Logger _logger = Logger();

  // Upload community cover image
  Future<String?> uploadCommunityCoverImage({
    required String communityId,
    required File imageFile,
  }) async {
    try {
      _logger.i('Uploading community cover image for: $communityId');
      
      final fileName = 'cover_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref()
          .child('communities')
          .child(communityId)
          .child('covers')
          .child(fileName);

      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'communityId': communityId,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      _logger.i('Cover image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      _logger.e('Error uploading cover image: $e');
      return null;
    }
  }

  // Pick image from gallery
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      _logger.e('Error picking image from gallery: $e');
      return null;
    }
  }

  // Take photo with camera
  Future<File?> takePhotoWithCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      _logger.e('Error taking photo: $e');
      return null;
    }
  }

  // Upload profile picture
  Future<String?> uploadProfilePicture({
    required String userId,
    required File imageFile,
  }) async {
    try {
      _logger.i('Uploading profile picture for: $userId');
      
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref()
          .child('users')
          .child(userId)
          .child('profile_pictures')
          .child(fileName);

      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'userId': userId,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      _logger.i('Profile picture uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      _logger.e('Error uploading profile picture: $e');
      return null;
    }
  }

  // Upload event image
  Future<String?> uploadEventImage({
    required String eventId,
    required File imageFile,
  }) async {
    try {
      _logger.i('Uploading event image for: $eventId');
      
      final fileName = 'event_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref()
          .child('events')
          .child(eventId)
          .child('images')
          .child(fileName);

      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'eventId': eventId,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      _logger.i('Event image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      _logger.e('Error uploading event image: $e');
      return null;
    }
  }

  // Upload community badge/icon image
  Future<String?> uploadCommunityBadgeIcon({
    required String communityId,
    required File imageFile,
  }) async {
    try {
      _logger.i('Uploading community badge/icon for: $communityId');
      final fileName = 'badge_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref()
          .child('communities')
          .child(communityId)
          .child('badge')
          .child(fileName);

      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'communityId': communityId,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      _logger.i('Badge/icon uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      _logger.e('Error uploading badge/icon: $e');
      return null;
    }
  }

  // Upload event poster
  Future<String?> uploadEventPoster({
    required String eventId,
    required File imageFile,
  }) async {
    try {
      _logger.i('Uploading event poster for: $eventId');
      
      final fileName = 'poster_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref()
          .child('events')
          .child(eventId)
          .child('posters')
          .child(fileName);

      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'eventId': eventId,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      _logger.i('Event poster uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      _logger.e('Error uploading event poster: $e');
      return null;
    }
  }

  // Generic image picker method
  Future<File?> pickImage() async {
    try {
      _logger.i('Opening image picker for local gallery');
      
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery, // Explicitly use local gallery
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        _logger.i('Image selected from local gallery: ${image.path}');
        return File(image.path);
      } else {
        _logger.i('No image selected (user cancelled)');
      }
      return null;
    } catch (e) {
      _logger.e('Error picking image from local gallery: $e');
      return null;
    }
  }

  // Generic image upload method
  Future<String?> uploadImage(File imageFile, String folderPath) async {
    try {
      _logger.i('Uploading image to folder: $folderPath');
      
      final fileName = 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref()
          .child(folderPath)
          .child(fileName);

      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      _logger.i('Image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      _logger.e('Error uploading image: $e');
      return null;
    }
  }

  // Delete file from storage
  Future<void> deleteFile(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
      _logger.i('File deleted successfully: $fileUrl');
    } catch (e) {
      _logger.e('Error deleting file: $e');
    }
  }

  // Get file size in MB
  double getFileSizeInMB(File file) {
    final bytes = file.lengthSync();
    return bytes / (1024 * 1024);
  }

  // Validate file size (max 10MB)
  bool isValidFileSize(File file) {
    final sizeInMB = getFileSizeInMB(file);
    return sizeInMB <= 10.0;
  }

  // Validate image dimensions
  Future<bool> isValidImageDimensions(File file) async {
    try {
      final bytes = file.readAsBytesSync();
      final completer = Completer<ui.Image>();
      ui.decodeImageFromList(bytes, completer.complete);
      final image = await completer.future;
      return image.width >= 200 && image.height >= 200;
    } catch (e) {
      _logger.e('Error validating image dimensions: $e');
      return false;
    }
  }
} 