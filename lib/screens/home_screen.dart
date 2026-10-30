// OWNER: Person 1 (Z). Placeholder: replace with the real My Trips screen.
// It already shows how to read trips and navigate, so copy that.

import 'package:flutter/material.dart';

import '../routes.dart';
import '../services/trip_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final trips = TripService.instance.trips;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('My Trips'),
      ),
      body: trips.isEmpty
          ? const Center(child: Text('No trips yet. Tap + to create one!'))
          : ListView.builder(
              itemCount: trips.length,
              itemBuilder: (BuildContext context, int index) {
                final trip = trips[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.place),
                    title: Text(trip.name),
                    subtitle: Text(trip.destination),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        Routes.dashboard,
                        arguments: trip,
                      );
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.pushNamed(context, Routes.createTrip);
          setState(() {}); // refresh the list when we come back
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
