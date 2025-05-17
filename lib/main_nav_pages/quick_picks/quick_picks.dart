import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:music_app/all_urls.dart';
import 'package:music_app/controller/song_controller.dart';
import 'package:music_app/main_nav_pages/quick_picks/quick_picks_controller.dart';
import 'package:music_app/player_page.dart';
// import 'package:music_app/player_page.dart';
// import 'package:music_app/services/services.dart';

class QuickPicks extends StatefulWidget {
  const QuickPicks({super.key});

  @override
  State<QuickPicks> createState() => _QuickPicksState();
}

class _QuickPicksState extends State<QuickPicks> {
  // late FireStoreServices services;
  late SongController controller;
  late QuickPicksController quickpicksController;
  @override
  void initState() {
    controller = Get.find<SongController>();
    // services = Get.find<FireStoreServices>();
    quickpicksController = Get.find<QuickPicksController>();
    quickpicksController.getQuickPicks();
    super.initState();
  }

  TextStyle style = const TextStyle(fontSize: 45, color: Colors.white);

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        children: [
          Center(
            child: Column(
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
                    ),
                  ],
                ),
                // Center(child: const Text('No songs avalable')),
              ],
            ),
          ),
          Expanded(
  child: AnimationLimiter(
    child: ListView.builder(  
      itemCount: quickpicksController.quickpicks.length, 
      itemBuilder: (context, index) {
        final quickpick = quickpicksController.quickpicks[index];
        return AnimationConfiguration.staggeredList(
          position: index,
          delay: const Duration(milliseconds: 100),
          child: SlideAnimation(
            verticalOffset: 50.0,
            horizontalOffset: 100,
            duration: const Duration(milliseconds: 300),
            child: FadeInAnimation(
              child: Obx(
                () => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Material(
                    color: Colors.transparent,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                      onTap: () {
                        controller.startPlaying(quickpick); 
                        // services.currentPlayingList = services.quickpicks;
                        controller.currentIndex.value = index;
                        Navigator.push(
                          context,
                          MaterialPageRoute( 
                            builder: (context) => const PlayerPage(),
                          ),
                        );
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
                          child: CachedNetworkImage(imageUrl: '$baseUrl${quickpick.coverurl}'), 
                        ),
                      ),
                      title: Text(
                        quickpick.title,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 1,
                      ),
                      subtitle: Text(
                        quickpick.artist,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        maxLines: 1,
                      ),
                      trailing: controller.currentIndex.value == index 
                          ? Lottie.asset('assets/lottie_animations/musics_floating.json')
                          : const SizedBox(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ); 
      },
    ),
  ),
)
        ],
      ),
    );
  }
}
