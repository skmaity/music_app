import 'package:flutter/material.dart';

class Albums extends StatefulWidget {
  const Albums({super.key});

  @override
  State<Albums> createState() => _AlbumsState();
}

class _AlbumsState extends State<Albums> {
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
                child: Text('Albums',style: TextStyle(fontSize: 45,color: Colors.white),),
              ),
              SizedBox(width: 10,)
              ],),
            
          ],
        ),
      )
    );
  }
}