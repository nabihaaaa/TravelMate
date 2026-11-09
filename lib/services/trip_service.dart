// SHARED DATA HOLDER (temporary, in memory, with sample data).
// Person 4 (SR): replace the insides with real storage, but KEEP these
// method/field names so everyone else's code keeps working.
//
// Everyone else: use TripService.instance, e.g.
//   final trips = TripService.instance.trips;
//   TripService.instance.itineraryFor(trip.id);

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/expense.dart';
import '../models/itinerary_item.dart';
import '../models/packing_item.dart';
import '../models/place.dart';
import '../models/trip.dart';

class TripService {
  TripService._();

  static final TripService instance = TripService._();

  static const String _tripsKey = 'saved_trips';
  static const String _itineraryKey = 'saved_itinerary';
  static const String _packingKey = 'saved_packing';
  static const String _expensesKey = 'saved_expenses';
  static const String _placesKey = 'saved_places';

  static const String _contactsKey = 'trusted_contacts';
  static const String _safetyNotesKey = 'safety_notes';
  static const String _emergencyInfoKey = 'emergency_info';
  static const String _checkInTimesKey = 'check_in_times';
  static const String _checkInEnabledKey = 'check_in_enabled';

  // Load saved trips.
  Future<void> loadTrips() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString(_tripsKey);

    if (savedData == null) return;

