class Expense {
  final int id;
  final int tripId;
  String title;
  double amount;
  String category; // Food, Accommodation, Transport, Recreation, Shopping, Other
  DateTime date;

  Expense({
    required this.id,
    required this.tripId,
    required this.title,
    required this.amount,
    this.category = 'Other',
    required this.date,
  }) {
    if (title.trim().isEmpty) {
      throw ArgumentError('Expense title cannot be empty');
    }
    if (amount <= 0) {
      throw ArgumentError('Amount must be greater than 0');
    }
  }

  Expense.fromMap(Map<String, dynamic> map)
      : id = map['id'] as int,
        tripId = map['tripId'] as int,
        title = map['title'] as String,
        amount = (map['amount'] as num).toDouble(),
        category = (map['category'] as String?) ?? 'Other',
        date = DateTime.parse(map['date'] as String);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tripId': tripId,
      'title': title,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
    };
  }

  @override
  String toString() => '$title: \$${amount.toStringAsFixed(2)}';
}
