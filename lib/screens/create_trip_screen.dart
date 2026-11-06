// OWNER: Person 2 (Se). Placeholder: replace with the Create/Edit Trip form.
// `trip == null` means CREATE; a Trip means EDIT.


import 'package:flutter/material.dart';

import '../models/trip.dart';
import '../services/trip_service.dart';

class CreateTripScreen extends StatefulWidget {
  const CreateTripScreen({super.key, this.trip});

  final Trip? trip;

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _destinationController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;

  bool get _isEditing => widget.trip != null;

  @override
  void initState() {
    super.initState();

    if (_isEditing) {
      final trip = widget.trip!;
      _nameController.text = trip.name;
      _destinationController.text = trip.destination;
      _notesController.text = trip.notes;
      _startDate = trip.startDate;
      _endDate = trip.endDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _destinationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select date';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initialDate = isStart
        ? (_startDate ?? DateTime.now())
        : (_endDate ?? _startDate ?? DateTime.now());

    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (selected == null) return;

    setState(() {
      if (isStart) {
        _startDate = selected;

        if (_endDate != null && _endDate!.isBefore(selected)) {
          _endDate = null;
        }
      } else {
        _endDate = selected;
      }
    });
  }

  Future<void> _saveTrip() async {
    if (!_formKey.currentState!.validate()) return;

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both trip dates')),
      );
      return;
    }

    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End date cannot be before start date'),
        ),
      );
      return;
    }

    final service = TripService.instance;

    if (_isEditing) {
      final trip = widget.trip!;

      trip.name = _nameController.text.trim();
      trip.destination = _destinationController.text.trim();
      trip.startDate = _startDate!;
      trip.endDate = _endDate!;
      trip.notes = _notesController.text.trim();

      await service.updateTrip(trip);
    } else {
      final trip = Trip(
        id: service.nextTripId(),
        name: _nameController.text.trim(),
        destination: _destinationController.text.trim(),
        startDate: _startDate!,
        endDate: _endDate!,
        notes: _notesController.text.trim(),
      );

      await service.addTrip(trip);
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isEditing ? 'Trip updated!' : 'Trip created!'),
      ),
    );

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Trip' : 'Create Trip'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Trip Name',
                  hintText: 'e.g. Summer Vacation',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a trip name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _destinationController,
                decoration: const InputDecoration(
                  labelText: 'Destination',
                  hintText: 'e.g. Toronto, Canada',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a destination';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              OutlinedButton.icon(
                onPressed: () => _pickDate(isStart: true),
                icon: const Icon(Icons.calendar_today),
                label: Text('Start Date: ${_formatDate(_startDate)}'),
              ),

              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: () => _pickDate(isStart: false),
                icon: const Icon(Icons.event),
                label: Text('End Date: ${_formatDate(_endDate)}'),
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _notesController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Trip Notes (Optional)',
                  hintText: 'Add any important information...',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: _saveTrip,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(_isEditing ? 'Save Changes' : 'Create Trip'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

