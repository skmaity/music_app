import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_app/services/services.dart';

class PlaylistPageFunction extends GetxController{
  FireStoreServices services = Get.put(FireStoreServices());


Future<void> addNewPlayList(BuildContext context) async {
  TextEditingController controller = TextEditingController();


  return showDialog<void>(
    context: context,
    barrierDismissible: true, // Allows the user to dismiss the dialog by tapping outside
    builder: (BuildContext context) {
      return BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 25, // Horizontal blur radius
          sigmaY: 25, // Vertical blur radius
        ),
        child: AlertDialog(
          backgroundColor: Colors.grey.shade100.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: BorderSide(
              width: 0.5,
              color: Colors.grey.shade100.withOpacity(0.4),
            ),
          ),
          title: const Text(
            'Add New Playlist',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter the name for your new playlist',
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  alignLabelWithHint: true,
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white30),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white30),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  suffixIcon: const Icon(
                    Icons.music_note_rounded,
                    color: Colors.white,
                  ),
                  hintText: "Playlist Name",
                  hintStyle: const TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Add',
                style: TextStyle(
                  color: Colors.amber,
                  shadows: [
                    Shadow(
                      color: Colors.amber,
                      blurRadius: 25,
                    ),
                  ],
                ),
              ),
              onPressed: () async {
                // Logic to handle playlist creation
                String playlistName = controller.text.trim();
                if (playlistName.isNotEmpty) {
              await services.addNewPlayList(playlistName);
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
    },
  );
}

  
}