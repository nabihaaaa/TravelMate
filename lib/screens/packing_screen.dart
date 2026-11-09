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

  // Categories match the comment in the PackingItem model.
  static const List<String> _categories = [
    'Clothing',
    'Toiletries',
    'Electronics',
    'Documents',
    'Other',
  ];

  // Only the packing items that belong to this trip.
  List<PackingItem> get _items => _service.packingFor(widget.trip.id);

  // ---------- saving + snackbars ----------

  // Saves everything through Person 4's storage, then shows a message.
  Future<void> _save(String successMessage) async {
    try {
      await _service.saveAllData();
      _showSnackBar(successMessage);
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

  // ---------- actions ----------

  // Checking/unchecking an item. Saves quietly (no snackbar every tap).
  Future<void> _togglePacked(PackingItem item, bool? value) async {
    setState(() => item.isPacked = value ?? false);
    try {
      await _service.saveAllData();
    } catch (error) {
      _showSnackBar('Could not save changes.');
    }
  }

  // Opens a dialog with a name field + category dropdown.
  Future<void> _addItem() async {
    final nameController = TextEditingController();
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
                  controller: nameController,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Item name'),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Please enter an item name'
                      : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: _categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => category = value ?? 'Other'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
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

    final item = PackingItem(
      id: _service.nextPackingId(),
      tripId: widget.trip.id,
      name: nameController.text.trim(),
      category: category,
    );

    setState(() => _service.packing.add(item));
    await _save('"${item.name}" added to your packing list');
  }

  // Asks for confirmation before deleting.
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
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _service.packing.removeWhere((p) => p.id == item.id));
    await _save('"${item.name}" removed');
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    final items = _items;
    final packedCount = items.where((i) => i.isPacked).length;

    // Our categories first, plus any unexpected ones from saved data.
    final categories = [
      ..._categories,
      ...items
          .map((i) => i.category)
          .where((c) => !_categories.contains(c))
          .toSet(),
    ];

    return Scaffold(
      appBar: AppBar(title: Text('Packing List · ${widget.trip.name}')),
      body: items.isEmpty
          ? _buildEmptyState()
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                _buildProgressCard(packedCount, items.length),
                for (final category in categories)
                  if (items.any((i) => i.category == category))
                    _buildCategorySection(
                      category,
                      items.where((i) => i.category == category).toList(),
                    ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addItem,
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
    );
  }

  Widget _buildProgressCard(int packed, int total) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              packed == total
                  ? 'All packed!'
                  : '$packed of $total items packed',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: total == 0 ? 0 : packed / total,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(String category, List<PackingItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
          child: Row(
            children: [
              Icon(
                _iconFor(category),
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(category, style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
        ),
        Card(
          child: Column(
            children: [
              for (final item in items)
                CheckboxListTile(
                  value: item.isPacked,
                  onChanged: (value) => _togglePacked(item, value),
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(
                    item.name,
                    style: TextStyle(
                      decoration: item.isPacked
                          ? TextDecoration.lineThrough
                          : null,
                      color: item.isPacked ? Colors.grey : null,
                    ),
                  ),
                  secondary: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Delete item',
                    onPressed: () => _deleteItem(item),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.luggage,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Nothing to pack yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap "Add Item" to start your packing list.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String category) {
    switch (category) {
      case 'Clothing':
        return Icons.checkroom;
      case 'Toiletries':
        return Icons.soap;
      case 'Electronics':
        return Icons.devices;
      case 'Documents':
        return Icons.description;
      default:
        return Icons.category;
    }
  }
}
