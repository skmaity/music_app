import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:music_app/const/theme/tokens.dart';
import 'package:music_app/global_widgets/motion.dart';

/// Swapped in for the page body when `InternetController` reports no
/// connection.
///
/// **No `Scaffold`.** This renders inside the dashboard's Scaffold; nesting a
/// second one was a direct violation of the app's own composition rule, and it
/// is why the page used to paint its own background over the gradient.
class NointernetPage extends StatelessWidget {
  const NointernetPage({super.key});

  @override
  Widget build(BuildContext context) {
    final style =
        Theme.of(context).textTheme.titleLarge?.copyWith(shadows: kGlow);

    return Center(
      // The connection dropping is a state change the user did not cause, so
      // it is announced rather than silently redrawn.
      child: Semantics(
        liveRegion: true,
        label: 'No connection',
        excludeSemantics: true,
        // The flicker used to loop forever regardless of the platform's
        // reduced-motion setting — both an accessibility violation and a
        // photosensitivity concern (`design_audit.md` C3).
        child: noMotion(context)
            ? Text('No Connection', style: style)
            : DefaultTextStyle(
                style: style ?? const TextStyle(),
                child: AnimatedTextKit(
                  repeatForever: true,
                  animatedTexts: [FlickerAnimatedText('No Connection')],
                ),
              ),
      ),
    );
  }
}
