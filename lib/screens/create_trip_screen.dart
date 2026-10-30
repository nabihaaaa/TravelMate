// OWNER: Person 2 (Se). Placeholder: replace with the Create/Edit Trip form.
// `trip == null` means CREATE; a Trip means EDIT.

import 'package:flutter/material.dart';

import '../models/trip.dart';
import '../widgets/placeholder_screen.dart';

class CreateTripScreen extends StatelessWidget {
  const CreateTripScreen({super.key, this.trip});

  final Trip? trip;

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      title: trip == null ? 'Create Trip' : 'Edit Trip',
      owner: 'Person 2 (Se)',
    );
  }
}
