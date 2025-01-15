class ArtistDocid {
  final String docId;

  ArtistDocid({
    required this.docId,

  });

  // Factory constructor to create an Artist from a JSON map
  factory ArtistDocid.fromJson(Map<String, dynamic> json) {
    return ArtistDocid(
      docId: json['docId'],
    );
  }

  // Method to convert an Artist object to JSON map
  Map<String, dynamic> toJson() {
    return {
      'docId': docId,
    };
  }
}
