import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ImageValidator {
  static const List<String> supportedFormats = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
  static const int maxFileSizeInBytes = 10 * 1024 * 1024; // 10MB in bytes
  
  static bool isValidFormat(String path) {
    final ext = path.toLowerCase().split('.').last;
    return supportedFormats.contains(ext);
  }

  static String getFileExtension(String path) {
    return path.toLowerCase().split('.').last;
  }

  static bool checkImageFormat(XFile image) {
    final ext = getFileExtension(image.path);
    return supportedFormats.contains(ext);
  }

  static Future<bool> isValidFileSize(XFile file) async {
    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      return bytes.length <= maxFileSizeInBytes;
    } else {
      final fileSize = await File(file.path).length();
      return fileSize <= maxFileSizeInBytes;
    }
  }

  static Future<List<dynamic>> filterValidImages(List<XFile> pickedImages) async {
    final validImages = <dynamic>[];
    final invalidFormats = <String>{};
    final List<String> oversizedFiles = [];

    for (final image in pickedImages) {
      final ext = getFileExtension(image.path);
      
      if (!supportedFormats.contains(ext)) {
        invalidFormats.add(ext.toUpperCase());
        continue;
      }

      // Check file size
      if (!await isValidFileSize(image)) {
        oversizedFiles.add(image.name);
        continue;
      }

      if (kIsWeb) {
        validImages.add(image);
      } else {
        validImages.add(File(image.path));
      }
    }

    String? errorMessage;
    if (invalidFormats.isNotEmpty || oversizedFiles.isNotEmpty) {
      final List<String> errors = [];
      if (invalidFormats.isNotEmpty) {
        errors.add('Unsupported format${invalidFormats.length > 1 ? 's' : ''}: ${invalidFormats.join(', ')}');
      }
      if (oversizedFiles.isNotEmpty) {
        errors.add('Files exceeding 10MB: ${oversizedFiles.join(', ')}');
      }
      errorMessage = errors.join('\n');
    }

    return [validImages, errorMessage];
  }

  static String get supportedFormatsText => 
    'Supported formats: ${supportedFormats.map((e) => e.toUpperCase()).join(', ')}\nMaximum file size: 10MB';
} 