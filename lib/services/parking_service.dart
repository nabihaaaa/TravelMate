import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ParkingService {
  ParkingService._();

  static final ParkingService instance = ParkingService._();

  String _key(int tripId) => 'parking_location_$tripId';

  Future<void> save(int tripId, LatLng location) async {
    final prefs = await SharedPreferences.getInstance();

    final data = {
      'latitude': location.latitude,
      'longitude': location.longitude,
    };

    final saved = await prefs.setString(
      _key(tripId),
      jsonEncode(data),
    );

    if (!saved) {
      throw StateError('Could not save parking location.');
    }
  }

  Future<LatLng?> load(int tripId) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_key(tripId));

    if (stored == null) return null;

    final data = jsonDecode(stored) as Map<String, dynamic>;

    return LatLng(
      (data['latitude'] as num).toDouble(),
      (data['longitude'] as num).toDouble(),
    );
  }

  Future<void> delete(int tripId) async {
    final prefs = await SharedPreferences.getInstance();

    final deleted = await prefs.remove(_key(tripId));

    if (!deleted) {
      throw StateError('Could not delete parking location.');
    }
  }
}