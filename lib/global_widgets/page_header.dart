import 'package:flutter/material.dart';
import 'package:music_app/const/theme/tokens.dart';

/// Right-aligned 45px page title — the app's most recognisable layout move,
/// mirroring the nav rail on the left.
///
/// Wrapped in [SafeArea] because the Dashboard sets `extendBodyBehindAppBar`,
/// so without it the title lands under the notch on a modern phone.
class PageHeader extends StatelessWidget {
  const PageHeader(this.title, {super.key, this.onBack});

  final String title;

  /// Shows a glowing back arrow on the left when non-null.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            Space.xs, Space.md, Space.gutter, Space.md),
        child: Row(
          children: [
            if (onBack != null)
              IconButton(
                onPressed: onBack,
                tooltip: 'Back',
                icon: const Icon(
                  Icons.arrow_back_ios_rounded,
                  color: Colors.white,
                  shadows: kGlow,
                ),
              ),
            Expanded(
              // Scale down rather than truncate. At 45px with `maxLines: 1`
              // and an ellipsis, "Quick picks" became "Quick p…" at the first
              // notch of Dynamic Type — the title of the screen, unreadable,
              // for the users most likely to need it. FittedBox keeps the
              // whole word at every text scale.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  title,
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  softWrap: false,
                  style: Theme.of(context).textTheme.displayLarge,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
