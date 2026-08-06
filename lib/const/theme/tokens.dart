/// Design tokens — the single source of every value in the UI.
///
/// Before this file, `Colors.grey.shade100.withValues(alpha: 0.1)` was typed
/// out in five separate files and drifted in each. Reach for a name here rather
/// than a number; if the name you want does not exist, add it here first.
///
/// See `doc/design.md` for what each group means, and `doc/design_audit.md`
/// for why the old values were consolidated the way they were.
library;

import 'package:flutter/material.dart';

// ---------------------------------------------------------------- spacing

/// 4pt-based spacing scale. The old set mixed a 4/8 grid with a 5/10 grid
/// (`4 · 5 · 8 · 10 · 20 · 24 · 50 · 60 · 70`); these are the replacements.
abstract final class Space {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// The page gutter — one value, so every screen shares a vertical spine.
  /// Headers inset `right: 10`, rows `horizontal: 10`, empty states
  /// `horizontal: 24` and the artist list `left: 10`, so nothing lined up
  /// with anything.
  static const double gutter = md;
}

// ----------------------------------------------------------------- radius

/// Four radii plus a pill. Replaces the previous eight
/// (`100 · 30 · 20 · 15 · 12 · 10 · 8 · 4`).
///
/// Nesting rule: an inner corner is `outer - padding`, never tighter.
abstract final class Radii {
  /// Rows, chips, small thumbnails.
  static const double sm = 8;

  /// Cards, artwork, inputs.
  static const double md = 12;

  /// Panels, sheets, transport controls.
  static const double lg = 20;

  /// The nav rail and other full-height surfaces.
  static const double xl = 28;

  /// Avatars.
  static const double full = 999;
}

// --------------------------------------------------------------- controls

/// Control sizes.
///
/// The transport was three `FloatingActionButton.large` at an identical 96dp,
/// so the screen had no primary action. [primary] and [secondary] are the
/// ladder: one filled, dominant control and two ghosts beside it. Both clear
/// the 48dp minimum target.
abstract final class Controls {
  static const double primary = 72;
  static const double secondary = 56;

  static const double iconPrimary = 36;
  static const double iconSecondary = 32;

  /// Inline icons that sit with text — the favourite heart, field affordances.
  static const double iconInline = 28;

  /// Album art in the tightest context there is — a sheet header, where the
  /// artwork is identifying a subject rather than being the subject.
  ///
  /// No longer the now-playing bar. That used this and so showed the smallest
  /// artwork anywhere in the app, *underneath* the list rows it was smaller
  /// than; it uses [thumbRow] now.
  static const double thumb = 48;

  /// Album art in a list row, and in the now-playing bar. The app's thesis is
  /// that the artwork *is* the experience, and rows used to show it at 50 —
  /// the smallest artwork of any music app of this kind, in the component the
  /// app repeats most.
  static const double thumbRow = 56;

  /// A person, at the top of their own page. Always at [Radii.full] — a circle
  /// is how the whole industry encodes "this is an artist, not an album".
  static const double avatar = 120;

  /// Hairline progress, as under the now-playing bar.
  static const double progressBar = 2;

  /// The seek thumb at rest, and while you have hold of it.
  static const double seekThumb = 6;
  static const double seekThumbGrab = 10;
}

// ------------------------------------------------------------------ colour

/// There is no brand colour. Hierarchy is white at three opacities; the
/// gradient supplies every hue. [accent] is the only fixed colour in the app.
abstract final class AppColors {
  /// Titles, active nav, primary icons.
  static const Color textPrimary = Colors.white;

  /// Artists, hints, inactive nav — anything that must stay readable.
  static const Color textSecondary = Color(0xB8FFFFFF); // 72%

  /// Metadata and empty-state explainers. The floor, and never body copy: it
  /// is the first thing to fail contrast over a bright cover.
  static const Color textTertiary = Color(0x80FFFFFF); // 50%

  /// The heart, and nothing else. One emotional control, one colour.
  static const Color accent = Colors.pinkAccent;

  /// Failure. The app previously had no danger colour at all, which is why a
  /// failed request and an empty list looked identical.
  static const Color danger = Color(0xFFFF6B6B);

  /// Veil and scrim base.
  static const Color scrim = Colors.black;

