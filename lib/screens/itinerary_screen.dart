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

  static const Color _pink = Color(0xFFC15E76);
  static const Color _darkPink = Color(0xFF91485D);
  static const Color _lightPink = Color(0xFFF9E5E7);
  static const Color _background = Color(0xFFFFF8F7);

  late DateTime _selectedDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = _dateOnly(widget.trip.startDate);
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String _formatShortDate(DateTime date) {
    return '${_months[date.month - 1]} ${date.day}';
  }

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

  List<DateTime> get _tripDates {
    final days =
        widget.trip.endDate
            .difference(_dateOnly(widget.trip.startDate))
            .inDays +
        1;

    return List.generate(
      days < 1 ? 1 : days,
      (index) => _dateOnly(widget.trip.startDate).add(Duration(days: index)),
    );
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

  List<ItineraryItem> get _selectedActivities {
    return _activities.where((activity) {
      return _dateOnly(activity.date) == _selectedDate;
    }).toList();
  }

  void _showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  Future<void> _save(String message) async {
    try {
      await _service.saveAllData();
      if (mounted) _showSnackBar(message);
    } catch (error) {
      if (mounted) _showSnackBar('Could not save changes.');
    }
  }

  Future<void> _showActivityForm({ItineraryItem? activity}) async {
    final isEditing = activity != null;
    final formKey = GlobalKey<FormState>();

    String title = activity?.title ?? '';
    String location = activity?.location ?? '';
    String notes = activity?.notes ?? '';

    DateTime selectedDate = _dateOnly(activity?.date ?? _selectedDate);

    TimeOfDay selectedTime = activity == null
        ? const TimeOfDay(hour: 9, minute: 0)
        : _parseTime(activity.startTime);

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, updateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(isEditing ? 'Edit Activity' : 'Add Activity'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      initialValue: title,
                      autofocus: !isEditing,
                      decoration: const InputDecoration(
                        labelText: 'Activity Title',
                        hintText: 'e.g. Visit Museum',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => title = value,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Please enter an activity title'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_formatDate(selectedDate)),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: dialogContext,
                          initialDate: selectedDate,
                          firstDate: _dateOnly(widget.trip.startDate),
                          lastDate: _dateOnly(widget.trip.endDate),
                        );

                        if (picked != null) {
                          updateDialog(() {
                            selectedDate = picked;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.access_time),
                      label: Text(_formatTime(selectedTime)),
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
                    const SizedBox(height: 14),
                    TextFormField(
                      initialValue: location,
                      decoration: const InputDecoration(
                        labelText: 'Location (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => location = value,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      initialValue: notes,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Notes (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => notes = value,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _pink,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: Text(isEditing ? 'Save Changes' : 'Add'),
            ),
          ],
        ),
      ),
    );

    if (result != true || !mounted) return;

    if (isEditing) {
      activity.title = title.trim();
      activity.date = selectedDate;
      activity.startTime = _formatTime(selectedTime);
      activity.location = location.trim();
      activity.notes = notes.trim();
    } else {
      final newActivity = ItineraryItem(
        id: _service.nextItineraryId(),
        tripId: widget.trip.id,
        title: title.trim(),
        date: selectedDate,
        startTime: _formatTime(selectedTime),
        location: location.trim(),
        notes: notes.trim(),
      );

      _service.itinerary.add(newActivity);
    }

    setState(() {
      _selectedDate = selectedDate;
    });

    await _save(isEditing ? 'Activity updated!' : 'Activity added!');
  }

  Future<void> _deleteActivity(ItineraryItem activity) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Activity'),
        content: Text('Are you sure you want to delete "${activity.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _pink,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _service.itinerary.removeWhere(
        (item) => item.id == activity.id && item.tripId == widget.trip.id,
      );
    });

    await _save('Activity deleted!');
  }

  Widget _buildTripCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _lightPink,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'YOUR TRIP',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.3,
                    fontWeight: FontWeight.bold,
                    color: _darkPink,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  widget.trip.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _darkPink,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${_formatShortDate(widget.trip.startDate)} – '
                  '${_formatShortDate(widget.trip.endDate)}, '
                  '${widget.trip.endDate.year}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.calendar_month_outlined,
              color: _pink,
              size: 25,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector() {
    final dates = _tripDates;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(dates.length, (index) {
          final date = dates[index];
          final selected = _dateOnly(date) == _selectedDate;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text('Day ${index + 1} · ${_formatShortDate(date)}'),
              selected: selected,
              showCheckmark: false,
              selectedColor: _pink,
              backgroundColor: _lightPink,
              labelStyle: TextStyle(
                color: selected ? Colors.white : _darkPink,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              shape: const StadiumBorder(),
              onSelected: (_) {
                setState(() {
                  _selectedDate = date;
                });
              },
            ),
          );
        }),
      ),
    );
  }

  Widget _buildActivityCard(ItineraryItem activity) {
    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      elevation: 1,
      shadowColor: Colors.black12,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        leading: const Icon(Icons.schedule, color: _darkPink, size: 23),
        title: Text(
          activity.title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            '${activity.startTime}'
            '${activity.location.isNotEmpty ? '\n${activity.location}' : ''}',
            style: const TextStyle(
              fontSize: 12,
              height: 1.5,
              color: Colors.black54,
            ),
          ),
        ),
        isThreeLine: activity.location.isNotEmpty,
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: _darkPink),
          onSelected: (value) {
            if (value == 'edit') {
              _showActivityForm(activity: activity);
            } else if (value == 'delete') {
              _deleteActivity(activity);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activities = _selectedActivities;

    final dayNumber =
        _tripDates.indexWhere((date) => date == _selectedDate) + 1;

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _pink,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Itinerary',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              children: [
                _buildTripCard(),
                const SizedBox(height: 16),
                _buildDaySelector(),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Day $dayNumber · ${_formatShortDate(_selectedDate)}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${activities.length} activities',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (activities.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.event_note_outlined, size: 42, color: _pink),
                        SizedBox(height: 10),
                        Text(
                          'No activities planned for this day.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Tap Add Activity to start planning.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  )
                else
                  ...activities.map(_buildActivityCard),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: const BoxDecoration(
              color: _background,
              border: Border(top: BorderSide(color: Color(0xFFF0DCDD))),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : () => _showActivityForm(),
                icon: const Icon(Icons.add, size: 19),
                label: Text(_saving ? 'Saving...' : 'Add Activity'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _pink,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
