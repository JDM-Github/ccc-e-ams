// location_controller.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ccc_ojt_schedule/components/snackbar.dart';
import 'package:ccc_ojt_schedule/handle_request.dart';
import 'package:ccc_ojt_schedule/store/login_store.dart';

class LocationController extends ChangeNotifier {
  final LoginStore loginStore;
  final RequestHandler requestHandler = RequestHandler();

  late double targetLatitude;
  late double targetLongitude;
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isLoading = true;
  bool _isSettingLocation = false;
  bool _isConfirming = false;

  LocationController({required this.loginStore}) {
    targetLatitude = loginStore.user.value['latitude'] ?? 0.0;
    targetLongitude = loginStore.user.value['longitude'] ?? 0.0;
  }

  // Getters for UI
  Position? get currentPosition => _currentPosition;
  bool get isLoading => _isLoading;
  bool get isSettingLocation => _isSettingLocation;
  bool get isConfirming => _isConfirming;
  bool get isSupervisor => loginStore.user.value['role'] == 'supervisor' || loginStore.user.value['isAdmin'] == true;
  double get targetLat => targetLatitude;
  double get targetLng => targetLongitude;

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  // --- Permission & Location Stream ------------------------------------------
  Future<bool> _ensureLocationPermission(BuildContext context) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (context.mounted) AppSnackBar.error(context, 'Location services are disabled.');
      return false;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (context.mounted) AppSnackBar.warning(context, 'Location permission denied.');
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      if (context.mounted) {
        AppSnackBar.error(context, 'Location permission permanently denied. Enable it in settings.');
        await Geolocator.openAppSettings();
      }
      return false;
    }
    return true;
  }

  Future<void> initializeLocation(BuildContext context) async {
    final hasPermission = await _ensureLocationPermission(context);
    if (hasPermission) {
      await _getCurrentLocation();
      _startLocationStream();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _getCurrentLocation() async {
    try {
      const locationSettings = LocationSettings(accuracy: LocationAccuracy.high);
      final position = await Geolocator.getCurrentPosition(locationSettings: locationSettings);
      _currentPosition = position;
      notifyListeners();
    } catch (e) {
      // ignore: use_build_context_synchronously
    }
  }

  void _startLocationStream() {
    _positionStreamSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 0),
        ).listen((position) {
          _currentPosition = position;
          notifyListeners();
        });
  }

  Future<void> refreshLocation(BuildContext context) async {
    _isLoading = true;
    notifyListeners();
    final hasPermission = await _ensureLocationPermission(context);
    if (hasPermission) {
      await _getCurrentLocation();
    }
    _isLoading = false;
    notifyListeners();
  }

  // --- Distance Calculation --------------------------------------------------
  double _degToRad(double deg) => deg * (pi / 180);

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000;
    double dLat = _degToRad(lat2 - lat1);
    double dLon = _degToRad(lon2 - lon1);
    double a =
        (sin(dLat / 2) * sin(dLat / 2)) + cos(_degToRad(lat1)) * cos(_degToRad(lat2)) * (sin(dLon / 2) * sin(dLon / 2));
    return earthRadius * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  bool isInOffice({double radiusInMeters = 40}) {
    if (_currentPosition == null) return false;
    return _calculateDistance(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          targetLatitude,
          targetLongitude,
        ) <=
        radiusInMeters;
  }

  double? getDistanceToTarget() {
    if (_currentPosition == null) return null;
    return _calculateDistance(_currentPosition!.latitude, _currentPosition!.longitude, targetLatitude, targetLongitude);
  }

  String formatDistance(double meters) {
    if (meters < 1000) return '${meters.toStringAsFixed(1)} m';
    return '${(meters / 1000).toStringAsFixed(2)} km';
  }

  // --- Set Office Location ---------------------------------------------------
  void enterSetLocationMode() {
    if (_currentPosition == null) {
      // Error will be shown via snackbar in UI
      return;
    }
    _isSettingLocation = true;
    notifyListeners();
  }

  void cancelSetLocation() {
    _isSettingLocation = false;
    notifyListeners();
  }

  Future<void> confirmSetLocation(BuildContext context) async {
    if (_currentPosition == null) {
      if (context.mounted) AppSnackBar.error(context, 'No GPS signal. Cannot set location.');
      return;
    }

    _isConfirming = true;
    notifyListeners();

    try {
      final cccId = loginStore.user.value['ccc_id'];
      final response = await requestHandler.handleRequest(
        'user/set-location',
        method: 'POST',
        body: {'ccc_id': cccId, 'latitude': _currentPosition!.latitude, 'longitude': _currentPosition!.longitude},
      );

      if (response['success'] == true) {
        targetLatitude = _currentPosition!.latitude;
        targetLongitude = _currentPosition!.longitude;
        _isSettingLocation = false;

        final updatedUser = Map<String, dynamic>.from(loginStore.user.value);
        updatedUser['latitude'] = targetLatitude;
        updatedUser['longitude'] = targetLongitude;
        loginStore.user.value = updatedUser;

        if (context.mounted) AppSnackBar.success(context, 'Office location updated successfully.');
      } else {
        if (context.mounted) AppSnackBar.error(context, response['message'] ?? 'Failed to update office location.');
      }
    } catch (e) {
      if (context.mounted) AppSnackBar.error(context, 'Network error: $e');
    } finally {
      _isConfirming = false;
      notifyListeners();
    }
  }
}
