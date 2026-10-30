class Trip {
  final int id;
  String name;
  String destination;
  DateTime startDate;
  DateTime endDate;
  String? image; // optional cover photo path
  String notes;
  double? budget; // optional; Expenses screen needs it (not in the UML, see README)

  Trip({
    required this.id,
    required this.name,
    required this.destination,
    required this.startDate,
    required this.endDate,
    this.image,
    this.notes = '',
    this.budget,
  }) {
    if (name.trim().isEmpty) {
      throw ArgumentError('Trip name cannot be empty');
    }
    if (endDate.isBefore(startDate)) {
      throw ArgumentError('End date cannot be before start date');
    }
    if (budget != null && budget! < 0) {
      throw ArgumentError('Budget cannot be negative');
    }
  }

  // Named constructor: rebuild a Trip from a Map (used by storage, Person 4).
  Trip.fromMap(Map<String, dynamic> map)
      : id = map['id'] as int,
        name = map['name'] as String,
        destination = map['destination'] as String,
        startDate = DateTime.parse(map['startDate'] as String),
        endDate = DateTime.parse(map['endDate'] as String),
        image = map['image'] as String?,
        notes = (map['notes'] as String?) ?? '',
        budget = (map['budget'] as num?)?.toDouble();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'destination': destination,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'image': image,
      'notes': notes,
      'budget': budget,
    };
  }

  int get days => endDate.difference(startDate).inDays + 1;

  @override
  String toString() => '$name ($destination)';
}
