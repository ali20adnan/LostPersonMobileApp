import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../app/services/media_storage_service.dart';
import '../../app/services/location_service.dart';
import '../../app/services/storage_service.dart';
import '../models/incident_model.dart';

/// Repository for managing incident operations
class IncidentRepository {
  final StorageService _storageService;
  final MediaStorageService _mediaStorageService;
  final LocationService _locationService;

  IncidentRepository({
    required StorageService storageService,
    required MediaStorageService mediaStorageService,
    required LocationService locationService,
  })  : _storageService = storageService,
        _mediaStorageService = mediaStorageService,
        _locationService = locationService;

  /// Create a new incident
  Future<bool> createIncident({
    required String type,
    required String title,
    required String description,
    required String locationName,
    required String severity,
    required String reporterId,
    required String reporterName,
    double? latitude,
    double? longitude,
    List<XFile>? mediaFiles,
  }) async {
    try {
      debugPrint('IncidentRepository: Creating incident...');

      // Generate incident ID
      final incidentId = const Uuid().v4();

      // Save media files if provided
      List<String> savedMediaPaths = [];
      if (mediaFiles != null && mediaFiles.isNotEmpty) {
        debugPrint(
            'IncidentRepository: Saving ${mediaFiles.length} media files');
        savedMediaPaths =
            await _mediaStorageService.saveMediaFiles(mediaFiles, incidentId);
        debugPrint(
            'IncidentRepository: Saved ${savedMediaPaths.length} media files');
      }

      // Create incident model
      final incident = Incident(
        id: incidentId,
        type: type,
        title: title,
        description: description,
        locationName: locationName,
        latitude: latitude,
        longitude: longitude,
        severity: severity,
        status: 'pending',
        reporterId: reporterId,
        reporterName: reporterName,
        mediaFilePaths: savedMediaPaths,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save to database
      await _storageService.saveIncident(incident);

      debugPrint('IncidentRepository: Incident created successfully - $incidentId');
      return true;
    } catch (e) {
      debugPrint('IncidentRepository: Error creating incident - $e');
      return false;
    }
  }

  /// Get all incidents with optional filters
  Future<List<Incident>> getIncidents({
    String? filterStatus,
    String? filterType,
  }) async {
    try {
      return await _storageService.getAllIncidents(
        status: filterStatus,
        type: filterType,
      );
    } catch (e) {
      debugPrint('IncidentRepository: Error getting incidents - $e');
      return [];
    }
  }

  /// Get incident by ID
  Future<Incident?> getIncident(String id) async {
    try {
      return await _storageService.getIncident(id);
    } catch (e) {
      debugPrint('IncidentRepository: Error getting incident - $e');
      return null;
    }
  }

  /// Update incident
  Future<bool> updateIncident(Incident incident) async {
    try {
      await _storageService.updateIncident(incident);
      return true;
    } catch (e) {
      debugPrint('IncidentRepository: Error updating incident - $e');
      return false;
    }
  }

  /// Update incident status
  Future<bool> updateIncidentStatus(String id, String status) async {
    try {
      await _storageService.updateIncidentStatus(id, status);
      return true;
    } catch (e) {
      debugPrint('IncidentRepository: Error updating incident status - $e');
      return false;
    }
  }

  /// Mark incident as resolved
  Future<bool> resolveIncident(String id) async {
    return await updateIncidentStatus(id, 'resolved');
  }

  /// Assign incident to staff member
  Future<bool> assignIncident(
      String incidentId, String staffId, String staffName) async {
    try {
      final incident = await getIncident(incidentId);
      if (incident == null) return false;

      final updatedIncident = incident.copyWith(
        assignedToId: staffId,
        assignedToName: staffName,
        status: 'inProgress',
        updatedAt: DateTime.now(),
      );

      return await updateIncident(updatedIncident);
    } catch (e) {
      debugPrint('IncidentRepository: Error assigning incident - $e');
      return false;
    }
  }

  /// Delete incident and its media files
  Future<bool> deleteIncident(String id) async {
    try {
      // Get incident to find media files
      final incident = await getIncident(id);
      if (incident != null && incident.mediaFilePaths.isNotEmpty) {
        // Delete media files
        await _mediaStorageService.deleteMediaFiles(incident.mediaFilePaths);
      }

      // Delete from database
      await _storageService.deleteIncident(id);
      return true;
    } catch (e) {
      debugPrint('IncidentRepository: Error deleting incident - $e');
      return false;
    }
  }

  /// Get current location
  Future<Map<String, double>?> getCurrentLocation() async {
    try {
      final position = await _locationService.getCurrentLocation();
      if (position == null) return null;

      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
      };
    } catch (e) {
      debugPrint('IncidentRepository: Error getting location - $e');
      return null;
    }
  }

  /// Format location coordinates
  String formatLocation(double latitude, double longitude) {
    return _locationService.formatCoordinates(latitude, longitude);
  }

  /// Get incidents by status
  Future<List<Incident>> getIncidentsByStatus(String status) async {
    return await getIncidents(filterStatus: status);
  }

  /// Get incidents by type
  Future<List<Incident>> getIncidentsByType(String type) async {
    return await getIncidents(filterType: type);
  }

  /// Get pending incidents count
  Future<int> getPendingIncidentsCount() async {
    final incidents = await getIncidentsByStatus('pending');
    return incidents.length;
  }

  /// Get critical incidents (high priority + pending/in progress)
  Future<List<Incident>> getCriticalIncidents() async {
    final allIncidents = await getIncidents();
    return allIncidents
        .where((incident) =>
            incident.severity == 'critical' &&
            (incident.status == 'pending' || incident.status == 'inProgress'))
        .toList();
  }
}
