class Artist {
  final String id;  // Added ID field
  final String name;
  final String imageUrl;

  Artist({
    required this.id,
    required this.name,
    required this.imageUrl,
  });

  // Factory constructor to create an Artist from a JSON map
  factory Artist.fromJson(Map<String, dynamic> json, String id) {
    return Artist(
      id: id,  // Assign the ID here
      name: json['name'],
      imageUrl: json['imageUrl'],
    );
  }

  // Method to convert an Artist object to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'imageUrl': imageUrl,
    };
  }
}
