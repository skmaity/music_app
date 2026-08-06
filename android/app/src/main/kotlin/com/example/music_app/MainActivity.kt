package com.shubha.music

import com.ryanheise.audioservice.AudioServiceActivity

// AudioServiceActivity, not FlutterActivity. It is a FlutterActivity subclass
// that keeps the Flutter engine attached while the media session is running, so
// tapping the notification card returns you to the app you were already using
// instead of cold-starting a second copy of it.
class MainActivity: AudioServiceActivity()
