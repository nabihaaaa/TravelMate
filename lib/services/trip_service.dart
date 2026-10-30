// SHARED DATA HOLDER (temporary, in memory, with sample data).
// Person 4 (SR): replace the insides with real storage, but KEEP these
// method/field names so everyone else's code keeps working.
//
// Everyone else: use TripService.instance, e.g.
//   final trips = TripService.instance.trips;
//   TripService.instance.itineraryFor(trip.id);

import '../models/expense.dart';
import '../models/itinerary_item.dart';
import '../models/packing_item.dart';
import '../models/place.dart';
import '../models/trip.dart';

class TripService {
  TripService._(); // private constructor: nobody else can create one
  static final TripService instance = TripService._();

  // ---- sample data so every screen has something to show ----
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

  // ---- per-trip lookups ----
  List<ItineraryItem> itineraryFor(int tripId) =>
      itinerary.where((i) => i.tripId == tripId).toList();

  List<PackingItem> packingFor(int tripId) =>
      packing.where((i) => i.tripId == tripId).toList();

  List<Expense> expensesFor(int tripId) =>
      expenses.where((e) => e.tripId == tripId).toList();

  List<Place> placesFor(int tripId) =>
      places.where((p) => p.tripId == tripId).toList();

  // ---- ids: next free id for a list of models ----
  int nextTripId() => trips.isEmpty ? 1 : trips.last.id + 1;
  int nextItineraryId() => itinerary.isEmpty ? 1 : itinerary.last.id + 1;
  int nextPackingId() => packing.isEmpty ? 1 : packing.last.id + 1;
  int nextExpenseId() => expenses.isEmpty ? 1 : expenses.last.id + 1;
  int nextPlaceId() => places.isEmpty ? 1 : places.last.id + 1;

  // ---- basic trip operations (Person 4 will make these persistent) ----
  void addTrip(Trip trip) => trips.add(trip);

  void deleteTrip(int tripId) {
    trips.removeWhere((t) => t.id == tripId);
    itinerary.removeWhere((i) => i.tripId == tripId);
    packing.removeWhere((i) => i.tripId == tripId);
    expenses.removeWhere((e) => e.tripId == tripId);
    places.removeWhere((p) => p.tripId == tripId);
  }
}
