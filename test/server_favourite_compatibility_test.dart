import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_app/data/library_database.dart';
import 'package:music_app/main_nav_pages/user_favourite_songs/model/user_favourites_model.dart';
import 'package:music_app/model/song_model.dart';
import 'package:music_app/repositories/library_repository.dart';

void main() {
  test('legacy PHP favourite payload keeps backend IDs and cache boundary',
      () async {
    final payload = jsonEncode({
      'success': true,
      'favorites': [
        {
          'songid': '17',
          'title': 'Hosted favourite',
          'songurl': '/music/17.mp3',
          'coverurl': '/covers/17.jpg',
          'artist': 'Server artist',
          'isquickpick': '0',
        },
      ],
    });
    final parsed = userFavouritesModelFromJson(payload);
    expect(parsed.success, isTrue);
    expect(parsed.favorites.single.songid, 17);
    expect(parsed.favorites.single.isBackend, isTrue);
    expect(parsed.favorites.single.songurl, '/music/17.mp3');

    final database = LibraryDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = LibraryRepository(database);
    final cached = await repository.cacheServerFavourites([
      ...parsed.favorites,
      MySongs.youtube(
        videoId: 'must-stay-local',
        title: 'YouTube favourite',
        artist: 'Video artist',
        artworkUrl: '',
      ),
    ]);

    final favourites = await repository.listFavourites();
    expect(cached, 1);
    expect(favourites.map((track) => track.stableKey), ['backend:17']);
    expect(
      await repository.favouriteOrigin(favourites.single),
      FavouriteOrigin.serverCache,
    );
  });
}
