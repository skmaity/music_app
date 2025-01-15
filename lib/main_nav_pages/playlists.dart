import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:get/get.dart';
import 'package:music_app/controller/song_controller.dart';
import 'package:music_app/main_nav_pages/page_controller/page_controller.dart';
import 'package:music_app/player_page.dart';
import 'package:music_app/playlist_page_function.dart';
import 'package:music_app/services/services.dart';

class Playlists extends StatefulWidget {
  const Playlists({super.key});

  @override
  State<Playlists> createState() => _PlaylistsState();
}

class _PlaylistsState extends State<Playlists> {

  PageControllerNavPages pageController = Get.put(PageControllerNavPages());

  @override
  Widget build(BuildContext context) {
    return Obx(
      ()=> Scaffold(
        backgroundColor: Colors.transparent,
        body: pageController.goInsidePlayList.value ? const InsidePlayList() :const PlayListWidgets(),
      ),
    );
  }
}

class InsidePlayList extends StatefulWidget {
  const InsidePlayList({super.key});

  @override
  State<InsidePlayList> createState() => _InsidePlayListState();
}

class _InsidePlayListState extends State<InsidePlayList> {

  late FireStoreServices services;

  PageControllerNavPages pageController = Get.put(PageControllerNavPages());


  @override
  void initState() {
    services = Get.put(FireStoreServices());
    services.getSongsFromFavorites();
    super.initState();
  }
  TextStyle style = const TextStyle(fontSize: 45, color: Colors.white);
  SongController controller = SongController();

  @override
  Widget build(BuildContext context) {
   return  Obx(
      () => Column(
        children: [
            Center(
                  child: Column(
                        children: [
                           const SizedBox(
                            height: 10,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                           Padding(
                             padding:
                                     const EdgeInsets.only(right: 10, top: 40),
                             child: IconButton(
                                                     
                                                     onPressed: (){
                             pageController.goInsidePlayList.value = ! pageController.goInsidePlayList.value;
                                                     },
                                                    icon: const Icon(
                                                     color: Colors.white,
                                                     shadows: [
                                                       Shadow(blurRadius: 9.0, color: Colors.white70, offset: Offset(0, 0))
                                                     ],
                                                     Icons.arrow_back_ios_rounded)),
                           ),

                              Row(
                                children: [
                                  Padding(
                                    padding:
                                         const EdgeInsets.only(right: 20, top: 40,),
                                    child: Text(
                                      'favorite',
                                      style: style,
                                    ),
                                  ),
                              
                                ],
                              ),
                              

                            ],
                          ),
                  // Center(child: const Text('No songs avalable')),

                        ],
                  ),
                  
                  
                ),
              Expanded(
  child: ListView.builder(
    itemCount: services.favorite.length, // Adjusted item count
    itemBuilder: (context, index) { 
      
      
        // Adjust index by subtracting 1 when accessing quickpicks 
        final favorite = services.favorite[index];
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Material(
            color: Colors.transparent,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
              onTap: () {
                controller.startPlaying(favorite); 
                  // controller.currentIndex.value = index - 1;
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PlayerPage()),
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
                  child: Image(
                    image: NetworkImage(favorite.cover),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              title: Text(
                favorite.title,
                style: const TextStyle(
                  color: Colors.white,
                ),
                maxLines: 1,
              ),
              subtitle: Text(
                favorite.artist,
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
      
    },
  ),
),

        ],
      ),
    );
  }
}






class PlayListWidgets extends StatefulWidget {
  const PlayListWidgets({super.key});

  @override
  State<PlayListWidgets> createState() => _PlayListWidgetsState();
}

class _PlayListWidgetsState extends State<PlayListWidgets> {

    late FireStoreServices services;

  PageControllerNavPages pageController = Get.put(PageControllerNavPages());

  @override
  void initState() {
      services = Get.put(FireStoreServices());
    services.getPlaylists();

    super.initState();
  }
  final PlaylistPageFunction _playlistPageFunction = Get.put(PlaylistPageFunction());

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        child: Column(
          children: [
              const SizedBox(height: 10,),
        
            const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [Padding(
                padding: EdgeInsets.only(right: 10,top: 40),
                child: Text('Playlists',style: TextStyle(fontSize: 45,color: Colors.white),),
              ),
              SizedBox(width: 10,)
              ],),

              SizedBox(
                height: MediaQuery.of(context).size.height,
                child: GridView.builder(
                  itemCount: 2,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
                  itemBuilder: (context, index) {
                    if(index == 0){
return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: (){
pageController.goInsidePlayList.value = !pageController.goInsidePlayList.value;
                        },
                        child: Container(
                                          
                          decoration: BoxDecoration(
                            border: Border.all(
                              width: 0.5,
                             color: Colors.grey.shade100.withOpacity(0.4)
                            ),
                            borderRadius: BorderRadius.circular(20),
                           color: Colors.grey.shade100.withOpacity(0.2)
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(FontAwesome.heart,color: Colors.red,),
                              SizedBox(height: 20,),
                              Text('My Faviorate',style: TextStyle(color: Colors.white),)
                            ],
                          ),
                        ),
                      ),
                    );
                    }
                    else if (index == 2-1){
                      return Padding(
                      padding:  const EdgeInsets.all(8.0),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: (){
                          _playlistPageFunction.addNewPlayList(context);
                        },
                        child: Container(
                                          
                          decoration: BoxDecoration(
                            border: Border.all(
                              width: 0.5,
                             color: Colors.grey.shade100.withOpacity(0.4)
                            ),
                            borderRadius: BorderRadius.circular(20),
                           color: Colors.grey.shade100.withOpacity(0.2)
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add,color: Colors.white,),
                              SizedBox(height: 20,),
                              Text('Add Playlist',style: TextStyle(color: Colors.white),)
                            ],
                          ),
                        ),
                      ),
                    );
                    }
                    else{
                      return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: (){

                        },
                        child: Container(          
                          decoration: BoxDecoration(
                            border: Border.all(
                              width: 0.5,
                             color: Colors.grey.shade100.withOpacity(0.4)
                            ),
                            borderRadius: BorderRadius.circular(20),
                           color: Colors.grey.shade100.withOpacity(0.2)
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(FontAwesome.heart,color: Colors.red,),
                              SizedBox(height: 20,),
                              Text('My Faviorate',style: TextStyle(color: Colors.white),)
                            ],
                          ),
                        ),
                      ),
                    );
                    }
                    
                    
                  },
                ),
              )
            
          ],
        ),
      );
  }
}