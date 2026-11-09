// File: trip_dashboard_screen.dart
// Purpose: Shows a summary of one trip (dates, packing and budget progress,
// upcoming activities) with shortcuts to the trip's other screens.
// Owner: Person 1 (Z).

import 'package:flutter/material.dart';

import '../models/itinerary_item.dart';
import '../models/trip.dart';
import '../routes.dart';
import '../services/trip_service.dart';
import 'safety_screen.dart';

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

  // Open another screen for this trip, then refresh when we come back.
  Future<void> _go(String route) async {
    await Navigator.pushNamed(context, route, arguments: trip);
    if (mounted) setState(() {});
  }

  Future<void> _editTrip() async {
    await Navigator.pushNamed(context, Routes.createTrip, arguments: trip);
    if (mounted) setState(() {});
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
        title: const Text('Trip Dashboard'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
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
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildPackingCard()),
                Expanded(child: _buildBudgetCard()),
              ],
            ),
          ),
          _buildUpNextCard(),
          _buildPlacesCard(),
          _buildItineraryCard(),
          _buildSafetyCard(),
        ],
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
            Text(
              trip.name,
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '${_formatDate(trip.startDate)} - '
              '${_formatDate(trip.endDate)}',
            ),
            const SizedBox(height: 4),
            Text(
              '${trip.destination} · ${trip.days} '
              '${trip.days == 1 ? 'day' : 'days'}',
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

  // One small stat card (used for Packing and Budget).
  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required double progress,
    required String caption,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: scheme.primary),
                  const SizedBox(width: 6),
                  Text(label, style: TextStyle(color: scheme.primary)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: progress),
              const SizedBox(height: 8),
              Text(caption, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPackingCard() {
    final items = TripService.instance.packingFor(trip.id);
    final packed = items.where((item) => item.isPacked).length;
    final progress = items.isEmpty ? 0.0 : packed / items.length;

    return _statCard(
      icon: Icons.luggage,
      label: 'Packing',
      value: items.isEmpty
          ? 'No items yet'
          : '$packed of ${items.length} packed',
      progress: progress,
      caption: items.isEmpty
          ? 'Add items in Packing'
          : '${(progress * 100).round()}% done',
      onTap: () => _go(Routes.packing),
    );
  }

  Widget _buildBudgetCard() {
    final spent = TripService.instance
        .expensesFor(trip.id)
        .fold<double>(0, (sum, expense) => sum + expense.amount);
    final budget = trip.budget;

    if (budget == null || budget <= 0) {
      return _statCard(
        icon: Icons.attach_money,
        label: 'Budget',
        value: '\$${spent.toStringAsFixed(0)} spent',
        progress: 0,
        caption: 'No budget set',
        onTap: () => _go(Routes.expenses),
      );
    }

    final remaining = budget - spent;

    return _statCard(
      icon: Icons.attach_money,
      label: 'Budget',
      value: '\$${spent.toStringAsFixed(0)} / \$${budget.toStringAsFixed(0)}',
      progress: (spent / budget).clamp(0.0, 1.0).toDouble(),
      caption: remaining >= 0
          ? '\$${remaining.toStringAsFixed(0)} remaining'
          : '\$${(-remaining).toStringAsFixed(0)} over budget',
      onTap: () => _go(Routes.expenses),
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
                'Up Next',
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

  Widget _buildPlacesCard() {
    final count = TripService.instance.placesFor(trip.id).length;

    return Card(
      child: ListTile(
        leading: const Icon(Icons.map),
        title: const Text('Places & Map'),
        subtitle: Text('$count saved ${count == 1 ? 'place' : 'places'}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _go(Routes.places),
      ),
    );
  }

  Widget _buildItineraryCard() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.event_note),
        title: const Text('Itinerary'),
        subtitle: const Text('Plan your trip day by day'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _go(Routes.itinerary),
      ),
    );
  }

  Widget _buildSafetyCard() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.health_and_safety_outlined),
        title: const Text('Travel Safety'),
        subtitle: const Text('Trusted contacts and check-in reminders'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SafetyScreen(trip: trip)),
          );

          if (mounted) setState(() {});
        },
      ),
    );
  }
}
