import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response;
import 'package:music_app/apis/all_urls.dart';
import 'package:music_app/model/artist_model.dart';
import 'package:music_app/model/song_model.dart';

/// Artists, and whichever one is open.
///
/// This used to hold a single unused `selectedArtistIndex`, while the screen
/// itself read from `FireStoreServices` — a dead Firebase shell whose
/// `getArtists()` body was commented out and only cleared the list. The screen
/// was fully built and rendered nothing.
///
/// The two `showArtistSongs` / `selectedArtistName` globals that used to drive
/// the master–detail switch live here now as [selected].
class ArtistController extends GetxController {

  final RxList<Artist> artists = <Artist>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool hasError = false.obs;

  /// Null on the list, set on the detail view.
  final Rxn<Artist> selected = Rxn<Artist>();
  final RxList<MySongs> songs = <MySongs>[].obs;
  final RxBool isLoadingSongs = true.obs;
  final RxBool hasSongsError = false.obs;

  Future<void> getArtists() async {
    isLoading.value = true;
    hasError.value = false;
    try {
      final res = await api.get(allArtistsUrl);
      if (res.statusCode == 200 && res.data['success'] == true) {
        artists.value = (res.data['data'] as List)
            .map((e) => Artist.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } else {
        hasError.value = true;
      }
    } catch (e) {
      debugPrint('Failed to load artists: $e');
      hasError.value = true;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> open(Artist artist) async {
    selected.value = artist;
    await _loadSongs(artist.id);
  }

  void back() {
    selected.value = null;
    songs.clear();
  }

  Future<void> retrySongs() async {
    final artist = selected.value;
    if (artist != null) await _loadSongs(artist.id);
  }

  Future<void> _loadSongs(int artistId) async {
    isLoadingSongs.value = true;
    hasSongsError.value = false;
    songs.clear();
    try {
      final res = await api.get(
        artistDetailsUrl,
        queryParameters: {'artist_id': artistId},
      );
      // `artist` and `songs` sit at the top level here, not under `data`.
      if (res.statusCode == 200 && res.data['success'] == true) {
        songs.value = (res.data['songs'] as List? ?? [])
            .map((e) => MySongs.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } else {
        hasSongsError.value = true;
      }
    } catch (e) {
      debugPrint('Failed to load artist songs: $e');
      hasSongsError.value = true;
    } finally {
      isLoadingSongs.value = false;
    }
  }
}
