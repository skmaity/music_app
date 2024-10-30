import 'dart:developer';

import 'package:get/get.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:music_app/controller/song_controller.dart';

class InternetController extends GetxController {
  
  RxBool internet = false.obs;

@override
  void onInit() {
    checkInternet();
    super.onInit();
  }

  final SongController _songController =  Get.put(SongController());

  checkInternet() async{
      log("The statement 'this machine is connected to the Internet' is: ");
  print(await InternetConnectionChecker().hasConnection);
  // returns a bool

  // We can also get an enum value instead of a bool
  log("Current status: ${await InternetConnectionChecker().connectionStatus}");
  // prints either InternetConnectionStatus.connected
  // or InternetConnectionStatus.disconnected

  // This returns the last results from the last call
  // to either hasConnection or connectionStatus
  // print("Last results: ${InternetConnectionChecker().lastTryResults}");

  // actively listen for status updates
  // this will cause InternetConnectionChecker to check periodically
  // with the interval specified in InternetConnectionChecker().checkInterval
  // until listener.cancel() is called
  var listener = InternetConnectionChecker().onStatusChange.listen((status) {
    switch (status) {
      case InternetConnectionStatus.connected:
        log('Data connection is available.');
        internet.value = true;
        break;
      case InternetConnectionStatus.disconnected:
        log('You are disconnected from the internet.');
        internet.value = false;
_songController.disposePlayer();
    break;
    }
  });
  }





}