import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:music_app/const/theme/app_theme.dart';
import 'package:music_app/core/bindings.dart';
import 'package:music_app/controller/settings_controller.dart';
import 'package:music_app/controller/userid_controller.dart';
import 'package:music_app/dashboard_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Must run before any AudioPlayer is constructed — SongController builds one
  // as a field, and bindings resolve it lazily, so "before runApp" is the only
  // place this is reliably early enough.
  //
  // ongoing + stopForegroundOnPause is the pair that makes the card behave the
  // way people expect: un-swipeable while music is actually playing, and
  // dismissible the moment it isn't.
  //
  // androidNotificationIcon is NOT left at its `mipmap/ic_launcher` default.
  // Android status-bar icons are a white-on-transparent mask — the system
  // throws away colour and keeps the alpha, so a full-colour launcher icon
  // renders as a solid grey square. ic_stat_nyro is the N-note mark as a
  // silhouette.
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.nyro.app.channel.audio',
    androidNotificationChannelName: 'Nyro playback',
    androidNotificationChannelDescription: 'Controls for the current track',
    androidNotificationIcon: 'drawable/ic_stat_nyro',
    androidNotificationOngoing: true,
    androidStopForegroundOnPause: true,
  );

  Get.put(UseridController());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
        title: kAppName,
        debugShowCheckedModeBanner: false,
        initialBinding: InitialScreenBindings(),
        theme: AppTheme.dark,
        home: const Dashboard());
  }
}
