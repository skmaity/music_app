import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:music_app/apis/all_urls.dart';
import 'package:music_app/controller/song_controller.dart';
import 'package:music_app/main_nav_pages/search_songs/controllers/search_song_controller.dart';
import 'package:music_app/model/song_model.dart';
import 'package:music_app/player_page/player_page.dart';

class SearchSongs extends StatefulWidget {
  const SearchSongs({super.key});

  @override
  State<SearchSongs> createState() => _SearchSongsState();
}

class _SearchSongsState extends State<SearchSongs> {
  TextEditingController songQuery = TextEditingController();
  @override
  void initState() {
    super.initState();
  }

  SearchSongController controller = Get.put(SearchSongController());
  SongController songController = Get.put(SongController());
  FocusNode focus = FocusNode();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.transparent,
        body: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Column(
            children: [
              const SizedBox(
                height: 10,
              ),
              const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: EdgeInsets.only(right: 10, top: 40),
                    child: Text(
                      'Songs',
                      style: TextStyle(fontSize: 45, color: Colors.white),
                    ),
                  ),
                  SizedBox(
                    width: 10,
                  )
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: TextField(
                  focusNode: focus,
                  controller: songQuery,
                  onChanged: (v) async {
                    controller.searchSong(v);
                  },
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                      alignLabelWithHint: true,

                      // normal border
                      enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white30),
                          borderRadius: BorderRadius.all(Radius.circular(15))),

                      // focused border
                      focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white30),
                          borderRadius: BorderRadius.all(Radius.circular(15))),
                      suffixIcon: Icon(
                        Icons.music_note_rounded,
                        color: Colors.white,
                      ),
                      hintText: "What's on your mind",
                      hintStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)))),
                ),
              ),
              SizedBox(
                height: 20,
              ),
              Obx(() => controller.isLoading.value
                  ? Expanded(child: Center(child: CircularProgressIndicator()))
                  : Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              padding: EdgeInsets.all(0),
                              itemCount: controller.searchSongResult.length,
                              itemBuilder: (context, index) {
                                MySongs searchSong =
                                    controller.searchSongResult[index];
                                return AnimationConfiguration.staggeredList(
                                  position: index,
                                  delay: const Duration(milliseconds: 100),
                                  child: SlideAnimation(
                                    verticalOffset: 50.0,
                                    horizontalOffset: 100,
                                    duration: const Duration(milliseconds: 300),
                                    child: FadeInAnimation(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 5),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: ListTile(
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 10),
                                            onTap: () async {
                                              focus.unfocus();
                                              await Future.delayed(
                                                  Duration(milliseconds: 400));
                                              songController
                                                  .startPlaying(searchSong);
                                              songController
                                                      .currentPlayingList =
                                                  controller.searchSongResult;
                                              songController
                                                  .currentIndex.value = index;
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      const PlayerPage(),
                                                ),
                                              );
                                            },
                                            tileColor: Colors.grey.shade100
                                                .withOpacity(0.1),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              side: BorderSide(
                                                width: 0.5,
                                                color: Colors.grey.shade200
                                                    .withOpacity(0.4),
                                              ),
                                            ),
                                            leading: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: SizedBox(
                                                height: 50,
                                                width: 50,
                                                child: CachedNetworkImage(
                                                    imageUrl:
                                                        '$baseUrl${searchSong.coverurl}'),
                                              ),
                                            ),
                                            title: Text(
                                              searchSong.title,
                                              style: const TextStyle(
                                                  color: Colors.white),
                                              maxLines: 1,
                                            ),
                                            subtitle: Text(
                                              searchSong.artist,
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12),
                                              maxLines: 1,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          )
                        ],
                      ),
                    ))
            ],
          ),
        ));
  }
}
