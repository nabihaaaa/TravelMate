import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/trip.dart';
import '../services/parking_service.dart';

class ParkingScreen extends StatefulWidget {
  const ParkingScreen({super.key, required this.trip});

  final Trip trip;

  @override
  State<ParkingScreen> createState() => _ParkingScreenState();
}

class _ParkingScreenState extends State<ParkingScreen> {
  final ParkingService _parking = ParkingService.instance;

  GoogleMapController? _mapController;
  LatLng? _savedSpot;
  LatLng? _selectedSpot;

  bool _busy = false;
  bool _loading = true;

  static const LatLng _defaultCenter = LatLng(45.5019, -73.5674);

  @override
  void initState() {
    super.initState();
    _loadSpot();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadSpot() async {
    try {
      final spot = await _parking.load(widget.trip.id);

      if (!mounted) return;

      setState(() {
        _savedSpot = spot;
        _loading = false;
      });

      if (spot != null) {
        await _focus(spot);
      }
    } catch (_) {
      if (!mounted) return;

      setState(() => _loading = false);
      _message('Could not load your saved parking location.');
    }
  }

  void _message(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _focus(LatLng location) async {
    await _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(location, 17),
    );
  }

  Future<LatLng> _currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw StateError('Please enable GPS and try again.');
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw StateError('Location permission was denied.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw StateError(
        'Location permission is permanently denied. '
        'Please enable it in Android Settings.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );

    return LatLng(position.latitude, position.longitude);
  }

  String _errorMessage(Object error) {
    if (error is StateError) {
      return error.message.toString();
    }

    if (error is TimeoutException) {
      return 'GPS timed out. Try again or select a point on the map.';
    }

    return 'Something went wrong. Please try again.';
  }

  Future<void> _saveSpot(LatLng location) async {
    setState(() => _busy = true);

    try {
      await _parking.save(widget.trip.id, location);

      if (!mounted) return;

      setState(() {
        _savedSpot = location;
        _selectedSpot = null;
      });

      await _focus(location);
      _message('Parking location saved.');
    } catch (error) {
      _message(_errorMessage(error));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _saveCurrentLocation() async {
    setState(() => _busy = true);

    try {
      final location = await _currentPosition();

      if (!mounted) return;

      await _parking.save(widget.trip.id, location);

      if (!mounted) return;

      setState(() {
        _savedSpot = location;
        _selectedSpot = null;
      });

      await _focus(location);
      _message('Current location saved as your parking spot.');
    } catch (error) {
      _message(_errorMessage(error));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _deleteSpot() async {
    if (_savedSpot == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove parking pin?'),
        content: const Text(
          'Your saved parking location will be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);

    try {
      await _parking.delete(widget.trip.id);

      if (!mounted) return;

      setState(() {
        _savedSpot = null;
        _selectedSpot = null;
      });

      _message('Parking pin removed.');
    } catch (error) {
      _message(_errorMessage(error));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _openDirections() async {
    final spot = _savedSpot;
    if (spot == null) return;

    final uri = Uri.https(
      'www.google.com',
      '/maps/dir/',
      {
        'api': '1',
        'destination': '${spot.latitude},${spot.longitude}',
        'travelmode': 'walking',
      },
    );

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        _message('Could not open Google Maps directions.');
      }
    } catch (_) {
      _message('Could not open directions. Check your connection.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final markers = <Marker>{};

    if (_savedSpot != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('saved_parking'),
          position: _savedSpot!,
          infoWindow: const InfoWindow(title: 'Parked Car'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
      );
    }

    if (_selectedSpot != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('selected_parking'),
          position: _selectedSpot!,
          infoWindow: const InfoWindow(
            title: 'Selected Location (Not Saved)',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find My Parked Car'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _savedSpot ?? _defaultCenter,
                      zoom: _savedSpot == null ? 11 : 17,
                    ),
                    markers: markers,
                    onMapCreated: (controller) {
                      _mapController = controller;

                      if (_savedSpot != null) {
                        _focus(_savedSpot!);
                      }
                    },
                    onLongPress: _busy
                        ? null
                        : (point) {
                            setState(() => _selectedSpot = point);
                          },
                    zoomControlsEnabled: true,
                    myLocationButtonEnabled: false,
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _savedSpot == null
                              ? 'No parking location saved. '
                                'Hold a point on the map to select it.'
                              : 'Parking saved: '
                                '${_savedSpot!.latitude.toStringAsFixed(5)}, '
                                '${_savedSpot!.longitude.toStringAsFixed(5)}',
                        ),
                        const SizedBox(height: 10),
                        FilledButton.icon(
                          onPressed: _busy ? null : _saveCurrentLocation,
                          icon: const Icon(Icons.my_location),
                          label: const Text('Save My Current Location'),
                        ),
                        if (_selectedSpot != null)
                          OutlinedButton.icon(
                            onPressed: _busy
                                ? null
                                : () => _saveSpot(_selectedSpot!),
                            icon: const Icon(Icons.place),
                            label: const Text('Save Selected Map Point'),
                          ),
                        if (_savedSpot != null) ...[
                          OutlinedButton.icon(
                            onPressed: _busy ? null : _openDirections,
                            icon: const Icon(Icons.directions_walk),
                            label: const Text('Directions Back to Car'),
                          ),
                          TextButton.icon(
                            onPressed: _busy ? null : _deleteSpot,
                            icon: Icon(
                              Icons.delete_outline,
                              color: scheme.error,
                            ),
                            label: Text(
                              'Remove Parking Pin',
                              style: TextStyle(color: scheme.error),
                            ),
                          ),
                        ],
                        if (_busy)
                          const LinearProgressIndicator(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}