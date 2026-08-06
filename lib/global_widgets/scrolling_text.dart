import 'package:flutter/material.dart';
import 'package:music_app/global_widgets/motion.dart';
import 'package:text_scroll/text_scroll.dart';

/// A single line of text that scrolls sideways when it doesn't fit, instead
/// of wrapping or clipping to an ellipsis.
///
/// Falls back to a plain, ellipsised [Text] under [noMotion]. `text_scroll`
/// has no reduced-motion switch of its own, and a title marqueeing forever
/// past a user who asked for less motion is exactly what `noMotion` exists to
/// stop — the now-playing marker and the background gradient both carry the
/// same branch for the same reason.
class ScrollingText extends StatelessWidget {
  const ScrollingText(this.text, {super.key, this.style, this.textAlign});

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    if (noMotion(context)) {
      return Text(
        text,
        style: style,
        textAlign: textAlign,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    // TextScroll only starts scrolling once the text is wider than the box
    // it's given; anything short enough to fit just sits still, same as the
    // Text above — there is no separate "does this need to scroll" check to
    // get wrong.
    return TextScroll(
      text,
      style: style,
      textAlign: textAlign,
      velocity: const Velocity(pixelsPerSecond: Offset(30, 0)),
      delayBefore: const Duration(seconds: 1),
      pauseBetween: const Duration(seconds: 2),
      fadedBorder: true,
      fadedBorderWidth: 0.08,
    );
  }
}
