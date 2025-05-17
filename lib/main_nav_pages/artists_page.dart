import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_app/controller/artist_controller.dart';
import 'package:music_app/controller/song_controller.dart';
import 'package:music_app/main_nav_pages/artist_page_change.dart';
import 'package:music_app/player_page.dart';
import 'package:music_app/services/services.dart';

ArtistController _artistController = Get.find<ArtistController>();

class ArtistsPage extends StatefulWidget {
  const ArtistsPage({super.key});

  @override
  State<ArtistsPage> createState() => _ArtistsPageState();
}

class _ArtistsPageState extends State<ArtistsPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.transparent,
        body: Obx(()=> showArtistSongs.value? const ArtistSongs(): const ArtistsListsPage() )
    );
  }
}

class ArtistsListsPage extends StatefulWidget {
  const ArtistsListsPage({super.key});

  @override
  State<ArtistsListsPage> createState() => _ArtistsListsPageState();
}

class _ArtistsListsPageState extends State<ArtistsListsPage> {
      late FireStoreServices services;

  @override 
  void initState() {
  services = Get.find<FireStoreServices>();
  services.getArtists();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.transparent,
        body: SingleChildScrollView(
          child: Padding(
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
                        'Artists',
                        style: TextStyle(fontSize: 45, color: Colors.white),
                      ),
                    ),
                    SizedBox(
                      width: 10,
                    )
                  ],
                ),
               Obx(
                 ()=> SizedBox(
                   height: MediaQuery.of(context).size.height,
                   child: ListView.builder(
                     itemCount: (services.artistsList.length / 5).ceil() + 1, 
                     itemBuilder: (context, index) {
                       if (index == 0) {
                         
                         return Column(
                           children: [
                             const SizedBox(height: 20),
                             SizedBox(
                               height: 180,
                               child: ListView.builder(
                  shrinkWrap: true,
                  scrollDirection: Axis.horizontal,
                  itemCount: services.artistsList.length >= 5 ? 5 : services.artistsList.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Row(
                        children: [
                          Column(
                            children: [
                              InkWell(
                                borderRadius: BorderRadius.circular(100),
                                onTap: (){
                        selectedArtistName.value = services.artistsList[index].name;

                                  services.getSongsUnderArtists(services.artistsList[index].id);
                                  toggleSongs();

                                },
                                
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(100),
                                    ),
                                    child: Image(
                                      height: 130,
                                      width: 130,
                                      image: NetworkImage(services.artistsList[index].imageUrl),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                               Text(
                                services.artistsList[index].name,
                                style: const TextStyle(color: Colors.white, fontSize: 16),
                              )
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                               ),
                             ),
                             const Padding(
                               padding: EdgeInsets.symmetric(horizontal: 10),
                               child: Row(
                  children: [
                    Text(
                      'More',
                      style: TextStyle(color: Colors.white, fontSize: 30),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Image(
                        image: AssetImage('assets/vectors/album_line2.png'),
                        fit: BoxFit.cover,
                      ),
                    )
                  ],
                               ),
                             ),
                           ],
                         );
                       } else {
                         // Remaining lists: Group remaining items in batches of 5
                         int startIndex = (index - 1) * 5 + 5;
                        //  int endIndex = startIndex + 5;
                         int remainingItems = services.artistsList.length - startIndex;
                 
                         if (remainingItems <= 0) {
                           // Add SizedBox at the end
                           return const SizedBox(height: 200);
                         }
                 
                         int itemCount = remainingItems >= 5 ? 5 : remainingItems;
                         
                         return Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             const SizedBox(height: 10),
                             SizedBox(
                               height: 180, 
                               child: ListView.builder(
                  shrinkWrap: true,
                  scrollDirection: Axis.horizontal, 
                  itemCount: itemCount,
                  itemBuilder: (context, subIndex) {
                    int actualIndex = startIndex + subIndex;
                    return InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: (){
                        selectedArtistName.value = services.artistsList[actualIndex].name;
                         services.getSongsUnderArtists(services.artistsList[actualIndex].id);
                                  toggleSongs();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child:  Image(
                                image: NetworkImage(services.artistsList[actualIndex].imageUrl),
                                fit: BoxFit.cover,
                                width: 110,
                                height: 110,
                              ),
                            ),
                            const SizedBox(height: 10),
                             SizedBox(
                              width: 100,
                               child: Text(
                                services.artistsList[actualIndex].name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontSize: 16),
                                                           ),
                             ),
                            // const SizedBox(height: 2),
                            // const SizedBox(
                            //   width: 110,
                            //   child: Text(
                            //     'Arijit Sing,alka yatri,kumar sanu',
                            //     style: TextStyle(
                            //       color: Colors.white60,
                            //       fontSize: 12,
                            //     ),
                            //     textAlign: TextAlign.center,
                            //   ),
                            // ),
                          ],
                        ),
                      ),
                    );
                  },
                               ),
                             ),
                           ],
                         );
                       }
                     },
                   ),
                 ),
               )

              ],
            ),
          ),
        ));
  }
}


