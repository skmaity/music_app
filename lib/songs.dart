import 'package:flutter/material.dart';

class Songs extends StatefulWidget {
  const Songs({super.key});

  @override
  State<Songs> createState() => _SongsState();
}

class _SongsState extends State<Songs> {
  @override
  Widget build(BuildContext context) {
    return  const Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        child: Column(
          children: [
              SizedBox(height: 10,),
        
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [Padding(
                padding: EdgeInsets.only(right: 10,top: 40),
                child: Text('Songs',style: TextStyle(fontSize: 45,color: Colors.white),),
              ),
              SizedBox(width: 10,)
              ],),
            
          ],
        ),
      )
    );
  }
}