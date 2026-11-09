import 'package:flutter/material.dart';

import '../models/place.dart';
import '../models/trip.dart';
import '../services/trip_service.dart';

class PlacesScreen extends StatefulWidget {
  const PlacesScreen({super.key, required this.trip});

  final Trip trip;

  @override
  State<PlacesScreen> createState() => _PlacesScreenState();
}

class _PlacesScreenState extends State<PlacesScreen> {
  final TripService _service = TripService.instance;

  bool _saving = false;
  String _searchQuery = '';

  static const Color _pink = Color(0xFFC15E76);
  static const Color _darkPink = Color(0xFF91485D);
  static const Color _lightPink = Color(0xFFFFF0F1);
  static const Color _background = Color(0xFFFFF8F7);

  List<Place> get _places => _service.placesFor(widget.trip.id);

  List<Place> get _filteredPlaces {
    if (_searchQuery.isEmpty) return _places;

    return _places.where((place) {
      return place.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          place.address.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  Future<void> _addPlace() async {
    final formKey = GlobalKey<FormState>();
    String name = '';
    String address = '';

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add a Place'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Place name',
                  hintText: 'e.g. Eiffel Tower',
                  prefixIcon: Icon(Icons.place_outlined),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Please enter a place name'
                    : null,
                onSaved: (value) => name = value!.trim(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Address or location',
                  hintText: 'e.g. Paris, France',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Please enter a location'
                    : null,
                onSaved: (value) => address = value!.trim(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                Navigator.pop(dialogContext, {
                  'name': name,
                  'address': address,
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _pink,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save Place'),
          ),
        ],
      ),
    );

    if (!mounted || result == null) return;

    setState(() => _saving = true);

    final nextId =
        _service.places.fold<int>(
          0,
          (maxId, place) => place.id > maxId ? place.id : maxId,
        ) +
        1;

    final place = Place(
      id: nextId,
      tripId: widget.trip.id,
      name: result['name']!,
      address: result['address']!,
    );

    try {
      _service.places.add(place);
      await _service.saveAllData();

      if (!mounted) return;
      setState(() => _searchQuery = '');
      _showSnackBar('Place added to your trip!');
    } catch (error) {
      _service.places.remove(place);
      _showSnackBar('Could not save this place.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deletePlace(Place place) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove this place?'),
        content: Text('Remove "${place.name}" from your saved places?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _pink,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;

    setState(() => _saving = true);
    final index = _service.places.indexOf(place);

    try {
      _service.places.remove(place);
      await _service.saveAllData();

      if (!mounted) return;
      _showSnackBar('Place removed successfully.');
    } catch (error) {
      if (index >= 0 && !_service.places.contains(place)) {
        _service.places.insert(index, place);
      }
      _showSnackBar('Could not remove this place.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  IconData _iconForPlace(String name) {
    final value = name.toLowerCase();

    if (value.contains('hotel') || value.contains('inn')) {
      return Icons.hotel_outlined;
    }
    if (value.contains('restaurant') || value.contains('cafe')) {
      return Icons.restaurant_outlined;
    }
    if (value.contains('park')) {
      return Icons.park_outlined;
    }
    if (value.contains('airport')) {
      return Icons.flight_outlined;
    }

    return Icons.location_on_outlined;
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFF0E2E3)),
      ),
      child: TextField(
        onChanged: (value) {
          setState(() => _searchQuery = value);
        },
        decoration: const InputDecoration(
          hintText: 'Search for places...',
          prefixIcon: Icon(Icons.search, size: 20),
          border: InputBorder.none,
          hintStyle: TextStyle(fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildMapPreview() {
    return Container(
      height: 180,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFEDECE8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(width: 65, color: const Color(0xFFDCEBD3)),
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Container(width: 75, color: const Color(0xFFDCEBD3)),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 45,
            child: Container(height: 12, color: Colors.white),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 112,
            child: Container(height: 10, color: Colors.white),
          ),
          Positioned(
            left: 85,
            top: 0,
            bottom: 0,
            child: Container(width: 9, color: Colors.white),
          ),
          Positioned(
            right: 105,
            top: 0,
            bottom: 0,
            child: Container(width: 9, color: Colors.white),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 78,
            child: Container(height: 5, color: const Color(0xFFD7D5D0)),
          ),
          Positioned(
            left: 42,
            top: 30,
            child: Icon(Icons.location_on, size: 35, color: _pink),
          ),
          Positioned(
            left: 145,
            top: 78,
            child: Icon(Icons.location_on, size: 35, color: _pink),
          ),
          Positioned(
            right: 38,
            top: 48,
            child: Icon(Icons.location_on, size: 35, color: _pink),
          ),
          Positioned(
            bottom: 10,
            right: 12,
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.map_outlined, size: 18, color: _darkPink),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceCard(Place place) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFF0DCDD)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE5E8),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                _iconForPlace(place.name),
                color: _darkPink,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(
                        Icons.near_me_outlined,
                        size: 12,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          place.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Delete place',
              onPressed: _saving ? null : () => _deletePlace(place),
              icon: const Icon(Icons.more_vert, size: 21),
              color: Colors.black54,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final places = _filteredPlaces;

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Places & Map',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                children: [
                  _buildSearchBar(),
                  const SizedBox(height: 12),
                  _buildMapPreview(),
                  const SizedBox(height: 20),
                  const Text(
                    'Saved Places',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  if (places.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.bookmark_border, size: 38, color: _pink),
                          const SizedBox(height: 10),
                          Text(
                            _searchQuery.isEmpty
                                ? 'No saved places yet.'
                                : 'No places found.',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'Add a place to keep track of your destinations.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...places.map(_buildPlaceCard),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                color: _background,
                border: Border(top: BorderSide(color: Color(0xFFF0DCDD))),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _addPlace,
                  icon: const Icon(Icons.add, size: 19),
                  label: Text(_saving ? 'Saving...' : 'Add Place'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _darkPink,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
