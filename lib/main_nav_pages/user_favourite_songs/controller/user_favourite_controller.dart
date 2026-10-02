import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:music_app/apis/all_urls.dart';
import 'package:music_app/controller/userid_controller.dart';
import 'package:music_app/main_nav_pages/user_favourite_songs/model/user_favourites_model.dart';
import 'package:music_app/model/song_model.dart';
import 'package:music_app/model/track_ref.dart';
import 'package:music_app/repositories/library_repository.dart';

typedef YoutubeFavouriteResolver = Future<MySongs> Function(MySongs song);

class UserFavouriteController extends GetxController {
  UserFavouriteController({
    LibraryRepository? library,
    YoutubeFavouriteResolver? resolveYoutube,
  })  : _library = library,
        _resolveYoutube = resolveYoutube;

  final LibraryRepository? _library;
  final YoutubeFavouriteResolver? _resolveYoutube;
  int _loadGeneration = 0;
  TrackSource? _activeSource;

  TrackSource? get activeSource => _activeSource;

  RxList<MySongs> userFavoutitesList = <MySongs>[].obs;

  /// Starts true so the first frame shows the skeleton, not the empty state.
  RxBool isLoading = true.obs;

  /// A failed request is not an empty list. "You have no favourites" and "the
  /// request failed" used to be pixel-identical.
  RxBool hasError = false.obs;

  Future<MySongs> prepareForPlayback(MySongs song) async {
    if (!song.isYouTube) return song;
    final resolve = _resolveYoutube;
    if (resolve == null) {
      throw StateError('YouTube playback resolver is unavailable.');
    }
    return resolve(song);
  }

  Future<void> loadFavourites(TrackSource source) async {
    _activeSource = source;
    final generation = ++_loadGeneration;
    isLoading.value = true;
    hasError.value = false;
    if (source == TrackSource.local) {
      userFavoutitesList.clear();
      isLoading.value = false;
      return;
    }
    if (source == TrackSource.nyroServer) {
      return _getUserFavourites(generation);
    }

    try {
      final library = _library;
      if (library == null) {
        throw StateError('Library repository is unavailable.');
      }
      final favourites = await library.listFavourites(source: source);
      if (generation != _loadGeneration) return;
      userFavoutitesList.value =
          favourites.map((track) => track.toSong()).toList(growable: false);
    } catch (error) {
      if (generation != _loadGeneration) return;
      debugPrint('Failed to load ${source.label} favourites: $error');
      hasError.value = true;
    } finally {
      if (generation == _loadGeneration) isLoading.value = false;
    }
  }

  /// The id is resolved here rather than passed in: it is loaded from disk, and
  /// every caller that read it off the observable risked sending an empty one
  /// and getting "Missing userid" back.
  Future<void> refreshServerFavouritesIfVisible() {
    if (_activeSource != TrackSource.nyroServer) return Future<void>.value();
    return getUserFavourites();
  }

  Future<void> getUserFavourites() {
    _activeSource = TrackSource.nyroServer;
    final generation = ++_loadGeneration;
    isLoading.value = true;
    hasError.value = false;
    return _getUserFavourites(generation);
  }

  Future<void> _getUserFavourites(int generation) async {
    final payLoad = {"userid": await Get.find<UseridController>().id};
    if (generation != _loadGeneration) return;
    try {
      // Must be POST: the host returns 403 for a GET carrying a body.
      final response = await api.post(getAllUserFavoiritesUrl, data: payLoad);
      if (generation != _loadGeneration) return;
      if (response.statusCode == 200) {
        final favourites =
            userFavouritesModelFromJson(jsonEncode(response.data)).favorites;
        userFavoutitesList.value = favourites;
        try {
          await _library?.cacheServerFavourites(favourites);
        } catch (e) {
          // The server list remains authoritative for this screen. A cache
          // failure must not turn a successful network response into an error.
          debugPrint('Failed to cache server favourites: $e');
        }
      } else {
        hasError.value = true;
      }
    } catch (e) {
      if (generation != _loadGeneration) return;
      debugPrint('Failed to load favourites: $e');
      hasError.value = true;
    } finally {
      if (generation == _loadGeneration) isLoading.value = false;
    }
  }
}
