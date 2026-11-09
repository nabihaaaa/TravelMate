// File: expenses_screen.dart
// Purpose: Lets users record trip expenses, set a trip budget, and see
// total spending and remaining budget. Data is saved through TripService.
// Owner: Person 5 (M).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/expense.dart';
import '../models/trip.dart';
import '../services/trip_service.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key, required this.trip});

  final Trip trip;

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final TripService _service = TripService.instance;

  // Categories match the comment in the Expense model.
  static const List<String> _categories = [
    'Food',
    'Accommodation',
    'Transport',
    'Recreation',
    'Shopping',
    'Other',
  ];

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

  // Only allows numbers with up to 2 decimal places (e.g. 12.50).
  final _moneyFormatter = FilteringTextInputFormatter.allow(
    RegExp(r'^\d*\.?\d{0,2}'),
  );

  // This trip's expenses, newest first.
  List<Expense> get _expenses {
    final list = _service.expensesFor(widget.trip.id);
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  // Adds up every expense amount for this trip.
  double get _total => _expenses.fold(0.0, (sum, e) => sum + e.amount);

  String _money(double value) => '\$${value.toStringAsFixed(2)}';

  String _formatDate(DateTime d) =>
      '${_months[d.month - 1]} ${d.day}, ${d.year}';

  // New expenses default to today if we're during the trip,
  // otherwise to the trip's start date.
  DateTime _defaultDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final inTrip =
        !today.isBefore(widget.trip.startDate) &&
        !today.isAfter(widget.trip.endDate);
    return inTrip ? today : widget.trip.startDate;
  }

  // ---------- saving + snackbars ----------

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

  // ---------- budget ----------

  Future<void> _setBudget() async {
    final controller = TextEditingController(
      text: widget.trip.budget?.toStringAsFixed(2) ?? '',
    );
    final formKey = GlobalKey<FormState>();

    // Returns 'save', 'clear', or null (cancelled).
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Trip Budget'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [_moneyFormatter],
            decoration: const InputDecoration(
              labelText: 'Budget',
              prefixText: '\$ ',
            ),
            validator: (value) {
              final number = double.tryParse(value?.trim() ?? '');
              if (number == null) return 'Please enter a valid amount';
              return null;
            },
          ),
        ),
        actions: [
          if (widget.trip.budget != null)
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, 'clear'),
              child: const Text('Remove'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, 'save');
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == null) return;

    final newBudget = result == 'clear'
        ? null
        : double.parse(controller.text.trim());

    setState(() => widget.trip.budget = newBudget);

    try {
      await _service.updateTrip(widget.trip);
      _showSnackBar(
        newBudget == null
            ? 'Budget removed'
            : 'Budget set to ${_money(newBudget)}',
      );
    } catch (error) {
      _showSnackBar('Could not save budget.');
    }
  }

  // ---------- add / edit / delete expenses ----------

  // One form for both adding (existing == null) and editing.
  Future<void> _openExpenseForm({Expense? existing}) async {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final amountController = TextEditingController(
      text: existing?.amount.toStringAsFixed(2) ?? '',
    );
    final formKey = GlobalKey<FormState>();

    String category = existing?.category ?? 'Other';
    if (!_categories.contains(category)) category = 'Other';
    DateTime date = existing?.date ?? _defaultDate();

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Add Expense' : 'Edit Expense'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    autofocus: existing == null,
                    decoration: const InputDecoration(
                      labelText: 'What was it for?',
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'Please enter a title'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [_moneyFormatter],
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      prefixText: '\$ ',
                    ),
                    validator: (value) {
                      final number = double.tryParse(value?.trim() ?? '');
                      if (number == null) return 'Please enter an amount';
                      if (number <= 0) return 'Amount must be greater than 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: _categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (value) =>
                        setDialogState(() => category = value ?? 'Other'),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today),
                    title: Text(_formatDate(date)),
                    subtitle: const Text('Tap to change date'),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: dialogContext,
                        initialDate: date,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setDialogState(() => date = picked);
                      }
                    },
                  ),
                ],
              ),
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
              child: Text(existing == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );

    if (saved != true) return;

    final title = titleController.text.trim();
    final amount = double.parse(amountController.text.trim());

    if (existing == null) {
      final expense = Expense(
        id: _service.nextExpenseId(),
        tripId: widget.trip.id,
        title: title,
        amount: amount,
        category: category,
        date: date,
      );
      setState(() => _service.expenses.add(expense));
      await _save('Expense added');
    } else {
      setState(() {
        existing.title = title;
        existing.amount = amount;
        existing.category = category;
        existing.date = date;
      });
      await _save('Expense updated');
    }
  }

  Future<void> _deleteExpense(Expense expense) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete expense?'),
        content: Text('Remove "${expense.title}" (${_money(expense.amount)})?'),
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

    setState(() => _service.expenses.removeWhere((e) => e.id == expense.id));
    await _save('Expense deleted');
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    final expenses = _expenses;
    final total = _total;

    return Scaffold(
      appBar: AppBar(title: Text('Expenses · ${widget.trip.name}')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          _buildSummaryCard(total),
          const SizedBox(height: 16),
          if (expenses.isEmpty)
            _buildEmptyState()
          else ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
              child: Text(
                'Expenses (${expenses.length})',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            for (final expense in expenses) _buildExpenseTile(expense),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openExpenseForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
    );
  }

  // Total spent + budget progress (only shows the bar if a budget is set).
  Widget _buildSummaryCard(double total) {
    final budget = widget.trip.budget;
    final overBudget = budget != null && total > budget;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Total spent', style: textTheme.titleSmall),
                ),
                TextButton.icon(
                  onPressed: _setBudget,
                  icon: const Icon(Icons.edit, size: 18),
                  label: Text(budget == null ? 'Set budget' : 'Edit budget'),
                ),
              ],
            ),
            Text(
              _money(total),
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (budget == null) ...[
              const SizedBox(height: 8),
              Text('No budget set for this trip.', style: textTheme.bodyMedium),
            ] else ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: budget == 0
                    ? 1.0
                    : (total / budget).clamp(0.0, 1.0).toDouble(),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
                color: overBudget ? scheme.error : null,
              ),
              const SizedBox(height: 8),
              Text(
                overBudget
                    ? 'Over budget by ${_money(total - budget)}'
                    : '${_money(budget - total)} left of ${_money(budget)}',
                style: textTheme.bodyMedium?.copyWith(
                  color: overBudget ? scheme.error : null,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseTile(Expense expense) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(_iconFor(expense.category), size: 20),
        ),
        title: Text(expense.title),
        subtitle: Text('${expense.category} · ${_formatDate(expense.date)}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _money(expense.amount),
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete expense',
              onPressed: () => _deleteExpense(expense),
            ),
          ],
        ),
        onTap: () => _openExpenseForm(existing: expense),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'No expenses yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap "Add Expense" to record your first one.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String category) {
    switch (category) {
      case 'Food':
        return Icons.restaurant;
      case 'Accommodation':
        return Icons.hotel;
      case 'Transport':
        return Icons.directions_car;
      case 'Recreation':
        return Icons.local_activity;
      case 'Shopping':
        return Icons.shopping_bag;
      default:
        return Icons.receipt_long;
    }
  }
}