  // -- glass ---------------------------------------------------------------
  //
  // Three levels, one recipe — see `GlassPanel`. There used to be four
  // unrelated ones: blurred at 0.4, blurred at 0.2, unblurred at 0.4,
  // unblurred at 0.1, two of them with borders and two without. That is a set
  // of accidents, not an elevation ladder.

  /// Rows and chips. Fill only: no blur, no edge, no shadow. A `BackdropFilter`
  /// per row is expensive in a `ListView`, and a row is a fill, not a pane.
  static const Color glass1 = Color(0x1AF5F5F5); // grey.shade100 @ 10%

  /// Cards and bars — the player card, the now-playing bar.
  static const Color glass2 = Color(0x33F5F5F5); // grey.shade100 @ 20%

  /// The nav rail, and anything else that spans an edge.
  ///
  /// This was 40%, which is not glass — it is a grey bar, and it made the
  /// app's weakest contrast pair: white text on a ~40% white surface. The pane
  /// now reads as a pane through [glassEdge] and [kPanelShadow] instead of
  /// through sheer opacity.
  static const Color glass3 = Color(0x3DF5F5F5); // grey.shade100 @ 24%

  /// The 1px hairline that turns fog into a pane.
  ///
  /// Every mature glass system defines its surfaces with one — Apple's
  /// materials, Vision OS. This app had none, and the one border it did have
  /// was 0.5px of a *second* grey at 40%, invisible over a moving gradient.
  static const Color glassEdge = Color(0x38FFFFFF); // white @ 22%

  /// The unplayed part of a progress track — the seek bar, the now-playing
  /// bar's hairline. Visible over a bright cover, quiet over a dark one.
  static const Color trackInactive = Color(0x3DFFFFFF); // 24%

  /// The press state, everywhere. Set once on the theme as `splashColor` and
  /// `highlightColor`, so every `InkWell` in the app answers a tap the same
  /// way — there was no pressed style defined anywhere before.
  static const Color overlay = Color(0x1FFFFFFF); // 12%
}

/// Standard blur sigma for glass levels 2 and 3.
const double kGlassBlur = 10.0;

/// The most of the viewport a modal bottom sheet may take.
///
/// Below 1.0 on purpose. Tapping the scrim is one of the two standard ways out
/// of a sheet, and the player's options sheet — four sections, two of them
/// wrapping to two rows of pills — was free to grow to whatever its content
/// needed, which on a shorter phone left barely any scrim to tap. A sheet with
/// no reachable scrim and no working drag is a sheet with no exit.
const double kSheetMaxHeightFraction = 0.75;

// --------------------------------------------------------------- backdrop

// No tokens for the album-art background. `design_audit.md` §7 asks for a
// luminance clamp on `vibrantColor` and a dark fallback in place of
// `Colors.white`, and both were built here — but the wider background rework
// they shipped with regressed the screen on device, and the whole thing went
// back to its original, working implementation at the author's request.
// `component/animated_gradient_widget.dart` and `controller/
// background_controller.dart` own their own values now, deliberately.

/// The resting veil, on every screen that has one.
///
/// The player used to rest at `0.0` — nothing at all between a vibrant,
/// full-bleed gradient and white text, which a bright cover pushes under 4.5:1
/// — while the dashboard rested at `0.1`. One contrast floor now: low enough
/// that the palette still reads as the palette, high enough that the type is
/// safe on the worst cover.
const double kVeilRest = 0.12;

/// Bottom-up scrim for type laid **over** artwork.
///
/// A cover is arbitrary — it can be white, or busy, or both — so anything
/// written on one needs its own ground rather than trusting the image.
const LinearGradient kArtScrim = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0x00000000), Color(0x40000000), Color(0xD9000000)],
  stops: [0.45, 0.72, 1.0],
);

/// Under a glass panel.
///
/// The app had **no shadows at all**, so the rail, the player card and a list
/// row all floated at the same z and glass established material without ever
/// establishing order. The glow cannot do this job: light emitted outward
/// reads as "on", never as "above".
const List<BoxShadow> kPanelShadow = [
  BoxShadow(color: Color(0x40000000), blurRadius: 24, offset: Offset(0, 8)),
];

