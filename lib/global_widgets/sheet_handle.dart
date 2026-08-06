import 'package:flutter/material.dart';
import 'package:music_app/const/theme/tokens.dart';

/// The way out of a bottom sheet.
///
/// **Keep this outside the sheet's scrollable, as a sibling above it.** That
/// placement is the whole point. Flutter wraps a modal sheet in a single
/// `VerticalDragGestureRecognizer`, a scroll view installs its own, and for a
/// touch landing anywhere on the scrollable the deeper recognizer wins the
/// gesture arena. The player's options sheet had this bar *inside* its
/// `SingleChildScrollView`, so the one affordance that looks draggable was the
/// one place a downward drag could only ever scroll — a sheet that appeared to
/// have no exit at all.
///
/// It answers a tap as well as a drag. Material's own built-in handle
/// (`showDragHandle: true`) is drag-and-screen-reader only, and it cannot be
/// used here regardless: it renders in the sheet's own `Material`, which this
/// app leaves transparent so a [GlassPanel] can supply the surface instead.
///
/// The whole 48dp strip is the target, not the 4pt bar you can see — the bar
/// is a mark, and a modal whose only exits are a precise drag and a strip of
/// scrim is a modal people get stuck in.
class SheetDragHandle extends StatelessWidget {
  const SheetDragHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      // The sheet's own Material sits *behind* the GlassPanel, so an InkWell
      // without this one would splash under the glass and the tap would look
      // like nothing happened.
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.of(context).pop(),
        // Inside the InkWell, not around it — from outside, excludeSemantics
        // drops the InkWell's own tap action and leaves a control a screen
        // reader can read but not activate.
        child: Semantics(
          button: true,
          label: 'Close',
          excludeSemantics: true,
          child: const SizedBox(
            height: kMinInteractiveDimension,
            width: double.infinity,
            child: Center(
              child: SizedBox(
                width: Space.xxl + Space.sm,
                height: Space.xs,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.glassEdge,
                    borderRadius: BorderRadius.all(Radius.circular(Radii.sm)),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
