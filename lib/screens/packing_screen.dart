// File: packing_screen.dart
// Purpose: Shows the packing list for a trip. Users can add items,
// check them off as packed, and delete them. Items are grouped by category.
// Owner: Mariyam .

import 'package:flutter/material.dart';

import '../models/packing_item.dart';
import '../models/trip.dart';
import '../services/trip_service.dart';

class PackingScreen extends StatefulWidget {
  const PackingScreen({super.key, required this.trip});

  final Trip trip;

  @override
  State<PackingScreen> createState() => _PackingScreenState();
}

class _PackingScreenState extends State<PackingScreen> {
  final TripService _service = TripService.instance;

  static const List<String> _categories = [
    'Clothing',
    'Toiletries',
    'Electronics',
    'Documents',
    'Other',
  ];

  static const List<String> _filters = [
    'All',
    'Clothing',
    'Toiletries',
    'Other',
  ];

  String _selectedFilter = 'All';

  List<PackingItem> get _items => _service.packingFor(widget.trip.id);

  List<PackingItem> get _visibleItems {
    if (_selectedFilter == 'All') return _items;

    if (_selectedFilter == 'Other') {
      return _items
          .where(
            (item) =>
                item.category == 'Electronics' ||
                item.category == 'Documents' ||
                item.category == 'Other',
          )
          .toList();
    }

    return _items.where((item) => item.category == _selectedFilter).toList();
  }

  String _formatDate(DateTime date) {
    const months = [
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

    return '${months[date.month - 1]} ${date.day}';
  }

  Future<void> _save(String message) async {
    try {
      await _service.saveAllData();
      _showSnackBar(message);
    } catch (error) {
      _showSnackBar('Could not save changes. Please try again.');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  Future<void> _togglePacked(PackingItem item, bool? value) async {
    setState(() {
      item.isPacked = value ?? false;
    });

    try {
      await _service.saveAllData();
    } catch (error) {
      _showSnackBar('Could not save changes.');
    }
  }

  Future<void> _addItem() async {
    String itemName = '';
    final formKey = GlobalKey<FormState>();
    String category = 'Other';

    final added = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Add Packing Item'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: itemName,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Item name'),
                  onChanged: (value) {
                    itemName = value;
                  },
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Please enter an item name'
                      : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: _categories.map((c) {
                    return DropdownMenuItem(value: c, child: Text(c));
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      category = value ?? 'Other';
                    });
                  },
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
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (added != true) return;
    if (!mounted) return;

    final item = PackingItem(
      id: _service.nextPackingId(),
      tripId: widget.trip.id,
      name: itemName.trim(),
      category: category,
    );

    setState(() {
      _service.packing.add(item);
      _selectedFilter = 'All';
    });

    await _save('"${item.name}" added to your packing list');
  }

  Future<void> _deleteItem(PackingItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete item?'),
        content: Text('Remove "${item.name}" from your packing list?'),
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

    if (confirm != true) return;

    setState(() {
      _service.packing.removeWhere((p) => p.id == item.id);
    });

    await _save('"${item.name}" removed');
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    final visibleItems = _visibleItems;
    final packedCount = items.where((i) => i.isPacked).length;
    final percentage = items.isEmpty
        ? 0
        : (packedCount / items.length * 100).round();

    return Scaffold(
      appBar: AppBar(title: const Text('Packing List')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              children: [
                _buildTripCard(packedCount, items.length, percentage),
                const SizedBox(height: 12),
                _buildFilters(),
                const SizedBox(height: 8),
                if (visibleItems.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('No items in this category.')),
                  )
                else
                  _buildItemList(visibleItems),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addItem,
                icon: const Icon(Icons.add),
                label: const Text('Add Item'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC15E76),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: const StadiumBorder(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripCard(int packed, int total, int percentage) {
    return Card(
      color: const Color(0xFFF9E5E7),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.trip.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Icon(Icons.luggage_outlined, color: Color(0xFFAE526A)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${_formatDate(widget.trip.startDate)} – '
              '${_formatDate(widget.trip.endDate)}, '
              '${widget.trip.endDate.year}',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$packed of $total items packed',
                  style: const TextStyle(fontSize: 12),
                ),
                Text('$percentage%', style: const TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: total == 0 ? 0 : packed / total,
              minHeight: 7,
              borderRadius: BorderRadius.circular(8),
              backgroundColor: const Color(0xFFFFCDD5),
              color: const Color(0xFFAE526A),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Wrap(
      spacing: 6,
      children: _filters.map((label) {
        final selected = _selectedFilter == label;

        return ChoiceChip(
          label: Text(label),
          selected: selected,
          showCheckmark: false,
          shape: const StadiumBorder(),
          selectedColor: const Color(0xFFAE526A),
          backgroundColor: const Color(0xFFF5E7E8),
          labelStyle: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontSize: 12,
          ),
          onSelected: (_) {
            setState(() {
              _selectedFilter = label;
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildItemList(List<PackingItem> items) {
    return Card(
      color: Colors.white,
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            Row(
              children: [
                Checkbox(
                  value: items[i].isPacked,
                  activeColor: const Color(0xFFAE526A),
                  onChanged: (value) => _togglePacked(items[i], value),
                ),
                Icon(
                  _iconFor(items[i].name, items[i].category),
                  size: 18,
                  color: const Color(0xFF75545D),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    items[i].name,
                    style: TextStyle(
                      fontSize: 13,
                      decoration: items[i].isPacked
                          ? TextDecoration.lineThrough
                          : null,
                      color: items[i].isPacked ? Colors.grey : null,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (value) {
                    if (value == 'delete') {
                      _deleteItem(items[i]);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            if (i != items.length - 1)
              const Divider(height: 1, indent: 12, endIndent: 12),
          ],
        ],
      ),
    );
  }

  IconData _iconFor(String name, String category) {
    switch (name.toLowerCase()) {
      case 't-shirts':
      case 'shirts':
      case 'jeans':
        return Icons.checkroom;
      case 'running shoes':
        return Icons.directions_run;
      case 'toothbrush':
        return Icons.cleaning_services;
      case 'sunscreen':
        return Icons.wb_sunny_outlined;
      case 'passport':
        return Icons.assignment_outlined;
    }

    switch (category) {
      case 'Clothing':
        return Icons.checkroom;
      case 'Toiletries':
        return Icons.cleaning_services;
      case 'Electronics':
        return Icons.devices;
      case 'Documents':
        return Icons.description_outlined;
      default:
        return Icons.category_outlined;
    }
  }
}
