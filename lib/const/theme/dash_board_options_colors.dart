import 'package:flutter/material.dart';
import 'package:music_app/const/theme/tokens.dart';

/// The glow now lives in `tokens.dart` with the rest of the design language.
/// Re-exported so the widgets already importing this file keep working.
export 'package:music_app/const/theme/tokens.dart' show kGlow;

/// Nav-rail state colours.
///
/// Inactive used to be [Colors.black54], which is close to invisible on top of
/// a dark album-art gradient, then `white54`, which measures under 3:1 over a
/// bright one. Both states are white, separated by opacity, and inactive is now
/// [AppColors.textSecondary] rather than a third white invented here.
///
/// 72% is a smaller step down from active than `white54` was, and that is
/// deliberate: nav state is already carried by the filled/outlined icon pair
/// and the glow, so the colour only has to be the third signal — it does not
/// have to be dim enough to fail contrast.
class DashBoardOptionsColors {
  const DashBoardOptionsColors._();

  static const Color optionSelected = AppColors.textPrimary;
  static const Color optionUnselected = AppColors.textSecondary;
}
