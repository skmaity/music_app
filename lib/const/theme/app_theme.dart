import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:music_app/const/theme/tokens.dart';

/// The app's one theme.
///
/// Before this file, `ThemeData` set three properties and every widget styled
/// itself inline — so each screen was a fresh chance to drift. Component themes
/// here are the defaults; a widget should only override one when it has a
/// reason worth a comment.
abstract final class AppTheme {
  static ThemeData get dark {
    final text = _textTheme;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: _scheme,
      textTheme: text,

      // Every Scaffold in the app is transparent over the gradient; this is
      // only what shows for the instant before the first frame paints.
      scaffoldBackgroundColor: Colors.black,

      iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 24),

      // One press state for the whole app. Every `InkWell` used to inherit
      // whatever M3 derived from the seed colour, which is how blue-violet
      // ripples ended up firing on song rows over an orange album gradient.
      splashColor: AppColors.overlay,
      highlightColor: AppColors.overlay,

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.textPrimary,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: text.titleLarge,
      ),

      // Navigation is functional copy, so keep it in the app's UI family.
      // The old Pacifico override made already-rotated labels harder to scan.
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll(
            text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          overlayColor: WidgetStatePropertyAll(
            Colors.white.withValues(alpha: 0.08),
          ),
        ),
      ),

      // The app's one button. `textButtonTheme` below is spoken for — it is
      // what puts the nav rail in Pacifico — so anything that needs to read as
      // a button uses this: a white pill, the same language as the player's
      // primary control. No `textStyle` here on purpose; M3 takes it from
      // `textTheme.labelLarge`, which already carries Josefin Sans.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.textPrimary,
          foregroundColor: Colors.black,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: Space.xl),
          shape: const StadiumBorder(),
        ),
      ),

      sliderTheme: SliderThemeData(
        trackHeight: 4,
        activeTrackColor: AppColors.textPrimary,
        inactiveTrackColor: AppColors.trackInactive,
        // What has downloaded, behind what has played.
        secondaryActiveTrackColor: Colors.white.withValues(alpha: 0.42),
        thumbColor: AppColors.textPrimary,
        overlayColor: AppColors.overlay,
        thumbShape: const _GrabThumb(),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
        // The scrub bubble. Without it you are dragging blind — the only
        // readout is the timestamp under your own thumb.
        showValueIndicator: ShowValueIndicator.onlyForContinuous,
        valueIndicatorShape: const DropSliderValueIndicatorShape(),
        valueIndicatorColor: AppColors.textPrimary,
        valueIndicatorTextStyle:
            AppText.numeric.copyWith(color: Colors.black, fontSize: 14),
      ),

      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.textPrimary,
        textColor: AppColors.textPrimary,
      ),

      // On is the white pill the rest of the app already uses for "this is
      // live" — the filled button, the player's primary disc. Off has to be
      // legible over glass, which M3's default is not: it derives the unselected
      // track from `surfaceContainerHighest`, and this scheme's surface is
      // `0xFF07070A`, so an off switch on a Settings panel would have been a
      // near-black shape on a translucent white one.
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.black
              : AppColors.textSecondary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.textPrimary
              : AppColors.glass1,
        ),
        trackOutlineColor:
            const WidgetStatePropertyAll(AppColors.glassEdge),
      ),

      inputDecorationTheme: InputDecorationTheme(
        constraints: const BoxConstraints(minHeight: 48),
        hintStyle: AppText.body.copyWith(color: AppColors.textSecondary),
        // Fields carry a real `labelText` now, not a placeholder standing in
        // for one, so the label needs styling of its own: quiet at rest,
        // primary once the field is focused and it floats into the notch.
        labelStyle: AppText.body.copyWith(color: AppColors.textSecondary),
        floatingLabelStyle:
            AppText.label.copyWith(color: AppColors.textPrimary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.24)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
          borderSide: const BorderSide(color: AppColors.textPrimary),
        ),
      ),

      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.textPrimary,
        selectionColor: Colors.white.withValues(alpha: 0.24),
        selectionHandleColor: AppColors.textPrimary,
      ),
    );
  }

  /// Explicit, not seeded.
  ///
  /// This was `ColorScheme.fromSeed(seedColor: Colors.blue)` in an app with no
  /// blue in it — which M3 then spent on the slider's inactive track, the text
  /// cursor and selection handles, and every list-row ripple. Blue-violet
  /// ripples over an orange album gradient. Primary is white because white is
  /// what this app's interactive feedback is made of.
  static const ColorScheme _scheme = ColorScheme.dark(
    primary: AppColors.textPrimary,
    onPrimary: Colors.black,
    secondary: AppColors.accent,
    onSecondary: Colors.white,
    surface: Color(0xFF07070A),
    onSurface: AppColors.textPrimary,
    error: AppColors.danger,
    onError: Colors.black,
  );

  /// Josefin Sans everywhere, with the [AppText] metrics merged onto the M3
  /// slots so a bare `Text` inherits weight, line-height and tracking instead
  /// of running at w400 with defaults.
  static TextTheme get _textTheme {
    final base = GoogleFonts.josefinSansTextTheme().apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );

    return base.copyWith(
      displayLarge: base.displayLarge?.merge(AppText.display),
      headlineMedium: base.headlineMedium?.merge(AppText.headline),
      titleLarge: base.titleLarge?.merge(AppText.title),
      bodyLarge: base.bodyLarge?.merge(AppText.body),
      bodyMedium: base.bodyMedium?.merge(AppText.body),
      bodySmall: base.bodySmall?.merge(AppText.caption),
      labelLarge: base.labelLarge?.merge(AppText.label),
    );
  }
}

/// A seek thumb that grows when you take hold of it.
///
/// `RoundSliderThumbShape` cannot do this: its `disabledThumbRadius` lerps on
/// the *enabled* animation, not on activation, so it only ever changes size
/// when the whole control switches on or off. Scrubbing a 6pt dot gives no
/// sense of having grabbed anything.
class _GrabThumb extends SliderComponentShape {
  const _GrabThumb();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      const Size.fromRadius(Controls.seekThumbGrab);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    const grow = Controls.seekThumbGrab - Controls.seekThumb;
    context.canvas.drawCircle(
      center,
      Controls.seekThumb + grow * activationAnimation.value,
      Paint()..color = sliderTheme.thumbColor ?? AppColors.textPrimary,
    );
  }
}
