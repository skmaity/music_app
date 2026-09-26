import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:music_app/controller/internet_controller.dart';
import 'package:music_app/controller/nav_controller.dart';
import 'package:music_app/controller/source_access_policy.dart';
import 'package:music_app/model/track_ref.dart';

void main() {
  test('connectivity state can exist without constructing or finding a player',
      () {
    final controller = InternetController();
    expect(controller.internet.value, isFalse);
  });

  test('a late connectivity probe cannot subscribe or update after close',
      () async {
    final probe = Completer<bool>();
    var listens = 0;
    final statuses = StreamController<InternetConnectionStatus>.broadcast(
      onListen: () => listens++,
    );
    final controller = InternetController(
      probe: () => probe.future,
      statuses: () => statuses.stream,
    );

    final check = controller.checkInternet();
    controller.onClose();
    probe.complete(true);
    await check;
    statuses.add(InternetConnectionStatus.connected);
    await Future<void>.delayed(Duration.zero);

    expect(controller.internet.value, isFalse);
    expect(listens, 0);
    await statuses.close();
  });

  test(
      'offline access remains available for local, library, downloads and settings',
      () {
    for (final destination in AppDestination.values) {
      expect(
        SourceAccessPolicy.canOpen(
          source: TrackSource.local,
          destination: destination,
          online: false,
        ),
        isTrue,
        reason: 'Local $destination should work offline.',
      );
    }

    for (final source in [TrackSource.nyroServer, TrackSource.youtube]) {
      for (final destination in [
        AppDestination.library,
        AppDestination.downloads,
        AppDestination.settings,
      ]) {
        expect(
          SourceAccessPolicy.canOpen(
            source: source,
            destination: destination,
            online: false,
          ),
          isTrue,
          reason: '$destination must remain reachable offline.',
        );
      }
    }
  });

  test('offline remote browsing is blocked without replacing global navigation',
      () {
    for (final source in [TrackSource.nyroServer, TrackSource.youtube]) {
      for (final destination in [
        AppDestination.quickPicks,
        AppDestination.songs,
        AppDestination.favourites,
        AppDestination.artists,
      ]) {
        expect(
          SourceAccessPolicy.canOpen(
            source: source,
            destination: destination,
            online: false,
          ),
          isFalse,
        );
      }
    }
  });

  test('online browsing permits every source and destination', () {
    for (final source in TrackSource.values) {
      for (final destination in AppDestination.values) {
        expect(
          SourceAccessPolicy.canOpen(
            source: source,
            destination: destination,
            online: true,
          ),
          isTrue,
        );
      }
    }
  });
}
