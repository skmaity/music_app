import 'dart:ui';
import 'package:animate_gradient/animate_gradient.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:get/get.dart';
import 'package:music_app/controller/song_controller.dart';
import 'package:music_app/main_nav_pages/Albums.dart';
import 'package:music_app/main_nav_pages/artists_page.dart';
import 'package:music_app/controller/background_controller.dart';
import 'package:music_app/controller/internet_controller.dart';
import 'package:music_app/nointernet_page.dart';
import 'package:music_app/main_nav_pages/playlists.dart';
import 'package:music_app/main_nav_pages/quick_picks.dart';
import 'package:music_app/main_nav_pages/songs.dart';
import 'package:music_app/player_page.dart';

class Dashboard extends StatefulWidget  {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  bool checkboxSelected = false;
  bool switchSelected = false;
  bool radioSelected = false;
  bool iconSelected = false;

  List<Widget> pages = [
    const QuickPicks(), 
    const Songs(),
    const Playlists(),
    const ArtistsPage(),
    const Albums()
  ];

  RxInt pageIndex = 0.obs;

  late final InternetController internetController ;
  late BackgroundController backgroundcontroller;
  late SongController songcontroller;

  @override
  void initState() {
    backgroundcontroller = Get.put(BackgroundController());
    backgroundcontroller.updatePaletteGenerator();
   internetController = Get.put(InternetController());
   songcontroller = Get.put(SongController());

    pageIndex.value = 0;
    super.initState();
  }
final BackgroundController _backgroundController = Get.put(BackgroundController());




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: Stack(
        alignment: Alignment.center,
        children:[
              // const AnimatedBackground(),
               AnimateGradient(
          primaryColors:_backgroundController.primaryColorsList,
          secondaryColors: _backgroundController.secondaryColorsList,
        ),
          
        
      

          AnimatedContainer(
            duration: const Duration(milliseconds: 5000),
            color: Colors.black.withOpacity(0.1),
            child: const SizedBox.expand(),
          ),
          Row(
            children: [
              Obx(
                () => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

 
songcontroller.isPlaying.value ? InkWell(
  onTap: (){
    // Navigator.push(context,MaterialPageRoute(builder: (context) => const PlayerPage(),)  );
    Get.to(()=>const PlayerPage());
  },
  child: Stack(
    alignment: AlignmentDirectional.center,
    children: [
      Obx(()=>
         SizedBox(
          height: 45,
          width: 45, 
          child:  CircularProgressIndicator(
            
            strokeWidth: 1,
            strokeCap: StrokeCap.round,
            value: songcontroller.getProgress(),
            color: Colors.white,
          )
        ),
      ),
     Container(
      
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
                                  color: Colors.grey.shade100.withOpacity(0.4)),
      child: 
       const Padding(
        padding:  EdgeInsets.all(8.0),
        child: Hero(
          tag: 'music',
          child: Icon(Icons.music_note_outlined,
          color: Colors.white,
           shadows: 
                   [Shadow(blurRadius: 9.0, color: Colors.white, offset: Offset(0, 0))]
          ),
        ),
        
      ),
      ).animate().fade().scale(),
    ]
  ),
):const SizedBox(),
  

const SizedBox(height: 10,),

                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(30),
                          bottomRight: Radius.circular(30)),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                        child: Container(
                          //  height: 400,

                          decoration: BoxDecoration(
                              color: Colors.grey.shade100.withOpacity(0.4)),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Column(
  children: [
    RotatedBox(
      quarterTurns: 3,
      child: TextButton.icon(
        iconAlignment: IconAlignment.end,
        onPressed: () {
          pageIndex.value = 0;
        },
        icon: Icon(
          pageIndex.value == 0 ? Icons.hotel_class_rounded : Icons.hotel_class_outlined,
          color: pageIndex.value == 0 ? Colors.white : Colors.black54,
          shadows: pageIndex.value == 0
              ? [const Shadow(blurRadius: 9.0, color: Colors.white, offset: Offset(0, 0))]
              : null,
          size: 20,
        ),
        label: Text( 
          'Quick picks',
          style: TextStyle(
            shadows: pageIndex.value == 0
                ? [const Shadow(blurRadius: 9.0, color: Colors.white, offset: Offset(0, 0))]
                : null,
            color: pageIndex.value == 0 ? Colors.white : Colors.black54,
          ),
        ),
      ),
    ),
    RotatedBox(
      quarterTurns: 3,
      child: TextButton.icon(
        iconAlignment: IconAlignment.end,
        onPressed: () {
          pageIndex.value = 1;
        },
        icon: Icon(
          pageIndex.value == 1 ? Icons.music_note : Icons.music_note_outlined,
          color: pageIndex.value == 1 ? Colors.white : Colors.black54,
          shadows: pageIndex.value == 1
              ? [const Shadow(blurRadius: 9.0, color: Colors.white, offset: Offset(0, 0))]
              : null,
          size: 20,
        ),
        label: Text(
          'Songs',
          style: TextStyle(
            shadows: pageIndex.value == 1
                ? [const Shadow(blurRadius: 9.0, color: Colors.white, offset: Offset(0, 0))]
                : null,
            color: pageIndex.value == 1 ? Colors.white : Colors.black54,
          ),
        ),
      ),
    ),
    RotatedBox(
      quarterTurns: 3,
      child: TextButton.icon(
        iconAlignment: IconAlignment.end,
        onPressed: () {
          pageIndex.value = 2;
        },
        icon: Icon(
          pageIndex.value == 2 ? FontAwesome.heart : FontAwesome.heart_o,
          color: pageIndex.value == 2 ? Colors.white : Colors.black54,
          shadows: pageIndex.value == 2
              ? [const Shadow(blurRadius: 9.0, color: Colors.white, offset: Offset(0, 0))]
              : null,
          size: 20,
        ),
        label: Text(
          'Favorites',
          style: TextStyle(
            shadows: pageIndex.value == 2
                ? [const Shadow(blurRadius: 9.0, color: Colors.white, offset: Offset(0, 0))]
                : null,
            color: pageIndex.value == 2 ? Colors.white : Colors.black54,
          ),
        ),
      ),
    ),
    RotatedBox(
      quarterTurns: 3,
      child: TextButton.icon(
        iconAlignment: IconAlignment.end,
        onPressed: () {
          pageIndex.value = 3;
        },
        icon: Icon(
          pageIndex.value == 3 ? Icons.person : Icons.person_2_outlined,
          color: pageIndex.value == 3 ? Colors.white : Colors.black54,
          shadows: pageIndex.value == 3
              ? [const Shadow(blurRadius: 9.0, color: Colors.white, offset: Offset(0, 0))]
              : null,
          size: 20,
        ),
        label: Text(
          'Artists',
          style: TextStyle(
            shadows: pageIndex.value == 3
                ? [const Shadow(blurRadius: 9.0, color: Colors.white, offset: Offset(0, 0))]
                : null,
            color: pageIndex.value == 3 ? Colors.white : Colors.black54,
          ),
        ),
      ),
    ),
    // RotatedBox(
    //   quarterTurns: 3,
    //   child: TextButton.icon(
    //     iconAlignment: IconAlignment.end,
    //     onPressed: () {
    //       pageIndex.value = 4;
    //     },
    //     icon: Icon(
    //       pageIndex.value == 4 ? Icons.album : Icons.album_outlined,
    //       color: pageIndex.value == 4 ? Colors.white : Colors.black54,
    //       shadows: pageIndex.value == 4
    //           ? [const Shadow(blurRadius: 9.0, color: Colors.white, offset: Offset(0, 0))]
    //           : null,
    //       size: 20,
    //     ),
    //     label: Text(
    //       'Albums',
    //       style: TextStyle(
    //         shadows: pageIndex.value == 4
    //             ? [const Shadow(blurRadius: 9.0, color: Colors.white, offset: Offset(0, 0))]
    //             : null,
    //         color: pageIndex.value == 4 ? Colors.white : Colors.black54,
    //       ),
    //     ),
    //   ),
    // ),
  ],
),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Obx(
                () => Expanded(
                  child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                        final slideAnimation = Tween<Offset>(
                          begin: const Offset(1.0, 0.0), // Slide in from right
                          end: const Offset(0.0, 0.0),
                        ).animate(animation);

                        return SlideTransition(
                          position: slideAnimation,
                          child: FadeTransition(opacity: animation, child: child),
                        );
                      },
                      child: internetController.internet.value
                          ? pages[pageIndex.value]
                          : const NointernetPage()

                          // child : const NointernetPage(),
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
