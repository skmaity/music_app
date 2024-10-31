import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:music_app/controller/internet_controller.dart';
import 'package:music_app/firebase_options.dart';
import 'package:music_app/dashboard_page.dart';
void main() async {
  InternetController internetController = Get.put(InternetController());
  internetController.checkInternet();
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
);
  runApp(const MyApp());
}       

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music App',
      theme: ThemeData(

        textButtonTheme:  TextButtonThemeData(
          style: ButtonStyle(textStyle:  WidgetStatePropertyAll(GoogleFonts.pacifico() ),),),
        
        textTheme: GoogleFonts.josefinSansTextTheme(),
        
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const Dashboard()
    );
    
  }
}
