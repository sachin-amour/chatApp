import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:path/path.dart' as p;

class CloudinaryStorageService {
  final CloudinaryPublic _cloudinary;

  // Singleton pattern to match your other services
  static CloudinaryStorageService? _instance;

  factory CloudinaryStorageService() {
    _instance ??= CloudinaryStorageService._internal();
    return _instance!;
  }

  // Private constructor
  CloudinaryStorageService._internal()
      : _cloudinary = CloudinaryPublic(
    'amouraspace',
    'flutter_app',
    cache: false,
  );

  /// Upload user profile picture
  /// Returns the secure URL of the uploaded image
  Future<String?> uploadUserPfp({
    required File file,
    required String uid,
  }) async {
    try {
      // Get file extension
      String extension = p.extension(file.path);

      // Create a unique public ID for the image
      String publicId = 'users/pfps/$uid$extension';

      // Upload the file to Cloudinary
      CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          file.path,
          publicId: publicId,
          folder: 'users/pfps',
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      // Return the secure URL
      if (response.secureUrl.isNotEmpty) {
        return response.secureUrl;
      }

      return null;
    } catch (e) {
      print('Error uploading to Cloudinary: $e');
      return null;
    }
  }

  /// Upload any image with custom folder path
  // Inside CloudinaryStorageService class

  /// Upload any image with custom folder path
  Future<String?> uploadImageToChat({
    required File file,
    required String chatId,
  }) async {
    try {
      // 1. Get file extension
      String extension = p.extension(file.path);

      // 2. Create a unique file name using a timestamp (or UUID for better uniqueness)
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();

      // 3. Define the folder path
      String folderPath = 'chats/$chatId'; // Better to use a 'chats' specific folder

      // 4. Create the public ID including the folder path and unique file name
      // This ensures a unique path for every image in that chat's folder.
      String publicId = '$folderPath/$fileName$extension';

      CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          file.path,
          publicId: publicId, // Use the fully unique public ID
          folder: folderPath, // Use the folder path
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      // Return the secure URL
      if (response.secureUrl.isNotEmpty) {
        return response.secureUrl;
      }

      return null;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  /// Upload video
  Future<String?> uploadVideo({
    required File file,
    required String folder,
    String? publicId,
  }) async {
    try {
      CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          file.path,
          publicId: publicId,
          folder: folder,
          resourceType: CloudinaryResourceType.Video,
        ),
      );

      if (response.secureUrl.isNotEmpty) {
        return response.secureUrl;
      }

      return null;
    } catch (e) {
      print('Error uploading video: $e');
      return null;
    }
  }

  /// Delete an image from Cloudinary
  // Future<bool> deleteImage(String publicId) async {
  //   try {
  //     await _cloudinary.deleteFile(
  //       publicId: publicId,
  //       resourceType: CloudinaryResourceType.Image,
  //       invalidate: true,
  //     );
  //     return true;
  //   } catch (e) {
  //     print('Error deleting image: $e');
  //     return false;
  //   }
  // }

  /// Get optimized image URL with transformations
  String getOptimizedImageUrl({
    required String secureUrl,
    int? width,
    int? height,
    String quality = 'auto',
    String format = 'auto',
  }) {
    // Extract public ID from secure URL
    Uri uri = Uri.parse(secureUrl);
    List<String> pathSegments = uri.pathSegments;

    // Cloudinary URL structure: .../upload/v123456/folder/image.jpg
    int uploadIndex = pathSegments.indexOf('upload');
    if (uploadIndex == -1) return secureUrl;

    // Build transformation string
    List<String> transformations = [];
    if (width != null) transformations.add('w_$width');
    if (height != null) transformations.add('h_$height');
    transformations.add('q_$quality');
    transformations.add('f_$format');

    String transformation = transformations.join(',');

    // Reconstruct URL with transformations
    List<String> newSegments = List.from(pathSegments);
    newSegments.insert(uploadIndex + 1, transformation);

    return '${uri.scheme}://${uri.host}/${newSegments.join('/')}';
  }
}

/// Example usage:
///
/// // Initialize the service (do this once, preferably in main.dart or dependency injection)
/// final storageService = CloudinaryStorageService(
///   cloudName: 'your_cloud_name',
///   uploadPreset: 'your_upload_preset',
/// );
///
/// // Upload profile picture
/// String? imageUrl = await storageService.uploadUserPfp(
///   file: imageFile,
///   uid: currentUserId,
/// );
///
/// if (imageUrl != null) {
///   print('Image uploaded successfully: $imageUrl');
///   // Save imageUrl to your database
/// }
///
/// // Get optimized version of image
/// String optimizedUrl = storageService.getOptimizedImageUrl(
///   secureUrl: imageUrl!,
///   width: 300,
///   height: 300,
///   quality: 'auto',
/// );