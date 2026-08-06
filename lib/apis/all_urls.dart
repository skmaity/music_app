import 'package:dio/dio.dart';

String myWebHost = 'https://workwithshubh.online/';
String myDir = 'music_apis/';
String baseUrl = "$myWebHost$myDir";

/// The one Dio the whole app makes requests through.
///
/// Five controllers each built a bare `Dio()`, and a bare Dio has **no
/// timeouts at all** — the defaults are null, meaning wait forever. Every
/// screen already had a loading state and an error state; nothing bounded how
/// long the first one lasted before the second could appear, so a host that
/// accepted a connection and then went quiet left the app spinning
/// indefinitely with no way back but a restart.
///
/// The numbers are deliberately generous. This app streams from shared hosting
/// to phones on mobile data, and a timeout that fires on a merely slow
/// connection turns a slow screen into a broken one.
final Dio api = Dio(BaseOptions(
  connectTimeout: const Duration(seconds: 10),
  receiveTimeout: const Duration(seconds: 15),
  sendTimeout: const Duration(seconds: 10),
));

String quickPicksUrl = "${baseUrl}get_quick_picks.php";
String searchSongsUrl = "${baseUrl}search_songs.php";

/// The whole songs table, unfiltered. Verified live 2026-08-06: rows carry no
/// `created_at` or other date field, so this is "All songs" — there is
/// nothing to sort by "recently added" without inventing an order the data
/// doesn't actually support.
String allSongsUrl = "${baseUrl}get_all_songs.php";
String addToFavouriteUrl = "${baseUrl}add_to_fav.php";
String removeFromFavouriteUrl = "${baseUrl}remove_from_fav.php";
String checkIfFavouriteUrl = "${baseUrl}check_if_favourite.php";
String getAllUserFavoiritesUrl = "${baseUrl}get_user_favourites.php";
String allArtistsUrl = "${baseUrl}get_all_artists.php";

/// Takes `?artist_id=<int>`. Unlike every other endpoint, it returns `artist`
/// and `songs` at the **top level** rather than under `data`.
String artistDetailsUrl = "${baseUrl}get_artist_details.php";
