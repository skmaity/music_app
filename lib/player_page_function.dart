import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';

class PlayerPageFunction extends GetxController {
  songAddedToFaviorateAlert(context, songTitle) {
    return Get.snackbar(
      duration: const Duration(seconds: 4),
      icon: const Icon(
        FontAwesome.heart,
        color: Colors.white,
        shadows: [
          Shadow( 
            blurRadius: 9.0,
            color: Colors.white,
            offset: Offset(0, 0),
          ),
        ],
      ),

      reverseAnimationCurve: Curves.decelerate,
      forwardAnimationCurve: Curves.decelerate,
      borderColor: Colors.white.withOpacity(0.2),
      isDismissible: true,
      margin: const EdgeInsets.symmetric(vertical: 30, horizontal: 10),
      borderWidth: 0.5,
      // Messages
      "Song Added to Favorites!",
      "Great choice! This song is now part of your favorites. 🎧💖",

      // Designs
      animationDuration: const Duration(milliseconds: 600),
      colorText: Colors.white,

      titleText: Text(
        songTitle,
        style: const TextStyle(color: Colors.white,fontWeight: FontWeight.bold),
      ),
    );
  }

  songRemovedFromFaviorateAlert(context, songTitle) {
    return Get.snackbar(
      duration: const Duration(seconds: 4),
      icon: const Icon(
               FontAwesomeIcons.heartCrack,
        color: Colors.white,
        shadows: [
          Shadow(
            blurRadius: 9.0,
            color: Colors.white,
            offset: Offset(0, 0),
          ),
        ],
      ),

      reverseAnimationCurve: Curves.decelerate,
      forwardAnimationCurve: Curves.decelerate,
      borderColor: Colors.white.withOpacity(0.2),
      isDismissible: true,
      margin: const EdgeInsets.symmetric(vertical: 30, horizontal: 10),
      borderWidth: 0.5,
      // Messages
      "Song Removed from Favorites!",
      "Noted! You can add it back anytime. 🎧✨",

      // Designs
      animationDuration: const Duration(milliseconds: 600),
      colorText: Colors.white,
    );
  }
}
