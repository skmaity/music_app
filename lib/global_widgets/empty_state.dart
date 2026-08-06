import 'package:flutter/material.dart';
import 'package:music_app/const/theme/tokens.dart';

/// The one empty / not-built-yet state: mark, headline, explanation, and —
/// where there is a sensible one — something to do about it.
///
/// Every list uses it. A list that renders nothing when it is empty reads as a
/// broken screen.
///
/// Write [message] as the next step ("Tap the heart while a song is playing"),
/// not a status report ("0 items").
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.headline,
    required this.message,
    this.icon = Icons.music_off_rounded,
    this.asset,
    this.actionLabel,
    this.onAction,
    this.markColor = AppColors.textTertiary,
  });

  final String headline;
  final String message;
  final IconData icon;

  /// Optional image in place of [icon] — used by the Settings placeholder.
  final String? asset;

  /// Both or neither. Omit when the screen genuinely has no next step to
  /// offer; a button that does nothing useful is worse than no button.
  final String? actionLabel;
  final VoidCallback? onAction;

  /// The mark recedes by default. It used to be 45px at `white70` above a 25px
  /// headline — top-heavy, the mark outweighing the message.
  final Color markColor;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Space.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (asset != null)
              Image.asset(asset!, height: Space.xxxl)
            else
              Icon(icon, size: Space.xxxl, color: markColor),
            const SizedBox(height: Space.lg),
            Text(
              headline,
              textAlign: TextAlign.center,
              style: text.titleLarge,
            ),
            // Was `SizedBox(height: 2)` — not a spacing value, an accident,
            // and it made the two lines collide.
            const SizedBox(height: Space.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: Space.xl),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// A request that **failed**, which is not the same thing as a list with
/// nothing in it.
///
/// Before this existed, every failure rendered [EmptyState]: "you have no
/// favourites" and "the request failed" were pixel-identical, and the user had
/// no way to know whether retrying was worth it.
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.onRetry,
    this.headline = 'Could not load',
    this.message = 'Something went wrong on the way to the server.',
  });

  final VoidCallback onRetry;
  final String headline;
  final String message;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.cloud_off_rounded,
      markColor: AppColors.danger,
      headline: headline,
      message: message,
      actionLabel: 'Try again',
      onAction: onRetry,
    );
  }
}