/// Under the player artwork.
///
/// The cover is the app's thesis and it sat flat on the glass with nothing
/// separating the two. Blur stays under the card's inner padding so the card's
/// own clip does not cut it off.
const List<BoxShadow> kArtShadow = [
  BoxShadow(color: Color(0x59000000), blurRadius: 20, offset: Offset(0, 6)),
];

// ------------------------------------------------------------------- glow

/// The signature. Active state, page-title marks and primary icons only —
/// never body text, list titles, subtitles or timestamps. Glowing everything
/// says nothing.
const List<Shadow> kGlow = [
  Shadow(blurRadius: 9.0, color: Colors.white, offset: Offset(0, 0)),
];

// ------------------------------------------------------------------- type

/// Type scale. Every step carries weight, line-height and tracking — the app
/// previously ran entirely at w400 with default metrics, which is why
/// hierarchy had to be carried by size alone.
///
/// Colour is applied by the theme, not here.
abstract final class AppText {
  /// Page titles. Size is fixed at 45 by design; the fix is the metrics —
  /// display type at default line-height reads as enlarged body copy.
  static const TextStyle display = TextStyle(
    fontSize: 45,
    fontWeight: FontWeight.w400,
    height: 1.02,
    letterSpacing: -1.2,
  );

  /// In-page section headings ("More").
  static const TextStyle headline = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w500,
    height: 1.1,
    letterSpacing: -0.5,
  );

  /// Empty-state headlines, and the player's track title — the most-looked-at
  /// string in the app, which used to run at 18 and rank below a tab label.
  static const TextStyle title = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: -0.2,
  );

  /// One step above body, for a line that leads a block without being a
  /// heading. The player's track title outranks this and uses [title].
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  /// Body, row titles, timestamps, nav labels.
  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  /// Empty-state explainers, secondary labels.
  static const TextStyle label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.1,
  );

  /// Metadata only. Anything read as a sentence stays at 16 or above.
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.35,
    letterSpacing: 0.2,
  );

  /// Timestamps and durations. Tabular figures stop the layout twitching as
  /// the seconds tick.
  static const TextStyle numeric = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.4,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}

// ----------------------------------------------------------------- motion

/// Two speeds, deliberately: content moves fast, the background moves slowly.
/// Never let the background animate at content speed.
abstract final class Motion {
  /// Press states, icon swaps.
  static const Duration fast = Duration(milliseconds: 150);

  /// The default for anything the user triggered.
  static const Duration normal = Duration(milliseconds: 220);

  /// Page transitions. Was 800ms — roughly 2.5x the platform standard, on the
  /// most repeated interaction in the app.
  static const Duration page = Duration(milliseconds: 300);

  /// Per-item list stagger. Was 100ms, which took a 20-row list two full
  /// seconds to finish appearing.
  static const Duration stagger = Duration(milliseconds: 40);

  /// The veil closing over a palette swap.
  static const Duration veilIn = Duration(milliseconds: 600);

  /// The veil releasing. Slow on purpose — it is what stops the gradient
  /// popping when the palette lands. The player used to run this at 5s because
  /// it faded all the way to zero; now that it rests at [kPlayerVeilRest] like
  /// the dashboard, both screens share one duration.
  static const Duration veilOut = Duration(milliseconds: 3000);

  /// The looping background gradient.
  static const Duration ambient = Duration(seconds: 4);

  /// One pass of the skeleton shimmer.
  static const Duration shimmer = Duration(milliseconds: 1400);

  /// How long typing has to stop before a query is worth sending. Search used
  /// to fire on every keystroke, so the whole result list re-animated in on
  /// every character typed.
  static const Duration debounce = Duration(milliseconds: 300);

  /// Entering: decelerate into place.
  static const Curve enter = Curves.easeOutCubic;

  /// Leaving: accelerate away.
  static const Curve exit = Curves.easeInCubic;

  /// Exits run at 65% of their entrance, so the UI feels responsive rather
  /// than polite. Nothing in the app used to exit faster than it entered.
  static Duration exitOf(Duration enter) => enter * 0.65;

  /// How far a page shifts on a rail switch, as a fraction of the content
  /// column. Material's shared-axis transition moves ~30dp — the outgoing page
  /// leaves one way and the incoming arrives from the other. This app used to
  /// fly a whole screen width from the right in *both* directions, so the two
  /// pages travelled together rather than past each other.
  static const double pageShift = 0.08;
}
