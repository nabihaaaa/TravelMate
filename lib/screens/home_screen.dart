// File: home_screen.dart
// Purpose: Displays the user's trips with All/Upcoming/Past filters,
// highlights the next trip, and provides navigation to create or open a trip.
// Owner: Person 1 (Z).

import 'package:flutter/material.dart';

import '../models/trip.dart';
import '../routes.dart';
import '../services/trip_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const List<String> _filters = ['All', 'Upcoming', 'Past'];
  String _filter = 'All';

  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String _formatDate(DateTime date) =>
      '${_months[date.month - 1]} ${date.day}, ${date.year}';

  String _formatRange(Trip trip) =>
      '${_formatDate(trip.startDate)} - ${_formatDate(trip.endDate)}';

  // A trip is "past" once its end date is before today.
  bool _isPast(Trip trip) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return trip.endDate.isBefore(today);
  }

  // The soonest trip that has not ended yet (null if there isn't one).
  Trip? _nextTrip(List<Trip> trips) {
    final upcoming = trips.where((trip) => !_isPast(trip)).toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    return upcoming.isEmpty ? null : upcoming.first;
  }

  // Trips to show for the selected filter, soonest first.
  List<Trip> _visibleTrips(List<Trip> all) {
    final list = all.where((trip) {
      if (_filter == 'Upcoming') return !_isPast(trip);
      if (_filter == 'Past') return _isPast(trip);
      return true;
    }).toList()..sort((a, b) => a.startDate.compareTo(b.startDate));
    return list;
  }

  Future<void> _openTrip(Trip trip) async {
    await Navigator.pushNamed(context, Routes.dashboard, arguments: trip);
    if (mounted) setState(() {}); // refresh in case the trip changed
  }

  Future<void> _createTrip() async {
    await Navigator.pushNamed(context, Routes.createTrip);
    if (mounted) setState(() {});
  }

  Future<void> _editTrip(Trip trip) async {
    await Navigator.pushNamed(context, Routes.createTrip, arguments: trip);
    if (mounted) setState(() {});
  }

  Future<void> _confirmDelete(Trip trip) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete trip?'),
        content: Text(
          '"${trip.name}" and its itinerary, packing list, expenses and '
          'places will be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await TripService.instance.deleteTrip(trip.id);

    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Trip deleted')));
  }

  @override
  Widget build(BuildContext context) {
    final allTrips = TripService.instance.trips;
    final visibleTrips = _visibleTrips(allTrips);
    final nextTrip = _nextTrip(allTrips);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('My Trips'),
      ),
      body: allTrips.isEmpty
          ? _buildEmptyState()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (nextTrip != null) _buildNextTripCard(nextTrip),
                _buildFilterChips(),
                if (visibleTrips.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text('No ${_filter.toLowerCase()} trips.'),
                    ),
                  )
                else
                  ...visibleTrips.map(_buildTripTile),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createTrip,
        tooltip: 'Create trip',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.luggage, size: 64),
            const SizedBox(height: 16),
            const Text(
              'No trips yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Tap the button below to plan your first trip.'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _createTrip,
              icon: const Icon(Icons.add),
              label: const Text('Create Trip'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextTripCard(Trip trip) {
    final service = TripService.instance;
    final packingItems = service.packingFor(trip.id);
    final packed = packingItems.where((item) => item.isPacked).length;
    final spent = service
        .expensesFor(trip.id)
        .fold<double>(0, (sum, expense) => sum + expense.amount);

    final spentText = trip.budget == null
        ? '\$${spent.toStringAsFixed(0)} spent'
        : '\$${spent.toStringAsFixed(0)} of '
              '\$${trip.budget!.toStringAsFixed(0)} spent';

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openTrip(trip),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Next trip', style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 4),
              Text(trip.name, style: Theme.of(context).textTheme.titleLarge),
              Text(_formatRange(trip)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  Chip(label: Text('$packed of ${packingItems.length} packed')),
                  Chip(label: Text(spentText)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Wrap(
        spacing: 8,
        children: _filters
            .map(
              (label) => ChoiceChip(
                label: Text(label),
                selected: _filter == label,
                onSelected: (_) => setState(() => _filter = label),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildTripTile(Trip trip) {
    return Card(
      child: ListTile(
        leading: Icon(_isPast(trip) ? Icons.history : Icons.place),
        title: Text(trip.name),
        subtitle: Text('${trip.destination}\n${_formatRange(trip)}'),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') _editTrip(trip);
            if (value == 'delete') _confirmDelete(trip);
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
        onTap: () => _openTrip(trip),
      ),
    );
  }
}
