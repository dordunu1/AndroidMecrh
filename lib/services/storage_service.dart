import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  Future<List<String>> uploadFiles(List<File> files, String path) async {
    try {
      final futures = files.map((file) => uploadFile(file, path));
      return await Future.wait(futures);
    } catch (e) {
      throw Exception('Failed to upload files: $e');
    }
  }

  Future<String> uploadFile(File file, String folder) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${_uuid.v4()}${p.extension(file.path)}';
      final ref = _storage.ref().child('$folder/$fileName');
      
      final uploadTask = await ref.putFile(file);
      if (uploadTask.state == TaskState.success) {
        return await ref.getDownloadURL();
      }
      
      throw Exception('Failed to upload file');
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  Future<void> deleteFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }

  Future<void> deleteFiles(List<String> urls) async {
    try {
      await Future.wait(
        urls.map((url) => deleteFile(url)),
      );
    } catch (e) {
      throw Exception('Failed to delete files: $e');
    }
  }

  Future<void> moveFile({
    required String sourceUrl,
    required String destinationPath,
  }) async {
    try {
      final sourceRef = _storage.refFromURL(sourceUrl);
      final extension = p.extension(sourceRef.name);
      final fileName = '${_uuid.v4()}$extension';
      final destinationRef = _storage.ref().child('$destinationPath/$fileName');

      final data = await sourceRef.getData();
      if (data == null) throw Exception('Failed to get file data');

      final metadata = SettableMetadata(
        contentType: _getContentType(extension),
      );

      await destinationRef.putData(data, metadata);
      await sourceRef.delete();
    } catch (e) {
      throw Exception('Failed to move file: $e');
    }
  }

  Future<void> copyFile({
    required String sourceUrl,
    required String destinationPath,
  }) async {
    try {
      final sourceRef = _storage.refFromURL(sourceUrl);
      final extension = p.extension(sourceRef.name);
      final fileName = '${_uuid.v4()}$extension';
      final destinationRef = _storage.ref().child('$destinationPath/$fileName');

      final data = await sourceRef.getData();
      if (data == null) throw Exception('Failed to get file data');

      final metadata = SettableMetadata(
        contentType: _getContentType(extension),
      );

      await destinationRef.putData(data, metadata);
    } catch (e) {
      throw Exception('Failed to copy file: $e');
    }
  }

  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.pdf':
        return 'application/pdf';
      case '.doc':
        return 'application/msword';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case '.xls':
        return 'application/vnd.ms-excel';
      case '.xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case '.ppt':
        return 'application/vnd.ms-powerpoint';
      case '.pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case '.txt':
        return 'text/plain';
      case '.csv':
        return 'text/csv';
      case '.json':
        return 'application/json';
      case '.xml':
        return 'application/xml';
      case '.zip':
        return 'application/zip';
      case '.rar':
        return 'application/x-rar-compressed';
      case '.7z':
        return 'application/x-7z-compressed';
      case '.mp3':
        return 'audio/mpeg';
      case '.wav':
        return 'audio/wav';
      case '.mp4':
        return 'video/mp4';
      case '.avi':
        return 'video/x-msvideo';
      case '.mov':
        return 'video/quicktime';
      case '.wmv':
        return 'video/x-ms-wmv';
      default:
        return 'application/octet-stream';
    }
  }
} 