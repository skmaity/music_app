import 'dart:ui' as ui;
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const MyApp());

const Color _kBackgroundColor = Color(0xffa0a0a0);

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
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

  @override
  void initState() {
    super.initState();
  }

  String imageurl = 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQaVKy63Q28LPrnZBlRvBKIG_9Z_rkiXjbJhg&s';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Colors',
      theme: ThemeData(),
      home: FutureBuilder(
        future: getImageSize(imageurl),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ImageColors(
              title: 'Image Colors',
              image: NetworkImage(imageurl),
              imageSize: Size(snapshot.data![0], snapshot.data![1]),
            );
          } else {
            return const CircularProgressIndicator();
          }
        },
      ),
    );
  }
}

class ImageColors extends StatefulWidget {
  const ImageColors({
    super.key,
    this.title,
    required this.image,
    this.imageSize,
  });

  final String? title;
  final ImageProvider image;
  final Size? imageSize;

  @override
  State<ImageColors> createState() => _ImageColorsState();
}

class _ImageColorsState extends State<ImageColors> {
  PaletteGenerator? paletteGenerator;

  @override
  void initState() {
    super.initState();
    _updatePaletteGenerator();
  }
 
  Future<void> _updatePaletteGenerator() async {
    paletteGenerator = await PaletteGenerator.fromImageProvider(
      widget.image,
      size: widget.imageSize,
      maximumColorCount: 20,
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackgroundColor,
      appBar: AppBar(
        title: Text(widget.title ?? ''),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Image(
                image: widget.image,
                width: widget.imageSize?.width,
                height: widget.imageSize?.height,
              ),
            ),
            PaletteSwatches(generator: paletteGenerator),
          ],
        ),
      ),
    );
  }
}

class PaletteSwatches extends StatelessWidget {
  const PaletteSwatches({super.key, this.generator});

  final PaletteGenerator? generator;

  @override
  Widget build(BuildContext context) {
    // final List<Widget> swatches = <Widget>[];
    final PaletteGenerator? paletteGen = generator;

    if (paletteGen == null || paletteGen.colors.isEmpty) {
      return Container();
    }
    // for (final Color color in paletteGen.colors) {
    //   swatches.add(PaletteSwatch(color: color));
    // }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Wrap(
        //   children: swatches,
        // ),
        Container(height: 30.0), 
        PaletteSwatch(label: 'Dominant', color: paletteGen.dominantColor?.color),
        PaletteSwatch(label: 'Light Vibrant', color: paletteGen.lightVibrantColor?.color),
        PaletteSwatch(label: 'Vibrant', color: paletteGen.vibrantColor?.color),
        PaletteSwatch(label: 'Dark Vibrant', color: paletteGen.darkVibrantColor?.color),
        PaletteSwatch(label: 'Light Muted', color: paletteGen.lightMutedColor?.color),
        PaletteSwatch(label: 'Muted', color: paletteGen.mutedColor?.color),
        PaletteSwatch(label: 'Dark Muted', color: paletteGen.darkMutedColor?.color),
      ],
    );
  }
}

@immutable
class PaletteSwatch extends StatelessWidget {
  const PaletteSwatch({
    super.key,
    this.color,
    this.label,
  });

  final Color? color;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final HSLColor hslColor = HSLColor.fromColor(color ?? Colors.transparent);
    final HSLColor backgroundAsHsl = HSLColor.fromColor(_kBackgroundColor);
    final double colorDistance = math.sqrt(
        math.pow(hslColor.saturation - backgroundAsHsl.saturation, 2.0) +
            math.pow(hslColor.lightness - backgroundAsHsl.lightness, 2.0));

    Widget swatch = Padding(
      padding: const EdgeInsets.all(2.0),
      child: color == null
          ? const Placeholder(
              fallbackWidth: 34.0,
              fallbackHeight: 20.0,
              color: Color(0xff404040),
            )
          : Tooltip(
              message: color!.toRGB(),
              child: Container(
                decoration: BoxDecoration(
                    color: color,
                    border: Border.all(
                      color: _kBackgroundColor,
                      style: colorDistance < 0.2
                          ? BorderStyle.solid
                          : BorderStyle.none,
                    )),
                width: 34.0,
                height: 20.0,
              ),
            ),
    );

    if (label != null) {
      swatch = ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 130.0, minWidth: 130.0),
        child: Row(
          children: <Widget>[
            swatch,
            Container(width: 5.0),
            Text(label!),
          ],
        ),
      );
    }
    return swatch;
  }
}

extension on Color {
  String toRGB() {
    return '#${red.toHex()}${green.toHex()}${blue.toHex()}';
  }
}

extension on int {
  String toHex([int minDigits = 2]) {
    return toRadixString(16).toUpperCase().padLeft(minDigits, '0');
  }
}
