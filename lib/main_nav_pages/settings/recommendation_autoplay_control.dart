import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_app/const/theme/tokens.dart';
import 'package:music_app/controller/settings_controller.dart';

/// Visible radio preference; explicit queue entries are never gated by it.
class RecommendationAutoplayControl extends StatelessWidget {
  const RecommendationAutoplayControl({super.key, required this.settings});

  final SettingsController settings;

  @override
  Widget build(BuildContext context) => Obx(
        () => SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: Space.md,
            vertical: Space.xs,
          ),
          secondary:
              const Icon(Icons.radio_rounded, color: AppColors.textSecondary),
          title: Text('Recommendation autoplay',
              style: Theme.of(context).textTheme.bodyMedium),
          subtitle: Text(
            'Play suggested tracks after Up next. Manually queued songs '
            'keep playing when this is off.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
          value: settings.recommendationAutoplayEnabled.value,
          onChanged: settings.setRecommendationAutoplayEnabled,
        ),
      );
}