    try {
      final List<dynamic> decoded = jsonDecode(savedData);

      final loadedTrips = decoded.map((item) {
        return Trip.fromMap(Map<String, dynamic>.from(item as Map));
      }).toList();

      trips
        ..clear()
        ..addAll(loadedTrips);
    } catch (error) {
      throw FormatException('Unable to load saved trips: $error');
    }
  }

  // Save trips.
  Future<void> saveTrips() async {
    final prefs = await SharedPreferences.getInstance();

    final encodedTrips = jsonEncode(trips.map((trip) => trip.toMap()).toList());

    final saved = await prefs.setString(_tripsKey, encodedTrips);

    if (!saved) {
      throw StateError('Unable to save trips');
    }
  }

  // Save all application data.
  Future<void> saveAllData() async {
    final prefs = await SharedPreferences.getInstance();

    await saveTrips();

    await prefs.setString(
      _itineraryKey,
      jsonEncode(itinerary.map((item) => item.toMap()).toList()),
    );

    await prefs.setString(
      _packingKey,
      jsonEncode(packing.map((item) => item.toMap()).toList()),
    );

    await prefs.setString(
      _expensesKey,
      jsonEncode(expenses.map((item) => item.toMap()).toList()),
    );

    await prefs.setString(
      _placesKey,
      jsonEncode(places.map((item) => item.toMap()).toList()),
    );

    await prefs.setString(_contactsKey, jsonEncode(trustedContacts));

    await prefs.setString(
      _safetyNotesKey,
      jsonEncode(
        safetyNotes.map((key, value) => MapEntry(key.toString(), value)),
      ),
    );

    await prefs.setString(
      _emergencyInfoKey,
      jsonEncode(
        emergencyInfo.map((key, value) => MapEntry(key.toString(), value)),
      ),
    );

    await prefs.setString(
      _checkInTimesKey,
      jsonEncode(
        checkInTimes.map((key, value) => MapEntry(key.toString(), value)),
      ),
    );

    await prefs.setString(
      _checkInEnabledKey,
      jsonEncode(checkInEnabled.toList()),
    );
  }

  // Load all application data.
  Future<void> loadAllData() async {
    final prefs = await SharedPreferences.getInstance();

    await loadTrips();

    final savedItinerary = prefs.getString(_itineraryKey);

    if (savedItinerary != null) {
      final List<dynamic> data = jsonDecode(savedItinerary);

      itinerary
        ..clear()
        ..addAll(
          data.map(
            (item) =>
                ItineraryItem.fromMap(Map<String, dynamic>.from(item as Map)),
          ),
        );
    }

    final savedPacking = prefs.getString(_packingKey);

    if (savedPacking != null) {
      final List<dynamic> data = jsonDecode(savedPacking);

      packing
        ..clear()
        ..addAll(
          data.map(
            (item) =>
                PackingItem.fromMap(Map<String, dynamic>.from(item as Map)),
          ),
        );
    }

    final savedExpenses = prefs.getString(_expensesKey);

    if (savedExpenses != null) {
      final List<dynamic> data = jsonDecode(savedExpenses);

      expenses
        ..clear()
        ..addAll(
          data.map(
            (item) => Expense.fromMap(Map<String, dynamic>.from(item as Map)),
          ),
        );
    }

    final savedPlaces = prefs.getString(_placesKey);

    if (savedPlaces != null) {
      final List<dynamic> data = jsonDecode(savedPlaces);

      places
        ..clear()
        ..addAll(
          data.map(
            (item) => Place.fromMap(Map<String, dynamic>.from(item as Map)),
          ),
        );
    }

    final savedContacts = prefs.getString(_contactsKey);

    if (savedContacts != null) {
      final List<dynamic> data = jsonDecode(savedContacts);

      trustedContacts
        ..clear()
        ..addAll(data.map((item) => Map<String, dynamic>.from(item as Map)));
    }

    final savedNotes = prefs.getString(_safetyNotesKey);

    if (savedNotes != null) {
      safetyNotes
        ..clear()
        ..addAll(
          (jsonDecode(savedNotes) as Map).map(
            (key, value) => MapEntry(int.parse(key), value.toString()),
          ),
        );
    }

    final savedEmergency = prefs.getString(_emergencyInfoKey);

    if (savedEmergency != null) {
      emergencyInfo
        ..clear()
        ..addAll(
          (jsonDecode(savedEmergency) as Map).map(
            (key, value) => MapEntry(int.parse(key), value.toString()),
          ),
        );
    }

    final savedTimes = prefs.getString(_checkInTimesKey);

    if (savedTimes != null) {
      checkInTimes
        ..clear()
        ..addAll(
          (jsonDecode(savedTimes) as Map).map(
            (key, value) => MapEntry(int.parse(key), value.toString()),
          ),
        );
    }

    final savedEnabled = prefs.getString(_checkInEnabledKey);

    if (savedEnabled != null) {
      checkInEnabled
        ..clear()
        ..addAll((jsonDecode(savedEnabled) as List).map((id) => id as int));
    }
  }

  // Update an existing trip.
  Future<void> updateTrip(Trip updatedTrip) async {
    final index = trips.indexWhere((trip) => trip.id == updatedTrip.id);

    if (index == -1) {
      throw StateError('Trip not found');
    }

    trips[index] = updatedTrip;
    await saveTrips();
  }

  // Sample trip data.
  final List<Trip> trips = [
    Trip(
      id: 1,
      name: 'Trip to Montreal',
      destination: 'Montréal, QC, Canada',
      startDate: DateTime(2026, 4, 12),
      endDate: DateTime(2026, 4, 18),
      notes: 'Train leaves Union Station at 10:15 AM.',
      budget: 1000,
    ),
    Trip(
      id: 2,
      name: 'Ottawa Weekend',
      destination: 'Ottawa, ON, Canada',
      startDate: DateTime(2026, 5, 22),
      endDate: DateTime(2026, 5, 24),
    ),
  ];

  final List<ItineraryItem> itinerary = [
    ItineraryItem(
      id: 1,
      tripId: 1,
      title: 'Arrive at YUL Airport',
      date: DateTime(2026, 4, 12),
      startTime: '2:00 PM',
      location: 'Montréal-Trudeau',
    ),
  ];

  final List<PackingItem> packing = [
    PackingItem(id: 1, tripId: 1, name: 'T-shirts', category: 'Clothing'),
    PackingItem(id: 2, tripId: 1, name: 'Toothbrush', category: 'Toiletries'),
    PackingItem(id: 3, tripId: 1, name: 'Passport', category: 'Documents'),
  ];

  final List<Expense> expenses = [
    Expense(
      id: 1,
      tripId: 1,
      title: 'Hotel',
      amount: 250,
      category: 'Accommodation',
      date: DateTime(2026, 4, 12),
    ),
  ];

  final List<Place> places = [
    Place(
      id: 1,
      tripId: 1,
      name: 'Mount Royal Park',
      address: 'Montréal, QC',
      latitude: 45.5048,
      longitude: -73.5878,
    ),
  ];

  // Safety information.
  final List<Map<String, dynamic>> trustedContacts = [];

  final Map<int, String> safetyNotes = {};

  final Map<int, String> emergencyInfo = {};

  final Map<int, String> checkInTimes = {};

  final Set<int> checkInEnabled = {};

  // Get contacts for a trip.
  List<Map<String, dynamic>> contactsFor(int tripId) {
    return trustedContacts
        .where((contact) => contact['tripId'] == tripId)
        .toList();
  }

  // Get next contact ID.
  int nextContactId() {
    if (trustedContacts.isEmpty) return 1;

    return trustedContacts.fold<int>(
          0,
          (maxId, contact) =>
              contact['id'] > maxId ? contact['id'] as int : maxId,
        ) +
        1;
  }

  // Per-trip lookups.
  List<ItineraryItem> itineraryFor(int tripId) =>
      itinerary.where((i) => i.tripId == tripId).toList();

  List<PackingItem> packingFor(int tripId) =>
      packing.where((i) => i.tripId == tripId).toList();

  List<Expense> expensesFor(int tripId) =>
      expenses.where((e) => e.tripId == tripId).toList();

  List<Place> placesFor(int tripId) =>
      places.where((p) => p.tripId == tripId).toList();

  // Next free IDs.
  int nextTripId() => trips.isEmpty ? 1 : trips.last.id + 1;

  int nextItineraryId() => itinerary.isEmpty ? 1 : itinerary.last.id + 1;

  int nextPackingId() => packing.isEmpty ? 1 : packing.last.id + 1;

  int nextExpenseId() => expenses.isEmpty ? 1 : expenses.last.id + 1;

  int nextPlaceId() => places.isEmpty ? 1 : places.last.id + 1;

  // Basic trip operations.
  Future<void> addTrip(Trip trip) async {
    trips.add(trip);
    await saveTrips();
  }

  Future<void> deleteTrip(int tripId) async {
    trips.removeWhere((trip) => trip.id == tripId);

    itinerary.removeWhere((item) => item.tripId == tripId);
    packing.removeWhere((item) => item.tripId == tripId);
    expenses.removeWhere((item) => item.tripId == tripId);
    places.removeWhere((item) => item.tripId == tripId);

    trustedContacts.removeWhere((contact) => contact['tripId'] == tripId);

    safetyNotes.remove(tripId);
    emergencyInfo.remove(tripId);
    checkInTimes.remove(tripId);
    checkInEnabled.remove(tripId);

    await saveAllData();
  }
}
