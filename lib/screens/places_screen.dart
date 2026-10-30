// OWNER: Person 6 (F). Placeholder: replace the body with the real screen.
// Keep the class name and the constructor so routes.dart keeps working.

import 'package:flutter/material.dart';

import '../models/trip.dart';
import '../widgets/placeholder_screen.dart';

class PlacesScreen extends StatelessWidget {
  const PlacesScreen({super.key, required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      title: 'Places & Map',
      owner: 'Person 6 (F)',
      subtitle: trip.name,
    );
  }
}
