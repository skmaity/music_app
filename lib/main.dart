import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:music_app/bindings.dart';
import 'package:music_app/dashboard_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {

    return GetMaterialApp(
        title: 'Music App', 
        debugShowCheckedModeBanner: false,
        initialBinding: InitialScreenBindings(),    
        theme: ThemeData(
          textButtonTheme: TextButtonThemeData(
            style: ButtonStyle(
              textStyle: WidgetStatePropertyAll(GoogleFonts.pacifico()),
            ),
          ),
          textTheme: GoogleFonts.josefinSansTextTheme(),
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const Dashboard());
  }
}
