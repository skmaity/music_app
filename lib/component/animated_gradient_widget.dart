import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

class AnimatedGradient extends StatefulWidget {
  const AnimatedGradient({
    super.key,
    required this.primaryColors,
    required this.secondaryColors,
    this.duration = const Duration(seconds: 4),
    this.transition = const Duration(milliseconds: 1200),
    this.reverse = true,
    this.animateAlignments = true,
    this.child,
    this.primaryBegin = Alignment.topLeft,
    this.primaryEnd = Alignment.topRight,
    this.secondaryBegin = Alignment.bottomLeft,
    this.secondaryEnd = Alignment.bottomRight,
    this.primaryBeginGeometry,
    this.primaryEndGeometry,
    this.secondaryBeginGeometry,
    this.secondaryEndGeometry,
    this.textDirectionForGeometry = TextDirection.ltr,
  })  : assert(primaryColors.length == secondaryColors.length),
        assert(primaryColors.length >= 2);

  final List<Color> primaryColors;
  final List<Color> secondaryColors;

  /// One pass of the ambient loop.
  final Duration duration;

  /// How long a *new* palette takes to displace the old one.
  ///
  /// Deliberately far longer than the 150-300ms a micro-interaction gets: this
  /// is the background, and the background moves slowly. It is also shorter
  /// than the veil's 3s reveal, so the new colours have finished settling by
  /// the time the scrim is out of the way.
  final Duration transition;

  final bool reverse;
  final bool animateAlignments;
  final Widget? child;

  final Alignment primaryBegin;
  final Alignment primaryEnd;
  final Alignment secondaryBegin;
  final Alignment secondaryEnd;

  final AlignmentGeometry? primaryBeginGeometry;
  final AlignmentGeometry? primaryEndGeometry;
  final AlignmentGeometry? secondaryBeginGeometry;
  final AlignmentGeometry? secondaryEndGeometry;

  final TextDirection textDirectionForGeometry;

  @override
  State<AnimatedGradient> createState() => _AnimatedGradientState();
}

