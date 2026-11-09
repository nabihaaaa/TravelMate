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

  static const List<String> _categories = [
    'Food',
    'Accommodation',
    'Transport',
    'Recreation',
    'Shopping',
    'Other',
  ];

  static const List<String> _filters = [
    'All',
    'Accommodation',
    'Food',
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

  static const Color _pink = Color(0xFFC15E76);
  static const Color _lightPink = Color(0xFFFFEEEE);

  String _selectedFilter = 'All';

  final _moneyFormatter = FilteringTextInputFormatter.allow(
    RegExp(r'^\d*\.?\d{0,2}'),
  );

  List<Expense> get _expenses {
    final list = _service.expensesFor(widget.trip.id);
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  List<Expense> get _visibleExpenses {
    if (_selectedFilter == 'All') return _expenses;

    if (_selectedFilter == 'Other') {
      return _expenses
          .where(
            (e) =>
                e.category == 'Transport' ||
                e.category == 'Recreation' ||
                e.category == 'Shopping' ||
                e.category == 'Other',
          )
          .toList();
    }

    return _expenses.where((e) => e.category == _selectedFilter).toList();
  }

  double get _total => _expenses.fold(0.0, (sum, e) => sum + e.amount);

  String _money(double value, {bool decimals = true}) {
    final parts = value.toStringAsFixed(decimals ? 2 : 0).split('.');
    final whole = parts[0];

    final formatted = whole.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );

    return '\$$formatted${decimals ? '.${parts[1]}' : ''}';
  }

  String _formatDate(DateTime d) =>
      '${_months[d.month - 1]} ${d.day}, ${d.year}';

  DateTime _defaultDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final inTrip =
        !today.isBefore(widget.trip.startDate) &&
        !today.isAfter(widget.trip.endDate);

    return inTrip ? today : widget.trip.startDate;
  }

  // ---------- saving ----------

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

  // ---------- budget ----------

  Future<void> _setBudget() async {
    String budgetText = widget.trip.budget?.toStringAsFixed(2) ?? '';

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Trip Budget'),
        content: Form(
          key: formKey,
          child: TextFormField(
            initialValue: budgetText,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [_moneyFormatter],
            decoration: const InputDecoration(
              labelText: 'Budget',
              prefixText: '\$ ',
            ),
            onChanged: (value) {
              budgetText = value;
            },
            validator: (value) {
              final number = double.tryParse(value?.trim() ?? '');
              if (number == null || number < 0) {
                return 'Please enter a valid amount';
              }
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
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, budgetText.trim());
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == null) return;

    final newBudget = result == 'clear' ? null : double.parse(result);

    if (!mounted) return;

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

  // ---------- add / edit / delete ----------

  Future<void> _openExpenseForm({Expense? existing}) async {
    String title = existing?.title ?? '';
    String amountText = existing?.amount.toStringAsFixed(2) ?? '';

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
                    initialValue: title,
                    autofocus: existing == null,
                    decoration: const InputDecoration(
                      labelText: 'What was it for?',
                    ),
                    onChanged: (value) {
                      title = value;
                    },
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Please enter a title'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: amountText,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [_moneyFormatter],
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      prefixText: '\$ ',
                    ),
                    onChanged: (value) {
                      amountText = value;
                    },
                    validator: (value) {
                      final number = double.tryParse(value?.trim() ?? '');
                      if (number == null || number <= 0) {
                        return 'Enter an amount greater than 0';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
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
      ),
    );

    if (saved != true) return;

    final amount = double.parse(amountText.trim());

    if (!mounted) return;

    if (existing == null) {
      final expense = Expense(
        id: _service.nextExpenseId(),
        tripId: widget.trip.id,
        title: title.trim(),
        amount: amount,
        category: category,
        date: date,
      );

      setState(() {
        _service.expenses.add(expense);
        _selectedFilter = 'All';
      });

      await _save('Expense added');
    } else {
      setState(() {
        existing.title = title.trim();
        existing.amount = amount;
        existing.category = category;
        existing.date = date;
        _selectedFilter = 'All';
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
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _service.expenses.removeWhere((e) => e.id == expense.id);
    });

    await _save('Expense deleted');
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    final budget = widget.trip.budget;
    final total = _total;
    final expenses = _visibleExpenses;

    final percentage = budget == null || budget <= 0
        ? 0
        : (total / budget * 100).round();

    return Scaffold(
      appBar: AppBar(title: Text('Expenses · ${widget.trip.name}')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              children: [
                _buildSummaryCard(total, budget, percentage),
                const SizedBox(height: 12),
                _buildFilters(),
                const SizedBox(height: 2),
                if (expenses.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('No expenses in this category.')),
                  )
                else
                  _buildExpenseList(expenses),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openExpenseForm(),
                icon: const Icon(Icons.add),
                label: const Text('Add Expense'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _pink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: const StadiumBorder(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- budget summary ----------

  Widget _buildSummaryCard(double total, double? budget, int percentage) {
    final remaining = budget == null ? null : budget - total;
    final overBudget = remaining != null && remaining < 0;

    return Card(
      color: _lightPink,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Total Budget',
                            style: TextStyle(fontSize: 12),
                          ),
                          IconButton(
                            onPressed: _setBudget,
                            icon: const Icon(Icons.edit, size: 15),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 28,
                              minHeight: 28,
                            ),
                            color: _pink,
                          ),
                        ],
                      ),
                      Text(
                        budget == null
                            ? 'Not set'
                            : _money(budget, decimals: false),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Total Spent',
                      style: TextStyle(fontSize: 12, color: _pink),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _money(total),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (budget == null)
              TextButton(onPressed: _setBudget, child: const Text('Set budget'))
            else ...[
              LinearProgressIndicator(
                value: budget <= 0
                    ? 0
                    : (total / budget).clamp(0.0, 1.0).toDouble(),
                minHeight: 7,
                borderRadius: BorderRadius.circular(8),
                backgroundColor: const Color(0xFFFFCDD5),
                color: overBudget ? Colors.red : _pink,
              ),
              const SizedBox(height: 7),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      overBudget
                          ? 'Over budget by ${_money(-remaining, decimals: false)}'
                          : '${_money(remaining!, decimals: false)} remaining',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  Text('$percentage%', style: const TextStyle(fontSize: 11)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------- category filters ----------

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
          selectedColor: _pink,
          backgroundColor: const Color(0xFFF5E7E8),
          labelStyle: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontSize: 11,
          ),
          onSelected: (_) {
            setState(() => _selectedFilter = label);
          },
        );
      }).toList(),
    );
  }

  // ---------- expense list ----------

  Widget _buildExpenseList(List<Expense> expenses) {
    return Card(
      color: Colors.white,
      child: Column(
        children: [
          for (int i = 0; i < expenses.length; i++) ...[
            _buildExpenseRow(expenses[i]),
            if (i != expenses.length - 1)
              const Divider(height: 1, indent: 12, endIndent: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildExpenseRow(Expense expense) {
    return InkWell(
      onTap: () => _openExpenseForm(existing: expense),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _iconBackground(expense.category),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _iconFor(expense.category),
                size: 19,
                color: _iconColor(expense.category),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${expense.category} · ${_formatDate(expense.date)}',
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              _money(expense.amount),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 20),
              onSelected: (value) {
                if (value == 'edit') {
                  _openExpenseForm(existing: expense);
                } else if (value == 'delete') {
                  _deleteExpense(expense);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _iconBackground(String category) {
    switch (category) {
      case 'Food':
        return const Color(0xFFFFE9D8);
      case 'Transport':
        return const Color(0xFFE8E7FA);
      default:
        return const Color(0xFFFFDDE3);
    }
  }

  Color _iconColor(String category) {
    switch (category) {
      case 'Food':
        return Colors.deepOrange;
      case 'Transport':
        return Colors.deepPurple;
      default:
        return const Color(0xFFAE526A);
    }
  }

  IconData _iconFor(String category) {
    switch (category) {
      case 'Food':
        return Icons.restaurant;
      case 'Accommodation':
        return Icons.hotel;
      case 'Transport':
        return Icons.directions_bus;
      case 'Recreation':
        return Icons.local_activity;
      case 'Shopping':
        return Icons.shopping_bag;
      default:
        return Icons.receipt_long;
    }
  }
}
