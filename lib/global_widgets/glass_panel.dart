import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:music_app/const/theme/tokens.dart';

/// How far off the background a surface sits.
enum GlassLevel {
  /// Rows and chips. Fill only — no blur, no edge, no shadow.
  low,

  /// Cards and bars: the player card, the now-playing bar.
  mid,

  /// Edge-spanning surfaces: the nav rail.
  high,
}

/// The app's one glass recipe.
///
/// **Clip → blur → fill → edge**, in that order; any other order looks muddy.
/// The shadow sits outside the clip, or the clip would cut it off.
///
/// Before this widget, "glass" meant four unrelated things hand-rolled at four
/// call sites — blurred at 0.4, blurred at 0.2, unblurred at 0.4, unblurred at
/// 0.1, two with borders and two without. Changing the recipe meant editing
/// every one of them, so nobody did, and they drifted.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    required this.borderRadius,
    this.level = GlassLevel.mid,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final GlassLevel level;
  final EdgeInsetsGeometry padding;

  bool get _isPane => level != GlassLevel.low;

  Color get _fill => switch (level) {
        GlassLevel.low => AppColors.glass1,
        GlassLevel.mid => AppColors.glass2,
        GlassLevel.high => AppColors.glass3,
      };

  @override
  Widget build(BuildContext context) {
    Widget surface = DecoratedBox(
      decoration: BoxDecoration(color: _fill, borderRadius: borderRadius),
      child: Padding(padding: padding, child: child),
    );

    if (_isPane) {
      surface = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: kGlassBlur, sigmaY: kGlassBlur),
        child: surface,
      );
    }

    final clipped = ClipRRect(borderRadius: borderRadius, child: surface);

    if (!_isPane) return clipped;

    // The blur re-samples everything behind it, and behind it the gradient is
    // animating continuously. Without this boundary the whole subtree repaints
    // with it — the single most expensive thing on screen.
    return RepaintBoundary(
      child: DecoratedBox(
        // Shadow behind, so the clip cannot cut it off.
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: kPanelShadow,
        ),
        child: DecoratedBox(
          // Hairline in *front*, and outside the clip. Drawn inside it, the
          // clip's own antialiasing eats most of the outer pixel and the edge
          // comes back as the smudge this is meant to replace.
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            border: Border.all(color: AppColors.glassEdge, width: 1),
          ),
          child: clipped,
        ),
      ),
    );
  }
}
