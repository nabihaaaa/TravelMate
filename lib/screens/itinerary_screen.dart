// OWNER: Person 2 (Se). Placeholder: replace the body with the real screen.
// Keep the class name and the constructor so routes.dart keeps working.


import 'package:flutter/material.dart';

import '../models/itinerary_item.dart';
import '../models/trip.dart';
import '../services/trip_service.dart';

class ItineraryScreen extends StatefulWidget {
  const ItineraryScreen({super.key, required this.trip});

  final Trip trip;

  @override
  State<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends State<ItineraryScreen> {
  final TripService _service = TripService.instance;

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  TimeOfDay _parseTime(String value) {
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})\s*(AM|PM)$',
      caseSensitive: false,
    ).firstMatch(value.trim());

    if (match == null) return const TimeOfDay(hour: 9, minute: 0);

    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final isPm = match.group(3)!.toUpperCase() == 'PM';

    hour = hour % 12 + (isPm ? 12 : 0);
    return TimeOfDay(hour: hour, minute: minute);
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  List<ItineraryItem> get _activities {
    final items = _service.itineraryFor(widget.trip.id);

    items.sort((a, b) {
      final dateComparison = a.date.compareTo(b.date);
      if (dateComparison != 0) return dateComparison;

      final aTime = _parseTime(a.startTime);
      final bTime = _parseTime(b.startTime);

      final aMinutes = aTime.hour * 60 + aTime.minute;
      final bMinutes = bTime.hour * 60 + bTime.minute;

      return aMinutes.compareTo(bMinutes);
    });

    return items;
  }

  Future<void> _showActivityForm({ItineraryItem? activity}) async {
    final isEditing = activity != null;

    final formKey = GlobalKey<FormState>();

    final titleController = TextEditingController(
      text: activity?.title ?? '',
    );

    final locationController = TextEditingController(
      text: activity?.location ?? '',
    );

    final notesController = TextEditingController(
      text: activity?.notes ?? '',
    );

    DateTime selectedDate = _dateOnly(
      activity?.date ?? widget.trip.startDate,
    );

    TimeOfDay selectedTime = activity == null
        ? const TimeOfDay(hour: 9, minute: 0)
        : _parseTime(activity.startTime);

    bool saved = false;

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, updateDialog) {
              return AlertDialog(
                title: Text(
                  isEditing ? 'Edit Activity' : 'Add Activity',
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  child: SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: titleController,
                            decoration: const InputDecoration(
                              labelText: 'Activity Title',
                              hintText: 'e.g. Visit Museum',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty) {
                                return 'Please enter an activity title';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              'Date: ${_formatDate(selectedDate)}',
                            ),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: dialogContext,
                                initialDate: selectedDate,
                                firstDate: _dateOnly(
                                  widget.trip.startDate,
                                ),
                                lastDate: _dateOnly(
                                  widget.trip.endDate,
                                ),
                              );

                              if (picked != null) {
                                updateDialog(() {
                                  selectedDate = picked;
                                });
                              }
                            },
                          ),

                          const SizedBox(height: 12),

                          OutlinedButton.icon(
                            icon: const Icon(Icons.access_time),
                            label: Text(
                              'Time: ${_formatTime(selectedTime)}',
                            ),
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: dialogContext,
                                initialTime: selectedTime,
                              );

                              if (picked != null) {
                                updateDialog(() {
                                  selectedTime = picked;
                                });
                              }
                            },
                          ),

                          const SizedBox(height: 16),

                          TextFormField(
                            controller: locationController,
                            decoration: const InputDecoration(
                              labelText: 'Location (Optional)',
                              border: OutlineInputBorder(),
                            ),
                          ),

                          const SizedBox(height: 16),

                          TextFormField(
                            controller: notesController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Notes (Optional)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                    },
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (!formKey.currentState!.validate()) {
                        return;
                      }

                      final title = titleController.text.trim();
                      final location = locationController.text.trim();
                      final notes = notesController.text.trim();
                      final time = _formatTime(selectedTime);

                      if (isEditing) {
                        activity.title = title;
                        activity.date = selectedDate;
                        activity.startTime = time;
                        activity.location = location;
                        activity.notes = notes;
                      } else {
                        final newActivity = ItineraryItem(
                          id: _service.nextItineraryId(),
                          tripId: widget.trip.id,
                          title: title,
                          date: selectedDate,
                          startTime: time,
                          location: location,
                          notes: notes,
                        );

                        _service.itinerary.add(newActivity);
                      }

                      saved = true;
                      Navigator.pop(dialogContext);
                    },
                    child: Text(isEditing ? 'Save Changes' : 'Add'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      // Dialog widgets may still be completing their exit animation.
      // Dispose controllers after the route has fully finished.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        titleController.dispose();
        locationController.dispose();
        notesController.dispose();
      });
    }

    if (saved && mounted) {
      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing ? 'Activity updated!' : 'Activity added!',
          ),
        ),
      );
    }
  }

  Future<void> _deleteActivity(ItineraryItem activity) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Activity'),
          content: Text(
            'Are you sure you want to delete "${activity.title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      setState(() {
        _service.itinerary.removeWhere(
          (item) => item.id == activity.id &&
              item.tripId == widget.trip.id,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activity deleted!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final activities = _activities;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Itinerary'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: activities.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_note, size: 64),
                  SizedBox(height: 16),
                  Text('No activities yet'),
                  SizedBox(height: 8),
                  Text('Tap + to add your first activity'),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: activities.length,
              itemBuilder: (context, index) {
                final activity = activities[index];

                final showDateHeader = index == 0 ||
                    _formatDate(activities[index - 1].date) !=
                        _formatDate(activity.date);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showDateHeader)
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 16,
                          bottom: 8,
                          left: 8,
                        ),
                        child: Text(
                          _formatDate(activity.date),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium,
                        ),
                      ),

                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.schedule),
                        title: Text(activity.title),
                        subtitle: Text(
                          '${activity.startTime}'
                          '${activity.location.isNotEmpty ? '\n${activity.location}' : ''}',
                        ),
                        isThreeLine: activity.location.isNotEmpty,
                        onTap: () => _showActivityForm(
                          activity: activity,
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showActivityForm(
                                activity: activity,
                              );
                            } else if (value == 'delete') {
                              _deleteActivity(activity);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showActivityForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
