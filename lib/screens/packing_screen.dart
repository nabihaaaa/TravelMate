// OWNER: Person 5 (M). Placeholder: replace the body with the real screen.
// Keep the class name and the constructor so routes.dart keeps working.

import 'package:flutter/material.dart';

import '../models/trip.dart';
import '../widgets/placeholder_screen.dart';

class PackingScreen extends StatelessWidget {
  const PackingScreen({super.key, required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      title: 'Packing List',
      owner: 'Person 5 (M)',
      subtitle: trip.name,
    );
  }
}
