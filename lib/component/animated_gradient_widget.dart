import 'package:flutter/material.dart';

class AnimatedGradient extends StatefulWidget {
  const AnimatedGradient({
    super.key,
    required this.primaryColors,
    required this.secondaryColors,
    this.duration = const Duration(seconds: 4),
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
  final Duration duration;
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
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late List<ColorTween> _colorTweens;
  late AlignmentTween _beginAlignment;
  late AlignmentTween _endAlignment;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: widget.reverse);

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _setupTweens();
  }

  @override
  void didUpdateWidget(covariant AnimatedGradient oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.primaryColors != widget.primaryColors ||
        oldWidget.secondaryColors != widget.secondaryColors) {
      _setupTweens();
    }
  }

  void _setupTweens() {
    _colorTweens = List.generate(
      widget.primaryColors.length,
      (i) => ColorTween(
        begin: widget.primaryColors[i],
        end: widget.secondaryColors[i],
      ),
    );

    final primaryBegin = widget.primaryBeginGeometry?.resolve(widget.textDirectionForGeometry) ?? widget.primaryBegin;
    final primaryEnd = widget.primaryEndGeometry?.resolve(widget.textDirectionForGeometry) ?? widget.primaryEnd;
    final secondaryBegin = widget.secondaryBeginGeometry?.resolve(widget.textDirectionForGeometry) ?? widget.secondaryBegin;
    final secondaryEnd = widget.secondaryEndGeometry?.resolve(widget.textDirectionForGeometry) ?? widget.secondaryEnd;

    _beginAlignment = AlignmentTween(
      begin: primaryBegin,
      end: primaryEnd,
    );
    _endAlignment = AlignmentTween(
      begin: secondaryBegin,
      end: secondaryEnd,
    );
  }

  List<Color> _evaluateColors() {
    return _colorTweens
        .map((tween) => tween.evaluate(_animation)!)
        .toList();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
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
