import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

class ImageStorageService {
  static Future<String?> saveImageLocally(String tempPath) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final String newPath = '${directory.path}/images';
      final dir = Directory(newPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      
      final String fileName = '${const Uuid().v4()}.jpg';
      final String savedPath = '$newPath/$fileName';
      
      final File tempFile = File(tempPath);
      await tempFile.copy(savedPath);
      
      return savedPath;
    } catch (e) {
      debugPrint('Error saving image locally: $e');
      return null;
    }
  }
}
