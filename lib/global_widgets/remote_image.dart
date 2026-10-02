import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:music_app/const/theme/tokens.dart';
import 'package:music_app/global_widgets/skeleton.dart';
import 'package:music_app/services/local_media_index.dart';

/// Every remote image in the app goes through this.
///
/// Fixed box first, image second, so a slow cover never reflows the list, and
/// both a placeholder and an error widget are always present — enough rows have
/// a missing cover that the fallback has to look deliberate.
class RemoteImage extends StatelessWidget {
  const RemoteImage({
    super.key,
    required this.url,
    required this.size,
    this.radius = 12,
    this.semanticLabel,
  });

  final String url;
  final double size;
  final double radius;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      image: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: SizedBox(
          height: size,
          width: size,
          child: _image(),
        ),
      ),
    );
  }

  Widget _placeholder(Widget child) => ColoredBox(
        color: AppColors.glass1,
        child: Center(child: child),
      );

  Widget _image() {
    if (LocalMediaPlatform.contentUriFromArtworkRef(url) != null) {
      return FutureBuilder<Uint8List?>(
        future: LocalMediaPlatform.loadArtwork(url),
        builder: (context, snapshot) {
          final bytes = snapshot.data;
          if (bytes == null || bytes.isEmpty) {
            return snapshot.connectionState == ConnectionState.waiting
                ? Skeleton(radius: radius)
                : _fallback();
          }
          return Image.memory(
            bytes,
            width: size,
            height: size,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.medium,
            gaplessPlayback: true,
          );
        },
      );
    }

    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      // Covers used to pop. Nothing else in the app arrives that abruptly.
      fadeInDuration: Motion.normal,
      fadeInCurve: Motion.enter,
      placeholder: (_, __) => Skeleton(radius: radius),
      errorWidget: (_, __, ___) => _fallback(),
    );
  }

  Widget _fallback() => _placeholder(Image.asset(
        'assets/nyro_logo.png',
        width: size * 0.62,
        height: size * 0.62,
        fit: BoxFit.contain,
      ));
}
