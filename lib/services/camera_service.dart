// lib/services/camera_service.dart
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

class CameraService {
  final ImagePicker _picker = ImagePicker();

  // Take photo from camera
  Future<File?> takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
<<<<<<< HEAD

=======
      
>>>>>>> 4eb743f5c696f1242a8ef094993dd9ef82211e1e
      if (photo != null) {
        return File(photo.path);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to take photo: $e');
    }
  }

  // Pick image from gallery
  Future<File?> pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
<<<<<<< HEAD

=======
      
>>>>>>> 4eb743f5c696f1242a8ef094993dd9ef82211e1e
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  // Crop and optimize image
<<<<<<< HEAD
  Future<File> cropAndOptimizeImage(
    File imageFile, {
=======
  Future<File> cropAndOptimizeImage(File imageFile, {
>>>>>>> 4eb743f5c696f1242a8ef094993dd9ef82211e1e
    int? cropX,
    int? cropY,
    int? cropWidth,
    int? cropHeight,
  }) async {
    try {
      final bytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);
<<<<<<< HEAD

=======
      
>>>>>>> 4eb743f5c696f1242a8ef094993dd9ef82211e1e
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Apply cropping if parameters provided
<<<<<<< HEAD
      if (cropX != null &&
          cropY != null &&
          cropWidth != null &&
          cropHeight != null) {
        image = img.copyCrop(
          image,
          x: cropX,
          y: cropY,
          width: cropWidth,
          height: cropHeight,
=======
      if (cropX != null && cropY != null && cropWidth != null && cropHeight != null) {
        image = img.copyCrop(image, 
          x: cropX, 
          y: cropY, 
          width: cropWidth, 
          height: cropHeight
>>>>>>> 4eb743f5c696f1242a8ef094993dd9ef82211e1e
        );
      }

      // Resize to standard dimensions
      image = img.copyResize(image, width: 512, height: 512);

      // Optimize quality
      final optimizedBytes = img.encodeJpg(image, quality: 85);
<<<<<<< HEAD

      // Create optimized file
      final optimizedFile = File(
        '${imageFile.parent.path}/optimized_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await optimizedFile.writeAsBytes(optimizedBytes);

=======
      
      // Create optimized file
      final optimizedFile = File('${imageFile.parent.path}/optimized_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await optimizedFile.writeAsBytes(optimizedBytes);
      
>>>>>>> 4eb743f5c696f1242a8ef094993dd9ef82211e1e
      return optimizedFile;
    } catch (e) {
      throw Exception('Failed to crop and optimize image: $e');
    }
  }

  // Validate image file
  bool validateImageFile(File imageFile) {
    final extension = imageFile.path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png'].contains(extension);
  }

  // Get image dimensions
  Future<Map<String, int>> getImageDimensions(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
<<<<<<< HEAD

=======
      
>>>>>>> 4eb743f5c696f1242a8ef094993dd9ef82211e1e
      if (image == null) {
        throw Exception('Failed to decode image');
      }

<<<<<<< HEAD
      return {'width': image.width, 'height': image.height};
=======
      return {
        'width': image.width,
        'height': image.height,
      };
>>>>>>> 4eb743f5c696f1242a8ef094993dd9ef82211e1e
    } catch (e) {
      throw Exception('Failed to get image dimensions: $e');
    }
  }
}

// Provider
<<<<<<< HEAD
final cameraServiceProvider = Provider((ref) => CameraService());
=======
final cameraServiceProvider = Provider((ref) => CameraService());
>>>>>>> 4eb743f5c696f1242a8ef094993dd9ef82211e1e
