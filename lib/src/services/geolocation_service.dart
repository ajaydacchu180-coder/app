import 'dart:async';
import 'package:geolocator/geolocator.dart';

/// GeolocationService provides GPS tracking and geofencing capabilities.
///
/// This addresses the Project Manager's requirements for:
/// - Smart Geofencing for auto clock-in/out
/// - Route tracking for field employees
/// - Location verification with anti-spoofing
/// - Multi-site support
class GeolocationService {
  StreamSubscription<Position>? _positionSubscription;
  final List<GeofenceZone> _geofenceZones = [];
  final Map<String, bool> _zoneStatus = {}; // Track if user is inside each zone

  // Callbacks for geofence events
  Function(GeofenceZone zone, GeofenceEvent event)? onGeofenceEvent;
  Function(Position position)? onLocationUpdate;

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Request location permissions
  Future<LocationPermission> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission;
  }

  /// Check current permission status
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Get current position
  Future<Position?> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
  }) async {
    try {
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      final permission = await checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: accuracy,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      return null;
    }
  }

  /// Start continuous location tracking
  Future<bool> startLocationTracking({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10, // meters
  }) async {
    try {
      final permission = await requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return false;
      }

      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: accuracy,
          distanceFilter: distanceFilter,
        ),
      ).listen((Position position) {
        onLocationUpdate?.call(position);
        _checkGeofences(position);
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Stop location tracking
  void stopLocationTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  /// Add a geofence zone
  void addGeofenceZone(GeofenceZone zone) {
    _geofenceZones.add(zone);
    _zoneStatus[zone.id] = false;
  }

  /// Remove a geofence zone
  void removeGeofenceZone(String zoneId) {
    _geofenceZones.removeWhere((z) => z.id == zoneId);
    _zoneStatus.remove(zoneId);
  }

  /// Clear all geofence zones
  void clearGeofenceZones() {
    _geofenceZones.clear();
    _zoneStatus.clear();
  }

  /// Get all configured geofence zones
  List<GeofenceZone> getGeofenceZones() => List.unmodifiable(_geofenceZones);

  /// Check if position is inside any geofence and trigger events
  void _checkGeofences(Position position) {
    for (final zone in _geofenceZones) {
      final isInside = _isInsideGeofence(position, zone);
      final wasInside = _zoneStatus[zone.id] ?? false;

      if (isInside && !wasInside) {
        // Entered zone
        _zoneStatus[zone.id] = true;
        onGeofenceEvent?.call(zone, GeofenceEvent.enter);
      } else if (!isInside && wasInside) {
        // Exited zone
        _zoneStatus[zone.id] = false;
        onGeofenceEvent?.call(zone, GeofenceEvent.exit);
      }
    }
  }

  /// Check if a position is inside a geofence zone
  bool _isInsideGeofence(Position position, GeofenceZone zone) {
    final distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      zone.latitude,
      zone.longitude,
    );
    return distance <= zone.radiusMeters;
  }

  /// Calculate distance between two points in meters
  double calculateDistance({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  /// Get distance to a specific geofence zone
  Future<double?> getDistanceToZone(String zoneId) async {
    final position = await getCurrentPosition();
    if (position == null) return null;

    final zone = _geofenceZones.firstWhere(
      (z) => z.id == zoneId,
      orElse: () => throw Exception('Zone not found'),
    );

    return calculateDistance(
      startLat: position.latitude,
      startLng: position.longitude,
      endLat: zone.latitude,
      endLng: zone.longitude,
    );
  }

  /// Verify if user is at expected location (anti-spoofing check)
  Future<LocationVerificationResult> verifyLocation({
    required double expectedLat,
    required double expectedLng,
    double toleranceMeters = 100,
  }) async {
    final position = await getCurrentPosition(accuracy: LocationAccuracy.best);

    if (position == null) {
      return LocationVerificationResult(
        verified: false,
        reason: 'Could not get current location',
      );
    }

    // Check accuracy - suspicious if too accurate (might be spoofed)
    if (position.accuracy > 500) {
      return LocationVerificationResult(
        verified: false,
        reason: 'Location accuracy too low',
        position: position,
      );
    }

    final distance = calculateDistance(
      startLat: position.latitude,
      startLng: position.longitude,
      endLat: expectedLat,
      endLng: expectedLng,
    );

    if (distance <= toleranceMeters) {
      return LocationVerificationResult(
        verified: true,
        reason: 'Location verified',
        position: position,
        distanceFromExpected: distance,
      );
    } else {
      return LocationVerificationResult(
        verified: false,
        reason: 'Location outside expected area',
        position: position,
        distanceFromExpected: distance,
      );
    }
  }

  /// Generate route tracking data for field employees
  Future<RoutePoint> recordRoutePoint({String? note}) async {
    final position = await getCurrentPosition();
    return RoutePoint(
      latitude: position?.latitude ?? 0,
      longitude: position?.longitude ?? 0,
      timestamp: DateTime.now().toUtc(),
      accuracy: position?.accuracy ?? 0,
      note: note,
    );
  }

  /// Calculate total distance from a list of route points (in km)
  double calculateRouteDistance(List<RoutePoint> points) {
    if (points.length < 2) return 0;

    double totalDistance = 0;
    for (int i = 1; i < points.length; i++) {
      totalDistance += calculateDistance(
        startLat: points[i - 1].latitude,
        startLng: points[i - 1].longitude,
        endLat: points[i].latitude,
        endLng: points[i].longitude,
      );
    }

    return totalDistance / 1000; // Convert to km
  }

  /// Dispose resources
  void dispose() {
    stopLocationTracking();
  }
}

/// Represents a geofence zone (e.g., office location)
class GeofenceZone {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final GeofenceZoneType type;
  final Map<String, dynamic>? metadata;

  GeofenceZone({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    this.type = GeofenceZoneType.office,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'radiusMeters': radiusMeters,
        'type': type.name,
        if (metadata != null) 'metadata': metadata,
      };
}

/// Types of geofence zones
enum GeofenceZoneType {
  office,
  clientSite,
  warehouse,
  restricted,
  custom,
}

/// Geofence events
enum GeofenceEvent {
  enter,
  exit,
  dwell, // Stayed inside for extended period
}

/// Result of location verification
class LocationVerificationResult {
  final bool verified;
  final String reason;
  final Position? position;
  final double? distanceFromExpected;

  LocationVerificationResult({
    required this.verified,
    required this.reason,
    this.position,
    this.distanceFromExpected,
  });
}

/// Route tracking point
class RoutePoint {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double accuracy;
  final String? note;

  RoutePoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.accuracy,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': timestamp.toIso8601String(),
        'accuracy': accuracy,
        if (note != null) 'note': note,
      };
}
