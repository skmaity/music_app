import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:music_app/all_urls.dart';
import 'package:music_app/controller/song_controller.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'dart:ui' as ui;

class BackgroundController extends GetxController {

  hideVisibility() {
    Future.delayed(const Duration(milliseconds: 300), () {
      isVisible.value = false;
    });
  }
  showVisibility() {
    if (isFromSongLogo.value) {
      isFromSongLogo.value = false;
      return;
    }
     Future.delayed(const Duration(seconds: 0), () {
          isVisible.value = true;

    });
  }

  RxBool isFromSongLogo = false.obs;
  RxBool isVisible = false.obs;
  SongController controller = Get.find<SongController>();

  RxList<Color> primaryColorsList = [
    Colors.black,
    Colors.black38,
  ].obs;
  RxList<Color> secondaryColorsList = [
    Colors.black38,
    Colors.black,
  ].obs;

  Future<List<double>> getImageSize(String imageUrl) async {
    List<double> heightAndWidth = [];

    final http.Response response = await http.get(Uri.parse(imageUrl));

    if (response.statusCode == 200) {
      final Uint8List imageData = response.bodyBytes;
      final ui.Image decodedImage = await decodeImageFromList(imageData);

      heightAndWidth.add(decodedImage.width.toDouble());
      heightAndWidth.add(decodedImage.height.toDouble());

      return heightAndWidth;
    } else {
      throw Exception('Failed to load image from the URL');
    }
  }

  PaletteGenerator? paletteGenerator;
  String altImage =
      "uploads/covers/alt_image_bg.jpg";

  Future<void> updatePaletteGenerator() async {
    try {


      if (controller.currentPlaying.coverurl != "coverurl") {  
    showVisibility(); 

// Get the image size from the URL
        List<double> dimensions =
            await getImageSize(baseUrl + controller.currentPlaying.coverurl);

        // Use the dimensions to set the size in PaletteGenerator
        paletteGenerator = await PaletteGenerator.fromImageProvider(
          NetworkImage( baseUrl + controller.currentPlaying.coverurl),
          size: Size(dimensions[0], dimensions[1]),
          maximumColorCount: 20,
        );
        primaryColorsList.clear();
        secondaryColorsList.clear();

        primaryColorsList 
            .add(paletteGenerator!.dominantColor?.color ?? Colors.white);
        primaryColorsList
            .add(paletteGenerator!.darkMutedColor?.color ?? Colors.white);

        secondaryColorsList
            .add(paletteGenerator!.dominantColor?.color ?? Colors.white);
        secondaryColorsList
            .add(paletteGenerator!.mutedColor?.color ?? Colors.white);
    hideVisibility();

      } else {
        controller.currentPlaying.coverurl = altImage;  
        updatePaletteGenerator(); 
      }

    } catch (e) {
      // Handle any errors that occur during the process
      print("Error generating palette: $e");
    showVisibility(); 

    }
  }
}
