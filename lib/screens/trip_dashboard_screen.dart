// OWNER: Person 1 (Z). Placeholder: replace with the real Trip Dashboard.
// The ListTiles show how to jump to every trip feature.

import 'package:flutter/material.dart';

import '../models/trip.dart';
import '../routes.dart';

class TripDashboardScreen extends StatelessWidget {
  const TripDashboardScreen({super.key, required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(trip.name),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit trip',
            onPressed: () async {
              final updated = await Navigator.pushNamed(
                context,
                Routes.createTrip,
                arguments: trip,
              );

              if (updated == true && context.mounted) {
                (context as Element).markNeedsBuild();
              }
            },
          ),
        ],
      ),
      body: ListView(
        children: <Widget>[
          ListTile(title: Text(trip.destination)),
          const Divider(),
          _link(context, Icons.event_note, 'Itinerary', Routes.itinerary),
          _link(context, Icons.luggage, 'Packing List', Routes.packing),
          _link(context, Icons.attach_money, 'Expenses', Routes.expenses),
          _link(context, Icons.map, 'Places & Map', Routes.places),
        ],
      ),
    );
  }

  Widget _link(BuildContext context, IconData icon, String label, String route) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.pushNamed(context, route, arguments: trip),
    );
  }
}
