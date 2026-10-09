import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class StorageService {
  /// Save an image file to app document storage directory
  static Future<String?> saveReceiptImage(File imageFile) async {
    if (kIsWeb) return null;

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final receiptsDir = Directory(p.join(appDir.path, 'receipt_thumbnails'));
      
      if (!await receiptsDir.exists()) {
        await receiptsDir.create(recursive: true);
      }

      final fileName = 'receipt_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedPath = p.join(receiptsDir.path, fileName);

      final savedFile = await imageFile.copy(savedPath);
      return savedFile.path;
    } catch (e) {
      debugPrint('Error saving receipt image: $e');
      return null;
    }
  }

  /// Delete cached thumbnail image
  static Future<void> deleteReceiptImage(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty || kIsWeb) return;
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error deleting receipt thumbnail: $e');
    }
  }
}
