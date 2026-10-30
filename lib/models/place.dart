class Place {
  final int id;
  final int tripId;
  String name;
  String address;
  double latitude;
  double longitude;

  Place({
    required this.id,
    required this.tripId,
    required this.name,
    this.address = '',
    this.latitude = 0.0,
    this.longitude = 0.0,
  }) {
    if (name.trim().isEmpty) {
      throw ArgumentError('Place name cannot be empty');
    }
    if (latitude < -90 || latitude > 90) {
      throw ArgumentError('Latitude must be between -90 and 90');
    }
    if (longitude < -180 || longitude > 180) {
      throw ArgumentError('Longitude must be between -180 and 180');
    }
  }

  Place.fromMap(Map<String, dynamic> map)
      : id = map['id'] as int,
        tripId = map['tripId'] as int,
        name = map['name'] as String,
        address = (map['address'] as String?) ?? '',
        latitude = (map['latitude'] as num).toDouble(),
        longitude = (map['longitude'] as num).toDouble();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tripId': tripId,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  @override
  String toString() => name;
}
