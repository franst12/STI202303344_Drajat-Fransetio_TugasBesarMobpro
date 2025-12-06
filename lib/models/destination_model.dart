import 'dart:convert';

class Destination {
  final int? id;
  final String name;
  final String description;
  final String address;
  final String openTime;
  final String closeTime; // FIELD BARU
  final List<String> imagePaths;
  final double latitude;
  final double longitude;

  Destination({
    this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.openTime,
    required this.closeTime, // FIELD BARU
    required this.imagePaths,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'address': address,
      'openTime': openTime,
      'closeTime': closeTime, // FIELD BARU
      'imagePath': jsonEncode(imagePaths),
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory Destination.fromMap(Map<String, dynamic> map) {
    List<String> images = [];
    if (map['imagePath'] != null && map['imagePath'].toString().isNotEmpty) {
      try {
        var decoded = jsonDecode(map['imagePath']);
        if (decoded is List) {
          images = List<String>.from(decoded);
        } else {
          images = [map['imagePath']];
        }
      } catch (e) {
        images = [map['imagePath']];
      }
    }

    return Destination(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      address: map['address'],
      openTime: map['openTime'],
      closeTime: map['closeTime'] ?? '17:00', // Default jika data lama null
      imagePaths: images,
      latitude: map['latitude'],
      longitude: map['longitude'],
    );
  }
}
