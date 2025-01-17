import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_app/services/services.dart';

class Songs extends StatefulWidget {
  const Songs({super.key});

  @override
  State<Songs> createState() => _SongsState();
}

class _SongsState extends State<Songs> {

  

  TextEditingController songQuery = TextEditingController();

  late FireStoreServices services;


 @override
  void initState() {
  services = Get.put(FireStoreServices());
    super.initState();
  }

List<Map<String, dynamic>> songs = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        child: Padding(
          padding:  EdgeInsets.only(left: 10), 
          child: Column(
            children: [
                const SizedBox(height: 10,),
          
              const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [Padding(
                  padding: EdgeInsets.only(right: 10,top: 40),
                  child: Text('Songs',style: TextStyle(fontSize: 45,color: Colors.white),),
                ),
                SizedBox(width: 10,)
                ],),
           SizedBox(height: 10,),
                Padding(
                  padding:  EdgeInsets.symmetric(horizontal: 10),
                  child: TextField(
                    controller: songQuery,
                    onChanged: (v) async{
                    log("shubha songs");

                    log(v);
                   
                   songs = await services.searchSongs(v);
                    setState(() {
                      
                    });
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


                     suffixIcon: Icon(Icons.music_note_rounded,color: Colors.white,),
                      hintText: "What's on your mind",
                      hintStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10)))
                    ),
                  ),
                ),
                Text(songs.isNotEmpty? songs[0]['title'] : "No Data" ,style: TextStyle(color: Colors.white),)
              
            ],
          ),
        ),
      )
    );
  }
}