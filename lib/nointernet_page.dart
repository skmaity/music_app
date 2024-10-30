import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NointernetPage extends StatefulWidget {
  const NointernetPage({super.key});

  @override
  State<NointernetPage> createState() => _NointernetPageState();
}

class _NointernetPageState extends State<NointernetPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Text('No Internet'),
              SizedBox(
                child: DefaultTextStyle(
                  style: GoogleFonts.josefinSans().copyWith(
                    fontSize: 20,
                    color: Colors.white,
                    shadows: [
                      const Shadow(
                        blurRadius: 7.0,
                        color: Colors.white,
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                  child: AnimatedTextKit(
                    repeatForever: true,
                    animatedTexts: [
                      FlickerAnimatedText('No Connection'),
                    ],
                    onTap: () {
                      print("Tap Event");
                    },
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
