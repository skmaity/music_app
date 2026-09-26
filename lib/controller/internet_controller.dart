import 'dart:async';
import 'dart:developer';

import 'package:get/get.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

typedef ConnectionProbe = Future<bool> Function();
typedef ConnectionStatuses = Stream<InternetConnectionStatus> Function();

class InternetController extends GetxController {
  InternetController({
    ConnectionProbe? probe,
    ConnectionStatuses? statuses,
  })  : _probe = probe ?? _defaultProbe,
        _statuses = statuses ?? _defaultStatuses;

  final RxBool internet = false.obs;
  final ConnectionProbe _probe;
  final ConnectionStatuses _statuses;

  StreamSubscription<InternetConnectionStatus>? _listener;
  int _checkGeneration = 0;
  bool _closed = false;

  @override
  void onInit() {
    super.onInit();
    checkInternet();
  }

  @override
  void onClose() {
    _closed = true;
    _checkGeneration++;
    _listener?.cancel();
    _listener = null;
    super.onClose();
  }

  Future<void> checkInternet() async {
    final generation = ++_checkGeneration;

    final previous = _listener;
    _listener = null;
    await previous?.cancel();

    final hasConnection = await _probe();
    if (_closed || generation != _checkGeneration) return;

    internet.value = hasConnection;
    log('Internet available: $hasConnection');

    _listener = _statuses().listen((status) {
      if (_closed || generation != _checkGeneration) return;
      switch (status) {
        case InternetConnectionStatus.connected:
          log('Connected to the internet.');
          internet.value = true;
        case InternetConnectionStatus.disconnected:
          log('Disconnected from the internet.');
          internet.value = false;
        case InternetConnectionStatus.slow:
          log('Slow internet connection.');
          // Slow is still connected. It must not hide remote browsing or touch
          // playback; individual requests own their loading/error states.
          internet.value = true;
      }
    });
  }

  static Future<bool> _defaultProbe() =>
      InternetConnectionChecker.instance.hasConnection;

  static Stream<InternetConnectionStatus> _defaultStatuses() =>
      InternetConnectionChecker.instance.onStatusChange;
}
