import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:music_app/const/theme/tokens.dart';
import 'package:music_app/global_widgets/skeleton.dart';

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
    this.fallbackIcon = Icons.music_note_rounded,
    this.semanticLabel,
  });

  final String url;
  final double size;
  final double radius;
  final IconData fallbackIcon;
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
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            // Covers used to pop. Nothing else in the app arrives that
            // abruptly, and album art is the one thing the user is looking at.
            fadeInDuration: Motion.normal,
            fadeInCurve: Motion.enter,
            // A shimmering block, not a spinner. This was a 16px ring at
            // `strokeWidth: 0.5` — sub-pixel on a 1x device and near-invisible
            // on any of them, reading as dirt on the screen rather than as
            // loading.
            placeholder: (_, __) => Skeleton(radius: radius),
            errorWidget: (_, __, ___) => _placeholder(
              Icon(fallbackIcon,
                  color: AppColors.textSecondary, size: size * 0.4),
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder(Widget child) => ColoredBox(
        color: AppColors.glass1,
        child: Center(child: child),
      );
}
