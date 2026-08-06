import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:music_app/const/theme/tokens.dart';
import 'package:music_app/global_widgets/motion.dart';

/// A placeholder block, shimmering unless the platform asks for reduced motion.
///
/// Every list used to clear its whole layout for one centred spinner and then
/// hard-cut to content. A skeleton keeps the page where it is, which reads as
/// faster than it is — and it never flashes.
class Skeleton extends StatelessWidget {
  const Skeleton({
    super.key,
    this.width,
    this.height,
    this.radius = Radii.sm,
  });

  final double? width;
  final double? height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.glass1,
        borderRadius: BorderRadius.circular(radius),
      ),
    );

    if (noMotion(context)) return box;

    return box
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: Motion.shimmer, color: AppColors.glass2);
  }
}

/// Rows matching [SongTile]'s geometry, so the list does not move when the
/// real rows arrive.
class SongListSkeleton extends StatelessWidget {
  const SongListSkeleton({super.key, this.count = 7});

  final int count;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      itemBuilder: (context, _) => Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: Space.gutter, vertical: Space.xs),
        child: Container(
          // Matches SongTile: `contentPadding` horizontal Space.md and
          // `minVerticalPadding` Space.sm around a Controls.thumbRow cover.
          padding: const EdgeInsets.symmetric(
              horizontal: Space.md, vertical: Space.sm),
          decoration: BoxDecoration(
            color: AppColors.glass1,
            borderRadius: BorderRadius.circular(Radii.sm),
          ),
          child: Row(
            children: [
              const Skeleton(
                  width: Controls.thumbRow,
                  height: Controls.thumbRow,
                  radius: Radii.md),
              const SizedBox(width: Space.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Skeleton(height: Space.md, radius: Radii.sm),
                    const SizedBox(height: Space.sm),
                    FractionallySizedBox(
                      widthFactor: 0.45,
                      child: const Skeleton(height: Space.sm, radius: Radii.sm),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
