import 'package:flutter/material.dart';

class Artists extends StatefulWidget {
  const Artists({super.key});

  @override
  State<Artists> createState() => _ArtistsState();
}

class _ArtistsState extends State<Artists> {
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
                child: Text('Artists',style: TextStyle(fontSize: 45,color: Colors.white),),
              ),
              SizedBox(width: 10,)
              ],),
            
          ],
        ),
      )
    );
  }
}