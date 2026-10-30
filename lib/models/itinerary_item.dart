class ItineraryItem {
  final int id;
  final int tripId;
  String title;
  DateTime date;
  String startTime; // e.g. '2:00 PM' (String, as in the UML)
  String location;
  String notes;

  ItineraryItem({
    required this.id,
    required this.tripId,
    required this.title,
    required this.date,
    required this.startTime,
    this.location = '',
    this.notes = '',
  }) {
    if (title.trim().isEmpty) {
      throw ArgumentError('Activity title cannot be empty');
    }
  }

  ItineraryItem.fromMap(Map<String, dynamic> map)
      : id = map['id'] as int,
        tripId = map['tripId'] as int,
        title = map['title'] as String,
        date = DateTime.parse(map['date'] as String),
        startTime = map['startTime'] as String,
        location = (map['location'] as String?) ?? '',
        notes = (map['notes'] as String?) ?? '';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tripId': tripId,
      'title': title,
      'date': date.toIso8601String(),
      'startTime': startTime,
      'location': location,
      'notes': notes,
    };
  }

  @override
  String toString() => '$title at $startTime';
}