class ArtistSongs extends StatefulWidget {
  const ArtistSongs({super.key});

  @override
  State<ArtistSongs> createState() => _ArtistSongsState();
}

class _ArtistSongsState extends State<ArtistSongs> {


  late FireStoreServices services;
  late SongController controller;

  @override 
  void initState() {
   services = Get.find<FireStoreServices>();
       controller = Get.find<SongController>();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(()=>
      Scaffold(
        backgroundColor: Colors.transparent,
        body: services.artistsongs.isNotEmpty? Column(children: [
            const SizedBox(
                    height: 50,
                  ),
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const IconButton(
                        
                        onPressed:
                  toggleSongs,
                       icon: Icon(
                        color: Colors.white,
                        shadows: [
                          Shadow(blurRadius: 9.0, color: Colors.white70, offset: Offset(0, 0))
                        ],
                        Icons.arrow_back_ios_rounded)),
                  
                      Padding(
                        padding: const EdgeInsets.only(right: 20),
                        child: Text(
                          services.artistsongs[_artistController.selectedArtistIndex.value].artist,
                          
                          style: const TextStyle(fontSize: 45, color: Colors.white),
                        ),
                      ),
                      
                    ],
                  ),
      
      Expanded(
        child: ListView.builder(
      itemCount: services.artistsongs.length, // Adjusted item count
      itemBuilder: (context, index) {
        
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Material(
              color: Colors.transparent,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                onTap: () {
                  controller.startPlaying(services.artistsongs[index]).then((_) { 
                  services.currentPlayingList = services.artistsongs;

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
                      image: NetworkImage(services.artistsongs[index].coverurl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                title: Text(
                  services.artistsongs[index].title,
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                  maxLines: 1,
                ),
                subtitle: Text(
                   services.artistsongs[index].artist,
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
      
      
        ],): Obx(()=>
           Column(children: [ 
              const SizedBox(
                      height: 50,
                    ),
                     Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const IconButton(
                          
                          onPressed:
                    toggleSongs,
                         icon: Icon(
                          color: Colors.white,
                          shadows: [
                            Shadow(blurRadius: 9.0, color: Colors.white70, offset: Offset(0, 0))
                          ],
                          Icons.arrow_back_ios_rounded)),
                    
                       SizedBox(
                        width: 240,
                         child: Padding(
                              padding: const EdgeInsets.only(right: 20),
                              child: Text(
                                textAlign: TextAlign.end,
                                overflow: TextOverflow.ellipsis,
                                selectedArtistName.value,
                                
                                style: const TextStyle(fontSize: 35, color: Colors.white),
                              ),
                            ),
                       ),
                        
                        
                      ],
                    ), 
                  const Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Center(child: Text("No Songs found",style: TextStyle(color: Colors.white),),),
                      ],
                    ),
                  )
          ]),
        )
      ),
    );
  }
}