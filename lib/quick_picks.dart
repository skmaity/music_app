import 'dart:developer';

import 'package:flutter/material.dart';
// import 'package:flutter_glow/flutter_glow.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:music_app/controller/song_controller.dart';
import 'package:music_app/player_page.dart';
import 'package:music_app/services/services.dart';

class QuickPicks extends StatefulWidget {
  const QuickPicks({super.key});

  @override
  State<QuickPicks> createState() => _QuickPicksState(); 
}

class _QuickPicksState extends State<QuickPicks> {
  late FireStoreServices services;
  late SongController controller;
  @override
  void initState() {
    controller = Get.put(SongController());
    services = Get.put(FireStoreServices());

    super.initState();

  }


  TextStyle style = GoogleFonts.pacifico().copyWith(
                        fontSize: 45, color: Colors.white);

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        children: [
          services.quickpicks.isEmpty
              ?  Center(
                  child: Column(
                        children: [
                           const SizedBox(
                            height: 10,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Padding(
                                padding:
                                     const EdgeInsets.only(right: 10, top: 40),
                                child: Text(
                                  'Quick picks',
                                  style: style,
                                ),
                              ),
                               const SizedBox(
                                width: 10,
                              ),

                            ],
                          ),
                  // Center(child: const Text('No songs avalable')),

                        ],
                  ),
                  
                  
                )
              : Expanded(
  child: ListView.builder(
    itemCount: services.quickpicks.length + 1, // Adjusted item count
    itemBuilder: (context, index) {
      
      if (index == 0) { // This is the first widget at index 0
        return Column(
          children: [
            const SizedBox(
              height: 10,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 10, top: 40),
                  child: Text(
                    'Quick picks',
                    style: style,
                  ),
                ),
                const SizedBox(
                  width: 10,
                )
              ],
            ),
          ],
        ); 
      } else {
        // Adjust index by subtracting 1 when accessing quickpicks
        final quickpick = services.quickpicks[index - 1];
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Material(
            color: Colors.transparent,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
              onTap: () {
                controller.startPlaying(quickpick).then((_) {
                  controller.currentIndex.value = index - 1;
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PlayerPage()),
                  );
                });
              },
              tileColor: Colors.grey.shade100.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  width: 0.5,
                  color: Colors.grey.shade200.withOpacity(0.4),
                ),
              ),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 50,
                  width: 50,
                  child: Image(
                    image: NetworkImage(quickpick.cover),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              title: Text(
                quickpick.title,
                style: const TextStyle(
                  color: Colors.white,
                ),
                maxLines: 1,
              ),
              subtitle: Text(
                quickpick.artist,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
                maxLines: 1,
              ),
              // trailing: IconButton(
              //   onPressed: () {
              //     // Additional functionality for trailing icon if needed
              //   },
              //   icon: const SizedBox(
              //     width: 20,
              //     child: GlowIcon(
              //       Icons.play_arrow_rounded,
              //       color: Colors.white,
              //     ),
              //   ),
              // ),
            ),
          ),
        );
      }
    },
  ),
),

        ],
      ),
    );
  }
}
