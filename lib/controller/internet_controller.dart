import 'dart:async';
import 'dart:developer';
import 'package:get/get.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:music_app/controller/song_controller.dart';

class InternetController extends GetxController {
  RxBool internet = false.obs;

  final SongController _songController = Get.find<SongController>();

  late StreamSubscription<InternetConnectionStatus> _listener;

  @override
  void onInit() {
    super.onInit();
    checkInternet();
  }

  @override
  void onClose() {
    _listener.cancel();
    super.onClose();
  }

  Future<void> checkInternet() async {
    InternetConnectionChecker internetConnectionChecker =
        InternetConnectionChecker.instance;
    final hasConnection = await internetConnectionChecker.hasConnection;
    internet.value = hasConnection;
    log("Internet available: $hasConnection");

    // Neither branch below touches the player's lifetime any more.
    //
    // Both used to call `SongController.disposePlayer()`, which called
    // `player.dispose()` — permanent — while `player` was built once as a
    // field and never rebuilt. One disconnect, or one merely *slow* reading,
    // killed the player for the rest of the session: every later seek, pause,
    // speed change and volume change threw into a disposed object, and the app
    // could only be recovered by restarting it. `disposePlayer()` no longer
    // exists; the player is disposed in `SongController.onClose` and nowhere
    // else.
    _listener = internetConnectionChecker.onStatusChange.listen((status) {
      switch (status) {
        case InternetConnectionStatus.connected:
          log('Connected to the internet.');
          internet.value = true;
          break;
        case InternetConnectionStatus.disconnected:
          log('Disconnected from the internet.');
          internet.value = false;
          // Pause rather than tear down. just_audio picks the stream back up
          // by itself once there is a connection again.
          _songController.pausePlaying();
          break;
        case InternetConnectionStatus.slow:
          log('Slow internet connection.');
          // Deliberately does not touch playback at all. "Slow" is not
          // "offline" — just_audio buffers through it, and cutting the audio
          // because a reachability probe was sluggish is worse than a moment
          // of rebuffering.
          internet.value = false;
          break;
      }
    });
  }
}
