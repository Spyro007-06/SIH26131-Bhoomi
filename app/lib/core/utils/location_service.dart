import 'dart:async';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/farm_models.dart';

/// Lifecycle statuses for device GPS location acquisition.
enum LocationServiceStatus {
  idle,
  requesting,
  acquired,
  denied,
  deniedForever,
  disabled,
  timeout,
  error,
}

/// Result object holding acquired GPS coordinates and resolution status.
class LocationResult {
  final GeoPoint? location;
  final LocationServiceStatus status;
  final String? errorMessage;

  const LocationResult({
    this.location,
    required this.status,
    this.errorMessage,
  });

  bool get isSuccess => status == LocationServiceStatus.acquired && location != null;
  bool get isDenied => status == LocationServiceStatus.denied || status == LocationServiceStatus.deniedForever;
  bool get isDeniedForever => status == LocationServiceStatus.deniedForever;
  bool get isDisabled => status == LocationServiceStatus.disabled;
  bool get isTimeout => status == LocationServiceStatus.timeout;
}

/// Abstract wrapper around Geolocator to allow test injection without native platform channel failures.
abstract class GeolocatorWrapper {
  Future<bool> isLocationServiceEnabled();
  Future<LocationPermission> checkPermission();
  Future<LocationPermission> requestPermission();
  Future<Position> getCurrentPosition({
    LocationAccuracy desiredAccuracy = LocationAccuracy.medium,
    Duration? timeLimit,
  });
  Future<bool> openAppSettings();
  Future<bool> openLocationSettings();
}

/// Default implementation delegating directly to the native Geolocator plugin.
class DefaultGeolocatorWrapper implements GeolocatorWrapper {
  const DefaultGeolocatorWrapper();

  @override
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled().timeout(
        const Duration(seconds: 3),
        onTimeout: () => false,
      );
    } catch (_) {
      return false;
    }
  }

  @override
  Future<LocationPermission> checkPermission() async {
    try {
      return await Geolocator.checkPermission().timeout(
        const Duration(seconds: 3),
        onTimeout: () => LocationPermission.denied,
      );
    } catch (_) {
      return LocationPermission.denied;
    }
  }

  @override
  Future<LocationPermission> requestPermission() async {
    try {
      return await Geolocator.requestPermission().timeout(
        const Duration(seconds: 3),
        onTimeout: () => LocationPermission.denied,
      );
    } catch (_) {
      return LocationPermission.denied;
    }
  }

  @override
  Future<Position> getCurrentPosition({
    LocationAccuracy desiredAccuracy = LocationAccuracy.medium,
    Duration? timeLimit,
  }) async {
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: desiredAccuracy,
      timeLimit: timeLimit ?? const Duration(seconds: 10),
    );
  }

  @override
  Future<bool> openAppSettings() async {
    try {
      return await Geolocator.openAppSettings();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (_) {
      return false;
    }
  }
}

/// Device GPS Location Service.
/// Handles permission requests, service checks, and real coordinates acquisition using Geolocator.
class LocationService {
  final GeolocatorWrapper _geolocator;

  LocationService({GeolocatorWrapper? geolocatorWrapper})
      : _geolocator = geolocatorWrapper ?? const DefaultGeolocatorWrapper();

  /// Acquire real device GPS coordinates.
  /// 1. Verifies if location services are enabled on device.
  /// 2. Requests/checks runtime location permissions.
  /// 3. Obtains high-accuracy farm coordinates with battery-efficient medium accuracy setting.
  Future<LocationResult> getCurrentLocation({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      // 1. Check if location services (GPS) are enabled
      final isServiceEnabled = await _geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) {
        return const LocationResult(
          status: LocationServiceStatus.disabled,
          errorMessage: 'Location services are disabled on your device.',
        );
      }

      // 2. Check current location permission status
      var permission = await _geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        // Request permission if not yet determined/denied once
        permission = await _geolocator.requestPermission();
      }

      // 3. Handle permission outcomes
      if (permission == LocationPermission.denied) {
        return const LocationResult(
          status: LocationServiceStatus.denied,
          errorMessage: 'Location permission denied by user.',
        );
      }

      if (permission == LocationPermission.deniedForever) {
        return const LocationResult(
          status: LocationServiceStatus.deniedForever,
          errorMessage: 'Location permission permanently denied. Please enable in App Settings.',
        );
      }

      // 4. Permission granted: acquire real device position
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        final position = await _geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: timeout,
        );

        return LocationResult(
          location: GeoPoint(
            lat: position.latitude,
            lng: position.longitude,
          ),
          status: LocationServiceStatus.acquired,
        );
      }

      return const LocationResult(
        status: LocationServiceStatus.error,
        errorMessage: 'Unable to determine location permission status.',
      );
    } on TimeoutException {
      return const LocationResult(
        status: LocationServiceStatus.timeout,
        errorMessage: 'GPS location request timed out.',
      );
    } on MissingPluginException {
      return const LocationResult(
        status: LocationServiceStatus.disabled,
        errorMessage: 'Location services are unavailable on this platform.',
      );
    } on PlatformException catch (e) {
      return LocationResult(
        status: LocationServiceStatus.error,
        errorMessage: e.message ?? e.toString(),
      );
    } catch (e) {
      if (e is TimeoutException || e.toString().toLowerCase().contains('timeout')) {
        return const LocationResult(
          status: LocationServiceStatus.timeout,
          errorMessage: 'GPS location request timed out.',
        );
      }
      return LocationResult(
        status: LocationServiceStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Open device App Settings so user can grant permanently denied permissions.
  Future<bool> openAppSettings() => _geolocator.openAppSettings();

  /// Open device Location/GPS Settings so user can enable disabled location services.
  Future<bool> openLocationSettings() => _geolocator.openLocationSettings();
}
