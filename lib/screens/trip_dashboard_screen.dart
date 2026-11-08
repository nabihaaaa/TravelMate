// File: trip_dashboard_screen.dart
// Purpose: Shows a summary of one trip (dates, packing and budget progress,
// upcoming activities) with shortcuts to the trip's other screens.
// Owner: Person 1 (Z).

import 'package:flutter/material.dart';

import '../models/itinerary_item.dart';
import '../models/trip.dart';
import '../routes.dart';
import '../services/trip_service.dart';

class TripDashboardScreen extends StatefulWidget {
  const TripDashboardScreen({super.key, required this.trip});

  final Trip trip;

  @override
  State<TripDashboardScreen> createState() => _TripDashboardScreenState();
}

class _TripDashboardScreenState extends State<TripDashboardScreen> {
  Trip get trip => widget.trip;

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

  // Open another screen for this trip, then refresh when we come back
  // (the packing list or expenses may have changed).
  Future<void> _go(String route) async {
    await Navigator.pushNamed(context, route, arguments: trip);
    if (mounted) setState(() {});
  }

  Future<void> _editTrip() async {
    await Navigator.pushNamed(context, Routes.createTrip, arguments: trip);
    if (mounted) setState(() {}); // the trip was edited in place
  }

  // Next 3 activities that are today or later, soonest first.
  List<ItineraryItem> _upcomingActivities() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final items =
        TripService.instance
            .itineraryFor(trip.id)
            .where((item) => !item.date.isBefore(today))
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    return items.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(trip.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit trip',
            onPressed: _editTrip,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSummaryCard(),
          _buildPackingCard(),
          _buildBudgetCard(),
          _buildUpNextCard(),
          const SizedBox(height: 8),
          _sectionTitle('Trip tools'),
          _link(Icons.event_note, 'Itinerary', Routes.itinerary),
          _link(Icons.luggage, 'Packing List', Routes.packing),
          _link(Icons.attach_money, 'Expenses', Routes.expenses),
          _link(Icons.map, 'Places & Map', Routes.places),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.place),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    trip.destination,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 18),
                const SizedBox(width: 8),
                Text(
                  '${_formatDate(trip.startDate)} - '
                  '${_formatDate(trip.endDate)}  '
                  '(${trip.days} ${trip.days == 1 ? 'day' : 'days'})',
                ),
              ],
            ),
            if (trip.notes.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(trip.notes),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPackingCard() {
    final items = TripService.instance.packingFor(trip.id);
    final packed = items.where((item) => item.isPacked).length;

    return Card(
      child: ListTile(
        leading: const Icon(Icons.luggage),
        title: const Text('Packing'),
        subtitle: items.isEmpty
            ? const Text('No packing items yet')
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$packed of ${items.length} packed'),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(value: packed / items.length),
                ],
              ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _go(Routes.packing),
      ),
    );
  }

  Widget _buildBudgetCard() {
    final spent = TripService.instance
        .expensesFor(trip.id)
        .fold<double>(0, (sum, expense) => sum + expense.amount);
    final budget = trip.budget;

    Widget subtitle;
    if (budget == null || budget <= 0) {
      subtitle = Text('\$${spent.toStringAsFixed(2)} spent (no budget set)');
    } else {
      final remaining = budget - spent;
      subtitle = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '\$${spent.toStringAsFixed(2)} of '
            '\$${budget.toStringAsFixed(2)} spent',
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: (spent / budget).clamp(0.0, 1.0).toDouble(),
          ),
          const SizedBox(height: 6),
          Text(
            remaining >= 0
                ? '\$${remaining.toStringAsFixed(2)} remaining'
                : '\$${(-remaining).toStringAsFixed(2)} over budget',
          ),
        ],
      );
    }

    return Card(
      child: ListTile(
        leading: const Icon(Icons.attach_money),
        title: const Text('Budget'),
        subtitle: subtitle,
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _go(Routes.expenses),
      ),
    );
  }

  Widget _buildUpNextCard() {
    final upcoming = _upcomingActivities();

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: Text(
                'Up next',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              trailing: TextButton(
                onPressed: () => _go(Routes.itinerary),
                child: const Text('See all'),
              ),
            ),
            if (upcoming.isEmpty)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text('No upcoming activities'),
              )
            else
              ...upcoming.map(
                (item) => ListTile(
                  leading: const Icon(Icons.schedule),
                  title: Text(item.title),
                  subtitle: Text(
                    '${_formatDate(item.date)} · ${item.startTime} · '
                    '${item.location}',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _link(IconData icon, String label, String route) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _go(route),
      ),
    );
  }
}
