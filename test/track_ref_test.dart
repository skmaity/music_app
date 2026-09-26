import 'package:flutter_test/flutter_test.dart';
import 'package:music_app/model/music_entities.dart';
import 'package:music_app/model/song_model.dart';
import 'package:music_app/model/source_capabilities.dart';
import 'package:music_app/model/track_ref.dart';

void main() {
  group('TrackRef', () {
    test('same provider ID remains distinct across all three sources', () {
      final refs = {
        for (final source in TrackSource.values)
          TrackRef(
            source: source,
            providerId: 'shared-id',
            title: 'Fixture',
            artist: 'Artist',
          ).stableKey,
      };

      expect(TrackSource.values, hasLength(3));
      expect(refs, hasLength(3));
    });

    test('legacy backend song round-trips without changing server ID', () {
      final legacy = MySongs(
        songid: 42,
        title: 'Hosted fixture',
        songurl: '/audio/42.mp3',
        coverurl: '/cover/42.jpg',
        artist: 'Nyro artist',
        isquickpick: 1,
      );

      final restored = TrackRef.fromSong(legacy).toSong();

      expect(restored.songid, 42);
      expect(restored.source, SongSource.backend);
      expect(restored.identity, 'backend:42');
      expect(restored.title, legacy.title);
      expect(restored.artist, legacy.artist);
      expect(restored.coverurl, legacy.coverurl);
      expect(restored.songurl, isEmpty,
          reason: 'TrackRef stores identity and metadata, not playback URLs.');
    });

    test('YouTube metadata persists without a resolved stream URL', () {
      final song = MySongs.youtube(
        videoId: 'video-1',
        title: 'YouTube fixture',
        artist: 'Uploader',
        artworkUrl: 'https://img.example/cover.jpg',
      ).copyWith(songurl: 'https://signed.example/temporary');

      final encoded = TrackRef.fromSong(song).toJson();
      final restored = TrackRef.fromJson(encoded);

      expect(encoded.keys, isNot(contains('songurl')));
      expect(encoded.keys, isNot(contains('streamUrl')));
      expect(restored.source, TrackSource.youtube);
      expect(restored.providerId, 'video-1');
      expect(restored.toSong().songurl, isEmpty);
    });

    test('legacy song JSON keeps only safe relative backend media paths', () {
      final relative = MySongs(
        songid: 1,
        title: 'Relative',
        songurl: '/audio/1.mp3',
        coverurl: '',
        artist: 'Artist',
        isquickpick: 0,
      );
      final signed = MySongs(
        songid: 2,
        title: 'Signed',
        songurl: 'https://media.example/2.mp3?token=secret',
        coverurl: '',
        artist: 'Artist',
        isquickpick: 0,
      );

      expect(relative.toJson()['songurl'], '/audio/1.mp3');
      expect(signed.toJson()['songurl'], isEmpty);

      for (final unsafe in [
        '//media.example/2.mp3',
        '/audio/2.mp3?token=secret',
        '/audio/2.mp3#temporary',
        'https://user:password@media.example/2.mp3',
      ]) {
        expect(signed.copyWith(songurl: unsafe).toJson()['songurl'], isEmpty,
            reason: 'Unsafe persistent media locator: $unsafe');
      }
      expect(
        signed
            .copyWith(
              source: SongSource.local,
              externalId: 'external:media:2',
              songurl: 'content://media/external/audio/2',
            )
            .toJson()['songurl'],
        isEmpty,
      );
    });

    test('local reference stores a stable provider identity', () {
      final ref = TrackRef(
        source: TrackSource.local,
        providerId: 'external:media:391',
        title: 'On-device fixture',
        artist: 'Local artist',
        duration: const Duration(minutes: 3),
      );

      final restored = TrackRef.fromJson(ref.toJson());

      expect(restored, ref);
      expect(restored.stableKey, 'local:external:media:391');
    });

    test('invalid persistent data is rejected instead of inventing identity',
        () {
      expect(
        () => TrackRef.fromJson({
          'source': 'youtube',
          'providerId': '',
          'title': 'Broken',
          'artist': 'Unknown',
        }),
        throwsFormatException,
      );
      expect(
        () => TrackRef.fromJson({
          'source': 'future-source',
          'providerId': 'id',
          'title': 'Broken',
          'artist': 'Unknown',
        }),
        throwsFormatException,
      );
    });
  });

  test('music entity identity includes source and entity type', () {
    const artist = ArtistRef(
      source: TrackSource.youtube,
      providerId: 'shared-id',
      name: 'Fixture artist',
    );
    const album = AlbumRef(
      source: TrackSource.youtube,
      providerId: 'shared-id',
      title: 'Fixture album',
      artist: 'Fixture artist',
    );

    expect(artist.stableKey, 'youtube:artist:shared-id');
    expect(album.stableKey, 'youtube:album:shared-id');
    expect(artist.stableKey, isNot(album.stableKey));
  });

  test('unsupported capabilities always expose an honest reason', () {
    final capabilities = SourceCapabilities(
      source: TrackSource.local,
      statuses: {
        for (final capability in MusicCapability.values)
          capability: capability == MusicCapability.offlinePlayback
              ? const CapabilityStatus.available()
              : CapabilityStatus.unavailable('Not available locally.'),
      },
    );

    expect(capabilities.supports(MusicCapability.offlinePlayback), isTrue);
    expect(capabilities.supports(MusicCapability.discovery), isFalse);
    expect(
      capabilities.status(MusicCapability.discovery).unavailableReason,
      'Not available locally.',
    );
    expect(
      () => CapabilityStatus.unavailable(''),
      throwsArgumentError,
    );
  });
}
