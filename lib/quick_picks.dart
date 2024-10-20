import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class QuickPicks extends StatefulWidget {
  const QuickPicks({super.key});

  @override
  State<QuickPicks> createState() => _QuickPicksState();
}

class _QuickPicksState extends State<QuickPicks> {
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
                child: Text('Quick picks',style: TextStyle(fontSize: 45,color: Colors.white),),
              ),
              SizedBox(width: 10,)
              ],),
            
          ],
        ),
      )
    );
  }
}