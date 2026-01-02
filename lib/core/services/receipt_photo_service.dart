import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_colors.dart';

/// Service for managing receipt photos locally
class ReceiptPhotoService {
  final ImagePicker _picker = ImagePicker();

  /// Show dialog to choose photo source and pick photo
  Future<File?> pickPhoto(BuildContext context) async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Add Receipt Photo',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.orange.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Photos are stored locally and will be deleted if you uninstall the app',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(
                Icons.camera_alt,
                color: AppColors.primaryBlue,
                size: 28,
              ),
              title: const Text('Take Photo'),
              subtitle: const Text('Use camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: AppColors.primaryBlue,
                size: 28,
              ),
              title: const Text('Choose from Gallery'),
              subtitle: const Text('Select existing photo'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (source == null) return null;

    try {
      final image = await _picker.pickImage(
        source: source,
        maxWidth: 1920, // Limit size for storage efficiency
        maxHeight: 1920,
        imageQuality: 85, // Good quality, reasonable size
      );

      if (image == null) return null;
      return File(image.path);
    } catch (e) {
      debugPrint('❌ Error picking photo: $e');
      return null;
    }
  }

  /// Save photo to app's local storage
  Future<String> savePhoto(File photo, String receiptId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final receiptsDir = Directory('${directory.path}/receipts');

      // Create directory if doesn't exist
      if (!await receiptsDir.exists()) {
        await receiptsDir.create(recursive: true);
        debugPrint('📁 Created receipts directory: ${receiptsDir.path}');
      }

      final fileName = '$receiptId.jpg';
      final savedPath = '${receiptsDir.path}/$fileName';

      // Copy photo to app storage
      await photo.copy(savedPath);
      debugPrint('✅ Photo saved: $savedPath');

      return savedPath;
    } catch (e) {
      debugPrint('❌ Error saving photo: $e');
      rethrow;
    }
  }

  /// Get photo file from path
  File? getPhoto(String? photoPath) {
    if (photoPath == null || photoPath.isEmpty) return null;

    final file = File(photoPath);
    if (file.existsSync()) {
      return file;
    } else {
      debugPrint('⚠️ Photo file not found: $photoPath');
      return null;
    }
  }

  /// Delete photo from storage
  Future<void> deletePhoto(String photoPath) async {
    try {
      final file = File(photoPath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('🗑️ Photo deleted: $photoPath');
      }
    } catch (e) {
      debugPrint('❌ Error deleting photo: $e');
    }
  }

  /// Check if photo exists
  bool photoExists(String? photoPath) {
    if (photoPath == null || photoPath.isEmpty) return false;
    return File(photoPath).existsSync();
  }
}
