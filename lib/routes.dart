// All route names and the route table live HERE (owner: Person 3).
// To open a screen from anywhere:
//
//   Navigator.pushNamed(context, Routes.dashboard, arguments: trip);
//
// Trip screens need a Trip passed as `arguments`.
// createTrip takes an OPTIONAL Trip: null = create, a Trip = edit.

import 'package:flutter/material.dart';

import 'models/trip.dart';
import 'screens/create_trip_screen.dart';
import 'screens/expenses_screen.dart';
import 'screens/itinerary_screen.dart';
import 'screens/main_shell.dart';
import 'screens/packing_screen.dart';
import 'screens/places_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/trip_dashboard_screen.dart';

class Routes {
  static const String home = '/';
  static const String createTrip = '/create-trip'; // arguments: Trip? (edit)
  static const String dashboard = '/dashboard'; // arguments: Trip
  static const String itinerary = '/itinerary'; // arguments: Trip
  static const String packing = '/packing'; // arguments: Trip
  static const String expenses = '/expenses'; // arguments: Trip
  static const String places = '/places'; // arguments: Trip
  static const String settings = '/settings';

  static Route<dynamic> generate(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const MainShell());

      case createTrip:
        final Trip? trip = settings.arguments as Trip?;
        return MaterialPageRoute(builder: (_) => CreateTripScreen(trip: trip));

      case dashboard:
        return _tripRoute(settings, (Trip t) => TripDashboardScreen(trip: t));
      case itinerary:
        return _tripRoute(settings, (Trip t) => ItineraryScreen(trip: t));
      case packing:
        return _tripRoute(settings, (Trip t) => PackingScreen(trip: t));
      case expenses:
        return _tripRoute(settings, (Trip t) => ExpensesScreen(trip: t));
      case places:
        return _tripRoute(settings, (Trip t) => PlacesScreen(trip: t));

      case Routes.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());

      default:
        return MaterialPageRoute(builder: (_) => const MainShell());
    }
  }

  // Helper for routes that need a Trip in `arguments`.
  static Route<dynamic> _tripRoute(
    RouteSettings settings,
    Widget Function(Trip) build,
  ) {
    final Trip trip = settings.arguments as Trip;
    return MaterialPageRoute(builder: (_) => build(trip));
  }
}
