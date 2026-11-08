import 'package:flutter/material.dart';

import '../services/notification_service.dart';

import '../models/place.dart';
import '../models/trip.dart';
import '../services/trip_service.dart';

class PlacesScreen extends StatefulWidget {
  const PlacesScreen({super.key, required this.trip});

  final Trip trip;

  @override
  State<PlacesScreen> createState() => _PlacesScreenState();
}

class _PlacesScreenState extends State<PlacesScreen> {
  final TripService _service = TripService.instance;
  bool _saving = false;
  bool _reminderBusy = false;
  DateTime? _scheduledFor;

  List<Place> get _places => _service.placesFor(widget.trip.id);

  Future<void> _testNotification() async {
    try {
      final allowed = await NotificationService.instance.requestPermission();

      if (!allowed) {
        _showSnackBar('Please enable notifications in device settings.');
        return;
      }

      await NotificationService.instance.showTripReminder(
        tripName: widget.trip.name,
        destination: widget.trip.destination,
      );

      _showSnackBar('Test notification sent!');
    } catch (error) {
      _showSnackBar('Notification failed: $error');
    }
  }

  Future<void> _scheduleReminder() async {
    final now = DateTime.now();
    final suggested = now.add(const Duration(minutes: 2));
    DateTime selectedDate = DateTime(suggested.year, suggested.month, suggested.day);
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(suggested);

    final reminder = await showDialog<DateTime>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, updateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Schedule Trip Reminder'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Get a reminder for ${widget.trip.name}.'),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_month_outlined),
                label: Text(MaterialLocalizations.of(dialogContext)
                    .formatMediumDate(selectedDate)),
                onPressed: () async {
                  final date = await showDatePicker(
                    context: dialogContext,
                    initialDate: selectedDate,
                    firstDate: DateTime(now.year, now.month, now.day),
                    lastDate: now.add(const Duration(days: 365 * 5)),
                  );
                  if (date != null && dialogContext.mounted) {
                    updateDialog(() => selectedDate = date);
                  }
                },
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                icon: const Icon(Icons.access_time_outlined),
                label: Text(selectedTime.format(dialogContext)),
                onPressed: () async {
                  final time = await showTimePicker(
                    context: dialogContext,
                    initialTime: selectedTime,
                  );
                  if (time != null && dialogContext.mounted) {
                    updateDialog(() => selectedTime = time);
                  }
                },
              ),
              const SizedBox(height: 12),
              const Text('Choose a future date and time. Android may deliver '
                  'the reminder a little later than selected.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final dateTime = DateTime(
                  selectedDate.year, selectedDate.month, selectedDate.day,
                  selectedTime.hour, selectedTime.minute,
                );
                if (!dateTime.isAfter(DateTime.now())) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Choose a future date and time.')),
                  );
                  return;
                }
                Navigator.pop(dialogContext, dateTime);
              },
              child: const Text('Schedule'),
            ),
          ],
        ),
      ),
    );

    if (!mounted || reminder == null) return;
    setState(() => _reminderBusy = true);
    try {
      final allowed = await NotificationService.instance.requestPermission();
      if (!allowed) {
        _showSnackBar('Please enable notifications in device settings.');
        return;
      }
      await NotificationService.instance.scheduleTripReminder(
        tripId: widget.trip.id,
        tripName: widget.trip.name,
        destination: widget.trip.destination,
        reminderDate: reminder,
      );
      if (!mounted) return;
      setState(() => _scheduledFor = reminder);
      _showSnackBar('Trip reminder scheduled!');
    } catch (error) {
      _showSnackBar('Could not schedule reminder: $error');
    } finally {
      if (mounted) setState(() => _reminderBusy = false);
    }
  }

  Future<void> _cancelReminder() async {
    setState(() => _reminderBusy = true);
    try {
      await NotificationService.instance.cancelTripReminder(widget.trip.id);
      if (!mounted) return;
      setState(() => _scheduledFor = null);
      _showSnackBar('Trip reminder cancelled.');
    } catch (error) {
      _showSnackBar('Could not cancel reminder: $error');
    } finally {
      if (mounted) setState(() => _reminderBusy = false);
    }
  }

  Widget _buildReminderCard() {
    final colors = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.notifications_outlined, color: colors.primary),
              const SizedBox(width: 10),
              const Expanded(child: Text('Trip Reminder',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700))),
            ]),
            const SizedBox(height: 8),
            Text(
              _scheduledFor == null
                  ? 'Choose when TravelMate should remind you about this trip.'
                  : 'Reminder set for ${MaterialLocalizations.of(context).formatMediumDate(_scheduledFor!)} at ${TimeOfDay.fromDateTime(_scheduledFor!).format(context)}',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: FilledButton.icon(
                onPressed: _reminderBusy ? null : _scheduleReminder,
                icon: const Icon(Icons.event_available_outlined),
                label: Text(_reminderBusy ? 'Please wait...' :
                    (_scheduledFor == null ? 'Schedule Reminder' : 'Change Reminder')),
              )),
              if (_scheduledFor != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Cancel reminder',
                  onPressed: _reminderBusy ? null : _cancelReminder,
                  icon: const Icon(Icons.notifications_off_outlined),
                ),
              ],
            ]),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  Future<void> _addPlace() async {
    final formKey = GlobalKey<FormState>();
    String name = '';
    String address = '';

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Row(
            children: [
              Icon(Icons.add_location_alt_outlined),
              SizedBox(width: 10),
              Text('Add a Place'),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Place name',
                    hintText: 'e.g. Eiffel Tower',
                    prefixIcon: Icon(Icons.place_outlined),
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Please enter a place name'
                      : null,
                  onSaved: (value) => name = value!.trim(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Address or location',
                    hintText: 'e.g. Paris, France',
                    prefixIcon: Icon(Icons.location_on_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Please enter a location'
                      : null,
                  onSaved: (value) => address = value!.trim(),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Save Place'),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();
                  Navigator.pop(dialogContext, {
                    'name': name,
                    'address': address,
                  });
                }
              },
            ),
          ],
        );
      },
    );

    if (!mounted || result == null) return;

    setState(() => _saving = true);

    final nextId =
        _service.places.fold<int>(
          0,
          (maxId, place) => place.id > maxId ? place.id : maxId,
        ) +
        1;

    final place = Place(
      id: nextId,
      tripId: widget.trip.id,
      name: result['name']!,
      address: result['address']!,
    );

    try {
      _service.places.add(place);
      await _service.saveAllData();

      if (!mounted) return;
      _showSnackBar('Place added to your trip!');
    } catch (_) {
      _service.places.remove(place);
      _showSnackBar('Could not save this place.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deletePlace(Place place) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Remove this place?'),
        content: Text(
          'Do you want to remove "${place.name}" from your saved places?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep Place'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;

    setState(() => _saving = true);
    final index = _service.places.indexOf(place);

    try {
      _service.places.remove(place);
      await _service.saveAllData();

      if (!mounted) return;
      _showSnackBar('Place removed successfully.');
    } catch (_) {
      if (index >= 0 && !_service.places.contains(place)) {
        _service.places.insert(index, place);
      }
      _showSnackBar('Could not remove this place.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildPlaceCard(Place place, int index) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.location_on_outlined,
                color: colors.onPrimaryContainer,
                size: 27,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(
                        Icons.near_me_outlined,
                        size: 13,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          place.address.isEmpty
                              ? 'Location not specified'
                              : place.address,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Remove ${place.name}',
              onPressed: _saving ? null : () => _deletePlace(place),
              icon: const Icon(Icons.delete_outline_rounded),
              color: colors.error,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripHeader(int count) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.primaryContainer,
            colors.primaryContainer.withValues(alpha: 0.65),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YOUR ADVENTURE',
                  style: TextStyle(
                    color: colors.onPrimaryContainer,
                    fontSize: 11,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  widget.trip.destination.isNotEmpty
                      ? widget.trip.destination
                      : widget.trip.name,
                  style: TextStyle(
                    color: colors.onPrimaryContainer,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.trip.name,
                  style: TextStyle(
                    color: colors.onPrimaryContainer,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    '$count saved ${count == 1 ? 'place' : 'places'}',
                    style: TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            Icons.travel_explore_rounded,
            size: 62,
            color: colors.onPrimaryContainer.withValues(alpha: 0.7),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final places = _places;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Explore Places',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Test Notification',
            icon: const Icon(Icons.notifications_active_outlined),
            onPressed: _testNotification,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  _buildTripHeader(places.length),
                  const SizedBox(height: 16),
                  _buildReminderCard(),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Text(
                        'Your Places',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.bookmark_outline_rounded,
                        color: colors.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Keep your must-visit spots in one place.',
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (places.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 48,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.map_outlined,
                            size: 64,
                            color: colors.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Your adventure starts here!',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add your first destination to start exploring.',
                            style: TextStyle(color: colors.onSurfaceVariant),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    ...List.generate(
                      places.length,
                      (index) => _buildPlaceCard(places[index], index),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(top: BorderSide(color: colors.outlineVariant)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _addPlace,
                  icon: const Icon(Icons.add_location_alt_outlined),
                  label: Text(_saving ? 'Saving...' : 'Add a Place'),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
