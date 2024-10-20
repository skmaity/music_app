import 'dart:ui';
import 'package:animate_gradient/animate_gradient.dart';
import 'package:flutter/material.dart';
import 'package:flutter_glow/flutter_glow.dart';
import 'package:music_app/Albums.dart';
import 'package:music_app/Artists.dart';
import 'package:music_app/playlists.dart';
import 'package:music_app/quick_picks.dart';
import 'package:music_app/songs.dart';
const flutterColor = Color(0xFF40D0FD);

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {


  // bool isSelected = false;
   bool checkboxSelected = false;
  bool switchSelected = false;
  bool radioSelected = false;
  bool iconSelected = false;

  List <Widget> pages = [
    const QuickPicks(),
    const Songs(),
    const Playlists(),
    const Artists(),
    const Albums()
  ];

  int pageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,


      body: Stack(
        alignment: Alignment.center,
        children: <Widget>[
         

           
     AnimateGradient(
      
        primaryColors: const [
          Colors.pink,
          Colors.pinkAccent,
          Colors.deepOrange,
        ],
        secondaryColors: const [
          Colors.blue,
          Colors.blueAccent,
          Colors.deepPurple,
        ],
        child: const SizedBox.expand(),
      ),

      AnimatedContainer(
        duration: const Duration(milliseconds: 5000),
        color: Colors.black.withOpacity(0.6),
        child: const SizedBox.expand(),),
           Row(
             children: [
               Column(
                mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   ClipRRect(
                    borderRadius: const BorderRadius.only(topRight: Radius.circular(30),bottomRight: Radius.circular(30)),
                     child: BackdropFilter(
                       filter:  ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                       child:  Container(
                        //  height: 400,
                         
                         decoration:  BoxDecoration(
                           color: Colors.grey.shade100.withOpacity(0.4)
                         ),
                         child:  Padding(
                           padding: const EdgeInsets.all(4.0),
                           child: Column(children: [
                            RotatedBox(quarterTurns: 3,
                            child: TextButton.icon(
                              iconAlignment: IconAlignment.end,
                                   onPressed: () {
                                    setState(() {
                                       pageIndex = 0;
                                    });
                                   },
                                   icon: GlowIcon(
                                    
                                     pageIndex == 0 ? Icons.hotel_class_rounded : Icons.hotel_class_outlined,
                                     color: pageIndex == 0 ? Colors.white : Colors.black54,
                                     glowColor: pageIndex == 0 ? Colors.white : Colors.transparent,
                                     size: 20,
                                     blurRadius: 9,
                                   ),
                                   label: GlowText(
                                    glowColor: pageIndex == 0 ?  Colors.white : Colors.transparent,
                                     'Quick picks',
              style: TextStyle(
                // fontSize: 18,
                color: pageIndex == 0 ?  Colors.white: Colors.black54),)
                                 ),
                            ),
                              RotatedBox(quarterTurns: 3,
                            child: TextButton.icon(
                              iconAlignment: IconAlignment.end,
                                   onPressed: () {
                                    setState(() {
                                                                              pageIndex = 1;

                                    });
                                   },
                                   icon: GlowIcon(
                                    
                                     pageIndex == 1 ? Icons.music_note : Icons.music_note_outlined,
                                     color: pageIndex == 1 ? Colors.white : Colors.black54,
                                     glowColor: pageIndex == 1 ? Colors.white : Colors.transparent,
                                     size: 20,
                                     blurRadius: 9,
                                   ),
                                   label: GlowText(
                                    glowColor: pageIndex == 1 ?  Colors.white : Colors.transparent,
                                     'Songs',
              style: TextStyle(
                // fontSize: 18,
                color: pageIndex == 1 ?  Colors.white: Colors.black54),)
                                 ),
                            ),
                              RotatedBox(quarterTurns: 3,
                            child: TextButton.icon(
                              iconAlignment: IconAlignment.end,
                                   onPressed: () {
                                    setState(() {
                                                                              pageIndex = 2;

                                    });
                                   },
                                   icon: GlowIcon(
                                    
                                     pageIndex == 2 ? Icons.playlist_play_outlined : Icons.playlist_play_rounded,
                                     color: pageIndex == 2 ? Colors.white : Colors.black54,
                                     glowColor: pageIndex == 2 ? Colors.white : Colors.transparent,
                                     size: 20,
                                     blurRadius: 9,
                                   ),
                                   label: GlowText(
                                    glowColor: pageIndex == 2 ?  Colors.white : Colors.transparent,
                                     'Playlists',
              style: TextStyle(
                // fontSize: 18,
                color: pageIndex == 2 ?  Colors.white: Colors.black54),)
                                 ),
                            ),  RotatedBox(quarterTurns: 3,
                            child: TextButton.icon(
                              iconAlignment: IconAlignment.end,
                                   onPressed: () {
                                    setState(() {
                                                                            pageIndex = 3;

                                    });
                                   },
                                   icon: GlowIcon(
                                    
                                     pageIndex == 3 ?  Icons.person :Icons.person_2_outlined ,
                                     color: pageIndex == 3 ? Colors.white : Colors.black54,
                                     glowColor: pageIndex == 3 ? Colors.white : Colors.transparent,
                                     size: 20,
                                     blurRadius: 9,
                                   ),
                                   label: GlowText(
                                    glowColor: pageIndex == 3 ?  Colors.white : Colors.transparent,
                                     'Artists',
              style: TextStyle(
                // fontSize: 18,
                color: pageIndex == 3 ?  Colors.white: Colors.black54),)
                                 ),
                            ),  RotatedBox(quarterTurns: 3,
                            child: TextButton.icon(
                              iconAlignment: IconAlignment.end,
                                   onPressed: () {
                                    setState(() {
                                                                              pageIndex = 4;

                                    });
                                   },
                                   icon: GlowIcon(
                                    
                                     pageIndex == 4 ? Icons.album : Icons.album_outlined,
                                     color: pageIndex == 4 ? Colors.white : Colors.black54,
                                     glowColor: pageIndex == 4 ? Colors.white : Colors.transparent,
                                     size: 20,
                                     blurRadius: 9,
                                   ),
                                   label: GlowText(
                                    glowColor: pageIndex == 4 ?  Colors.white : Colors.transparent,
                                     'Albums',
              style: TextStyle(
                // fontSize: 18,
                color: pageIndex == 4 ?  Colors.white: Colors.black54),)
                                 ),
                            ),
                             ],),
                         ),
                       ),
                     ),
                   ),
                 ],
               ),
          
          // Expanded(
          //   child: AnimatedSwitcher(
          //     duration: Duration(milliseconds: 500),
          //     transitionBuilder: (Widget child, Animation<double> animation) {
          //       final slideAnimation = Tween<Offset>(
          //         begin: Offset(0.0, 1.0), // Slide in from bottom
          //         end: Offset(0.0, 0.0),
          //       ).animate(animation);

          //       return ClipRect( // Clip overflow if needed
          //         child: SlideTransition(
          //           position: slideAnimation,
          //           child: child,
          //         ),
          //       );
          //     },
          //     child: SizedBox.expand( // Constraining the size
          //       key: ValueKey<int>(pageIndex), // Key must be unique for AnimatedSwitcher to work properly
          //       child: pages[pageIndex],
          //     ),
          //   )),

            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  final slideAnimation = Tween<Offset>(
                    begin: const Offset(1.0, 0.0), // Slide in from right
                    end: const Offset(0.0, 0.0),
                  ).animate(animation);
              
                  return SlideTransition(
                    position: slideAnimation,
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: pages[pageIndex],
              ),
            )


           



             ],
           ),
        ],
      ),
    );
  }
}