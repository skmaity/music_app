

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

  checkInternet() async {
    InternetConnectionChecker internetConnectionChecker = InternetConnectionChecker.instance;
    final hasConnection = await internetConnectionChecker.hasConnection;
    internet.value = hasConnection;
    log("Internet available: $hasConnection");

    _listener = internetConnectionChecker.onStatusChange.listen((status) {
      switch (status) {
        case InternetConnectionStatus.connected:
          log('Connected to the internet.');
          internet.value = true;
          break;
        case InternetConnectionStatus.disconnected:
          log('Disconnected from the internet.');
          internet.value = false;
          _songController.disposePlayer();
          break;
        case InternetConnectionStatus.slow:
          log('Slow internet connection.');
          internet.value = false;
          _songController.disposePlayer();
          break;
      }
    });
  }
}
