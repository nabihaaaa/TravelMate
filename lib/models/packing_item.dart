class PackingItem {
  final int id;
  final int tripId;
  String name;
  String category; // e.g. Clothing, Toiletries, Electronics, Documents, Other
  bool isPacked;

  PackingItem({
    required this.id,
    required this.tripId,
    required this.name,
    this.category = 'Other',
    this.isPacked = false,
  }) {
    if (name.trim().isEmpty) {
      throw ArgumentError('Item name cannot be empty');
    }
  }

  PackingItem.fromMap(Map<String, dynamic> map)
      : id = map['id'] as int,
        tripId = map['tripId'] as int,
        name = map['name'] as String,
        category = (map['category'] as String?) ?? 'Other',
        isPacked = (map['isPacked'] as bool?) ?? false;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tripId': tripId,
      'name': name,
      'category': category,
      'isPacked': isPacked,
    };
  }

  @override
  String toString() => '$name (${isPacked ? 'packed' : 'not packed'})';
}
