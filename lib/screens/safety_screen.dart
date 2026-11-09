import 'package:flutter/material.dart';

import '../models/trip.dart';
import '../services/trip_service.dart';
import '../services/notification_service.dart';

class SafetyScreen extends StatefulWidget {
  const SafetyScreen({super.key, required this.trip});

  final Trip trip;

  @override
  State<SafetyScreen> createState() => _SafetyScreenState();
}

class _SafetyScreenState extends State<SafetyScreen> {
  final TripService _service = TripService.instance;

  static const Color _pink = Color(0xFFC15E76);
  static const Color _darkPink = Color(0xFF91485D);
  static const Color _background = Color(0xFFFFF7F6);
  static const Color _lightPink = Color(0xFFF9E5E7);

  bool _saving = false;

  List<Map<String, dynamic>> get _contacts =>
      _service.contactsFor(widget.trip.id);

  String get _notes => _service.safetyNotes[widget.trip.id] ?? '';

  String get _emergency => _service.emergencyInfo[widget.trip.id] ?? '';

  bool get _reminderEnabled => _service.checkInEnabled.contains(widget.trip.id);

  TimeOfDay get _reminderTime {
    final value = _service.checkInTimes[widget.trip.id];

    if (value == null) return const TimeOfDay(hour: 20, minute: 0);

    final parts = value.split(':');

    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';

    return '$hour:$minute $period';
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  Future<void> _saveData(String message) async {
    try {
      await _service.saveAllData();

      if (mounted) _showMessage(message);
    } catch (error) {
      if (mounted) _showMessage('Could not save changes.');
    }
  }

  Future<void> _contactForm({Map<String, dynamic>? existing}) async {
    String name = existing?['name'] ?? '';
    String contactMethod = existing?['contactMethod'] ?? '';

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(existing == null ? 'Add Contact' : 'Edit Contact'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: name,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Contact name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                onChanged: (value) => name = value,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a name'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: contactMethod,
                decoration: const InputDecoration(
                  labelText: 'Phone number or email',
                  prefixIcon: Icon(Icons.contact_phone_outlined),
                ),
                onChanged: (value) => contactMethod = value,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter contact information'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: Text(existing == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );

    if (result != true || !mounted) return;

    setState(() {
      if (existing == null) {
        _service.trustedContacts.add({
          'id': _service.nextContactId(),
          'tripId': widget.trip.id,
          'name': name.trim(),
          'contactMethod': contactMethod.trim(),
        });
      } else {
        existing['name'] = name.trim();
        existing['contactMethod'] = contactMethod.trim();
      }
    });

    await _saveData('Trusted contact saved!');
  }

  Future<void> _deleteContact(Map<String, dynamic> contact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove Contact?'),
        content: Text('Remove ${contact['name']} from your trusted contacts?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _service.trustedContacts.removeWhere(
        (item) =>
            item['id'] == contact['id'] && item['tripId'] == widget.trip.id,
      );
    });

    await _saveData('Contact removed.');
  }

  Future<void> _editText({
    required String title,
    required String label,
    required String currentValue,
    required Function(String) onSave,
  }) async {
    String value = currentValue;
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title),
        content: Form(
          key: formKey,
          child: TextFormField(
            initialValue: currentValue,
            maxLines: 5,
            autofocus: true,
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
            ),
            onChanged: (text) => value = text,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != true || !mounted) return;

    setState(() => onSave(value.trim()));