class _AnimatedGradientState extends State<AnimatedGradient>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late AlignmentTween _beginAlignment;
  late AlignmentTween _endAlignment;
  bool _reduceMotion = false;

  /// Drives the crossfade from the outgoing palette to the incoming one.
  ///
  /// Separate from [_controller] because the two run on unrelated clocks: the
  /// ambient loop never stops, and a song change has to be able to blend
  /// underneath it without resetting or stuttering it.
  late AnimationController _blend;
  late Animation<double> _blendCurve;

  /// The palette being faded *from*. Both lists, because the ambient loop is
  /// itself a lerp between primary and secondary — a crossfade has to move
  /// both ends of it, or the gradient would fade to the new colours at one
  /// corner while still arriving from the old ones at the other.
  late List<Color> _fromPrimary;
  late List<Color> _fromSecondary;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _blend = AnimationController(
      vsync: this,
      duration: widget.transition,
      value: 1.0,
    );

    // Decelerate into place: the palette is arriving, and arrivals ease out.
    _blendCurve = CurvedAnimation(parent: _blend, curve: Curves.easeOutCubic);

    _fromPrimary = widget.primaryColors;
    _fromSecondary = widget.secondaryColors;

    _setupTweens();
  }

  // The gradient loops forever, so it is the app's biggest reduced-motion
  // offender. Hold it on the primary colours instead of stopping mid-tween.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _reduceMotion = MediaQuery.of(context).disableAnimations;
    if (_reduceMotion) {
      _controller.stop();
      // Land the crossfade rather than abandoning it part-blended, which would
      // strand the gradient on a mix of two songs' palettes.
      _blend.value = 1.0;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: widget.reverse);
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedGradient oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.transition != oldWidget.transition) {
      _blend.duration = widget.transition;
    }

    // `listEquals`, not `!=`. Both call sites hand this a fresh
    // `List<Color>.from(...)` on every rebuild, so identity always differs and
    // an identity check restarted the crossfade on rebuilds that changed no
    // colour at all — the seek bar ticking would have kept resetting it.
    if (!listEquals(oldWidget.primaryColors, widget.primaryColors) ||
        !listEquals(oldWidget.secondaryColors, widget.secondaryColors)) {
      _startBlend(oldWidget);
    }

    if (oldWidget.primaryBegin != widget.primaryBegin ||
        oldWidget.primaryEnd != widget.primaryEnd ||
        oldWidget.secondaryBegin != widget.secondaryBegin ||
        oldWidget.secondaryEnd != widget.secondaryEnd) {
      _setupTweens();
    }
  }

  /// Begins the crossfade onto the palette [widget] now carries.
  void _startBlend(AnimatedGradient oldWidget) {
    // Fade from what is *on screen right now*, not from the palette we were
    // nominally heading to. Skipping two tracks quickly used to mean the
    // second change snapped; this makes the blend interruptible, so it just
    // re-aims from wherever the half-finished fade had got to.
    _fromPrimary = _blendedFrom(oldWidget.primaryColors, _fromPrimary);
    _fromSecondary = _blendedFrom(oldWidget.secondaryColors, _fromSecondary);

    if (_reduceMotion) {
      _blend.value = 1.0;
    } else {
      _blend.forward(from: 0.0);
    }
  }

  /// Where a channel of the outgoing palette actually sits at this instant.
  List<Color> _blendedFrom(List<Color> target, List<Color> from) {
    final t = _blendCurve.value;
    return List.generate(
      target.length,
      (i) => i < from.length ? Color.lerp(from[i], target[i], t)! : target[i],
    );
  }

  void _setupTweens() {
    final primaryBegin =
        widget.primaryBeginGeometry?.resolve(widget.textDirectionForGeometry) ??
            widget.primaryBegin;
    final primaryEnd =
        widget.primaryEndGeometry?.resolve(widget.textDirectionForGeometry) ??
            widget.primaryEnd;
    final secondaryBegin = widget.secondaryBeginGeometry
            ?.resolve(widget.textDirectionForGeometry) ??
        widget.secondaryBegin;
    final secondaryEnd =
        widget.secondaryEndGeometry?.resolve(widget.textDirectionForGeometry) ??
            widget.secondaryEnd;

    _beginAlignment = AlignmentTween(
      begin: primaryBegin,
      end: primaryEnd,
    );
    _endAlignment = AlignmentTween(
      begin: secondaryBegin,
      end: secondaryEnd,
    );
  }

  /// The gradient's colours for this frame.
  ///
  /// Two lerps, in order: the crossfade moves each end of the ambient sweep
  /// from the old palette onto the new one, then the sweep runs between those
  /// two ends as it always did. That order is what lets the loop carry on
  /// smoothly *through* a song change rather than jumping at it.
  List<Color> _evaluateColors() {
    final blend = _blendCurve.value;
    final sweep = _animation.value;

    return List.generate(widget.primaryColors.length, (i) {
      final from = i < _fromPrimary.length
          ? Color.lerp(_fromPrimary[i], widget.primaryColors[i], blend)!
          : widget.primaryColors[i];
      final to = i < _fromSecondary.length
          ? Color.lerp(_fromSecondary[i], widget.secondaryColors[i], blend)!
          : widget.secondaryColors[i];
      return Color.lerp(from, to, sweep)!;
    });
  }

  @override
  void dispose() {
    _blend.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_reduceMotion) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: widget.primaryBegin,
            end: widget.primaryEnd,
            colors: widget.primaryColors,
          ),
        ),
        child: widget.child,
      );
    }

    return AnimatedBuilder(
      // Both clocks. The ambient sweep and the palette crossfade advance
      // independently, and a frame that missed either would stutter.
      animation: Listenable.merge([_animation, _blend]),
      builder: (_, __) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: widget.animateAlignments
                  ? _beginAlignment.evaluate(_animation)
                  : widget.primaryBegin,
              end: widget.animateAlignments
                  ? _endAlignment.evaluate(_animation)
                  : widget.primaryEnd,
              colors: _evaluateColors(),
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}
