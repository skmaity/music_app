  import 'package:get/get_rx/src/rx_types/rx_types.dart';

RxBool showArtistSongs = false.obs;
RxString selectedArtistName =  "".obs;

   void toggleSongs() {
    showArtistSongs.value = !showArtistSongs.value;
  }