    await _saveData('$title saved!');
  }

  Future<void> _setReminder() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );

    if (selected == null || !mounted) return;

    setState(() => _saving = true);

    try {
      final allowed = await NotificationService.instance.requestPermission();

      if (!allowed) {
        _showMessage('Please enable notifications in device settings.');
        return;
      }

      await NotificationService.instance.scheduleDailyCheckIn(
        tripId: widget.trip.id,
        tripName: widget.trip.name,
        time: selected,
      );

      _service.checkInTimes[widget.trip.id] =
          '${selected.hour.toString().padLeft(2, '0')}:'
          '${selected.minute.toString().padLeft(2, '0')}';

      _service.checkInEnabled.add(widget.trip.id);

      await _service.saveAllData();

      if (!mounted) return;

      setState(() {});
      _showMessage('Daily check-in reminder scheduled!');
    } catch (error) {
      _showMessage('Could not schedule reminder: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _toggleReminder(bool enabled) async {
    setState(() => _saving = true);

    try {
      if (enabled) {
        final allowed = await NotificationService.instance.requestPermission();

        if (!allowed) {
          _showMessage('Please enable notifications in device settings.');
          return;
        }

        await NotificationService.instance.scheduleDailyCheckIn(
          tripId: widget.trip.id,
          tripName: widget.trip.name,
          time: _reminderTime,
        );

        _service.checkInEnabled.add(widget.trip.id);
      } else {
        await NotificationService.instance.cancelDailyCheckIn(widget.trip.id);

        _service.checkInEnabled.remove(widget.trip.id);
      }

      await _service.saveAllData();

      if (!mounted) return;

      setState(() {});
      _showMessage(
        enabled ? 'Check-in reminder enabled.' : 'Reminder disabled.',
      );
    } catch (error) {
      _showMessage('Could not update reminder: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
      ),
      child: child,
    );
  }

  Widget _sectionHeading({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _lightPink,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: _pink, size: 21),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContacts() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading(
            icon: Icons.people_outline,
            title: 'Trusted Contacts',
            subtitle: 'Add people you trust while travelling.',
          ),
          const SizedBox(height: 12),
          if (_contacts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No trusted contacts added yet.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            )
          else
            ..._contacts.map((contact) {
              final name = contact['name'] as String;

              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: _lightPink,
                  foregroundColor: _darkPink,
                  child: Text(name.isEmpty ? '?' : name[0].toUpperCase()),
                ),
                title: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  contact['contactMethod'],
                  style: const TextStyle(fontSize: 11),
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _contactForm(existing: contact);
                    } else {
                      _deleteContact(contact);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              );
            }),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _saving ? null : () => _contactForm(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Contact'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _darkPink,
                backgroundColor: _lightPink,
                side: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminder() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading(
            icon: Icons.alarm_outlined,
            title: 'Check-in Reminder',
            subtitle: 'Set a daily reminder to check in.',
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: _background,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: const Color(0xFFF2E3E3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _saving ? null : _setReminder,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        'Daily at ${_formatTime(_reminderTime)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ),
                Switch(
                  value: _reminderEnabled,
                  activeThumbColor: _pink,
                  onChanged: _saving ? null : _toggleReminder,
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Tap the time to change your daily reminder.',
            style: TextStyle(fontSize: 10, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyNotes() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _sectionHeading(
                  icon: Icons.sticky_note_2_outlined,
                  title: 'Safety Notes',
                  subtitle: 'Keep important information handy.',
                ),
              ),
              IconButton(
                onPressed: () => _editText(
                  title: 'Safety Notes',
                  label: 'Hotel, meeting point, plans...',
                  currentValue: _notes,
                  onSave: (value) {
                    _service.safetyNotes[widget.trip.id] = value;
                  },
                ),
                icon: const Icon(Icons.edit_outlined, color: _darkPink),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFF2E3E3)),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Text(
              _notes.isEmpty
                  ? 'Add your hotel address, meeting point, or other important travel notes.'
                  : _notes,
              style: TextStyle(
                fontSize: 12,
                height: 1.6,
                color: _notes.isEmpty ? Colors.black54 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyInfo() {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _sectionHeading(
                  icon: Icons.emergency_outlined,
                  title: 'Emergency Information',
                  subtitle: 'Keep important emergency details accessible.',
                ),
              ),
              IconButton(
                onPressed: () => _editText(
                  title: 'Emergency Information',
                  label: 'Local emergency number and details',
                  currentValue: _emergency,
                  onSave: (value) {
                    _service.emergencyInfo[widget.trip.id] = value;
                  },
                ),
                icon: const Icon(Icons.edit_outlined, color: _darkPink),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _background,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Text(
              _emergency.isEmpty
                  ? 'Add the local emergency number, hospital details, or other useful emergency information for your destination.'
                  : _emergency,
              style: TextStyle(
                fontSize: 12,
                height: 1.6,
                color: _emergency.isEmpty ? Colors.black54 : Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'For immediate danger, contact local emergency services.',
            style: TextStyle(fontSize: 10, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text(
          'Safety',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        backgroundColor: _background,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        children: [
          _buildContacts(),
          const SizedBox(height: 12),
          _buildReminder(),
          const SizedBox(height: 12),
          _buildSafetyNotes(),
          const SizedBox(height: 12),
          _buildEmergencyInfo(),
        ],
      ),
    );
  }
}
