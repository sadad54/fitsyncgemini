import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class ImageUploadService {
  final ImagePicker _picker = ImagePicker();

  /// Request camera and storage permissions
  Future<bool> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses =
        await [
          Permission.camera,
          Permission.photos,
          Permission.storage,
        ].request();

    return statuses.values.every((status) => status.isGranted);
  }

  /// Capture photo using camera
  Future<File?> capturePhoto() async {
    try {
      if (!await requestPermissions()) {
        throw Exception('Camera and storage permissions are required');
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      return image != null ? File(image.path) : null;
    } catch (e) {
      throw Exception('Failed to capture photo: $e');
    }
  }

  /// Select image from gallery
  Future<File?> selectFromGallery() async {
    try {
      if (!await requestPermissions()) {
        throw Exception('Storage permissions are required');
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      return image != null ? File(image.path) : null;
    } catch (e) {
      throw Exception('Failed to select image: $e');
    }
  }

  /// Upload image to Supabase storage
  Future<String> uploadImage(
    File imageFile, {
    Function(double)? onProgress,
  }) async {
    try {
      // TODO: Replace with actual Supabase upload logic
      // For now, simulate upload progress
      for (int i = 0; i <= 100; i += 10) {
        await Future.delayed(const Duration(milliseconds: 100));
        onProgress?.call(i / 100);
      }

      // TODO: Implement actual Supabase storage upload
      // Example implementation:
      // final fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
      // final response = await Supabase.instance.client.storage
      //     .from('community-images')
      //     .upload(fileName, imageFile);
      //
      // final imageUrl = Supabase.instance.client.storage
      //     .from('community-images')
      //     .getPublicUrl(response);
      //
      // return imageUrl;

      // For now, return a placeholder URL
      return 'https://via.placeholder.com/400x500/00E5FF/FFFFFF?text=Uploaded+Image';
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Compress image for better performance
  Future<File> compressImage(File imageFile) async {
    try {
      // TODO: Implement image compression
      // For now, return the original file
      return imageFile;
    } catch (e) {
      throw Exception('Failed to compress image: $e');
    }
  }
}
