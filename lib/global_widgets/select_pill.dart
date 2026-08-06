import 'package:flutter/material.dart';
import 'package:music_app/const/theme/tokens.dart';

/// A stadium chip, selected or not — the app's one "pick one of these" shape.
///
/// Modelled on `filledButtonTheme`'s white pill rather than inventing a second
/// control language per screen. Shared by the player's speed row, its sleep
/// timer, and Settings' default-speed and skip-interval pickers; it lives here
/// rather than beside any one of them so a fourth picker cannot start a fourth
/// variant.
class SelectPill extends StatelessWidget {
  const SelectPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.semanticLabel,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Material(
      color: selected ? AppColors.textPrimary : AppColors.glass1,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        // Inside the InkWell, not around it — from outside, excludeSemantics
        // drops the InkWell's own tap action and leaves a control a screen
        // reader can read but not activate.
        child: Semantics(
          button: true,
          selected: selected,
          label: semanticLabel ?? label,
          excludeSemantics: true,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.lg),
              child: Center(
                child: Text(
                  label,
                  style: text.bodyLarge?.copyWith(
                    color: selected ? Colors.black : AppColors.textPrimary,
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
