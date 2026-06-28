import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Service for storing incident media files (photos/videos)
class MediaStorageService {
  /// Initialize service - create directories if needed
  Future<void> init() async {
    try {
      final mediaDir = await _getMediaDirectory();
      if (!await mediaDir.exists()) {
        await mediaDir.create(recursive: true);
        debugPrint(
            'MediaStorageService: Created media directory at ${mediaDir.path}');
      }
    } catch (e) {
      debugPrint('MediaStorageService: Error initializing - $e');
    }
  }

  /// Get media storage directory for today
  Future<Directory> _getMediaDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final today = DateTime.now();
    final dateFolder =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return Directory(path.join(appDir.path, 'media', 'incidents', dateFolder));
  }

  /// Save media file from XFile (picked from gallery or camera)
  /// Returns the absolute path where the file was saved, or null if failed
  Future<String?> saveMediaFile(XFile file, String incidentId) async {
    try {
      debugPrint('MediaStorageService: Saving media file for incident $incidentId');

      // Get media directory
      final mediaDir = await _getMediaDirectory();
      if (!await mediaDir.exists()) {
        await mediaDir.create(recursive: true);
      }

      // Get file extension
      final extension = path.extension(file.path);
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Create filename: <incident_id>_<timestamp>.<ext>
      final filename = '${incidentId}_$timestamp$extension';
      final filePath = path.join(mediaDir.path, filename);

      // Copy file to destination
      final sourceFile = File(file.path);
      await sourceFile.copy(filePath);

      debugPrint('MediaStorageService: Saved media file to $filePath');
      return filePath;
    } catch (e) {
      debugPrint('MediaStorageService: Error saving media file - $e');
      return null;
    }
  }

  /// Save multiple media files
  /// Returns list of saved file paths (null entries are skipped for failed saves)
  Future<List<String>> saveMediaFiles(
      List<XFile> files, String incidentId) async {
    final savedPaths = <String>[];

    for (var file in files) {
      final savedPath = await saveMediaFile(file, incidentId);
      if (savedPath != null) {
        savedPaths.add(savedPath);
      }
    }

    debugPrint(
        'MediaStorageService: Saved ${savedPaths.length}/${files.length} media files');
    return savedPaths;
  }

  /// Delete media file
  Future<bool> deleteMediaFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('MediaStorageService: Deleted file $filePath');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('MediaStorageService: Error deleting file - $e');
      return false;
    }
  }

  /// Delete multiple media files
  Future<void> deleteMediaFiles(List<String> filePaths) async {
    for (var filePath in filePaths) {
      await deleteMediaFile(filePath);
    }
  }

  /// Check if file exists
  Future<bool> fileExists(String filePath) async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      debugPrint('MediaStorageService: Error checking file existence - $e');
      return false;
    }
  }

  /// Get file size in bytes
  Future<int?> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
      return null;
    } catch (e) {
      debugPrint('MediaStorageService: Error getting file size - $e');
      return null;
    }
  }

  /// Check disk space before saving (returns available space in bytes)
  Future<int?> getAvailableSpace() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final stat = await appDir.stat();
      // Note: This is a simplified check; actual implementation may vary by platform
      return stat.size;
    } catch (e) {
      debugPrint('MediaStorageService: Error checking available space - $e');
      return null;
    }
  }

  /// Validate file size (max 50MB)
  Future<bool> validateFileSize(String filePath,
      {int maxSizeMB = 50}) async {
    final fileSize = await getFileSize(filePath);
    if (fileSize == null) return false;

    final maxSizeBytes = maxSizeMB * 1024 * 1024;
    return fileSize <= maxSizeBytes;
  }

  /// Get all media files in directory
  Future<List<String>> getAllMediaFiles() async {
    try {
      final mediaBaseDir = await getApplicationDocumentsDirectory();
      final incidentsDir =
          Directory(path.join(mediaBaseDir.path, 'media', 'incidents'));

      if (!await incidentsDir.exists()) {
        return [];
      }

      final files = <String>[];
      await for (var entity
          in incidentsDir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          files.add(entity.path);
        }
      }

      return files;
    } catch (e) {
      debugPrint('MediaStorageService: Error listing media files - $e');
      return [];
    }
  }

  /// Cleanup orphaned media files (files not referenced in database)
  /// This should be called periodically or during app startup
  Future<void> cleanupOrphanedFiles(List<String> referencedPaths) async {
    try {
      final allFiles = await getAllMediaFiles();
      final orphanedFiles =
          allFiles.where((file) => !referencedPaths.contains(file)).toList();

      debugPrint(
          'MediaStorageService: Found ${orphanedFiles.length} orphaned files');

      for (var filePath in orphanedFiles) {
        await deleteMediaFile(filePath);
      }

      debugPrint('MediaStorageService: Cleanup completed');
    } catch (e) {
      debugPrint('MediaStorageService: Error during cleanup - $e');
    }
  }
}
