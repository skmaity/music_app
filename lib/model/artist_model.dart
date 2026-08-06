/// An artist, as `get_all_artists.php` and `get_artist_details.php` return one.
///
/// The old model expected `id` (a String) and `imageUrl`; the API sends
/// `artist_id` (an **int**) and `imageurl` (lowercase), which is why the screen
/// rendered nothing even once the endpoints existed.
class Artist {
  const Artist({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.bio,
    this.totalSongs = 0,
  });

  final int id;
  final String name;

  /// **Relative** — prefix with `baseUrl`, like every other image in the app.
  final String imageUrl;

  /// Nullable in the database, and null in practice today.
  final String? bio;

  /// Only `get_all_artists.php` carries this; the details endpoint's `artist`
  /// object does not, so a detail view counts the songs it was given.
  final int totalSongs;

  factory Artist.fromJson(Map<String, dynamic> json) => Artist(
        id: int.tryParse('${json['artist_id']}') ?? 0,
        name: json['name'] as String? ?? 'Unknown artist',
        imageUrl: json['imageurl'] as String? ?? '',
        bio: json['bio'] as String?,
        totalSongs: int.tryParse('${json['total_songs']}') ?? 0,
      );
}
