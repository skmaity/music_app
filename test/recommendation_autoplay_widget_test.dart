import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_app/controller/settings_controller.dart';
import 'package:music_app/main_nav_pages/settings/recommendation_autoplay_control.dart';

class _Settings extends SettingsController {
  @override
  // Test double intentionally avoids plugin initialization.
  // ignore: must_call_super
  void onInit() {}
  bool? changed;
  @override
  Future<void> setRecommendationAutoplayEnabled(bool value) async {
    changed = value;
    recommendationAutoplayEnabled.value = value;
  }
}

void main() {
  testWidgets('recommendation autoplay toggle describes generated tracks only',
      (tester) async {
    final settings = _Settings();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: RecommendationAutoplayControl(settings: settings)),
    ));
    expect(find.text('Recommendation autoplay'), findsOneWidget);
    expect(find.textContaining('Manually queued songs'), findsOneWidget);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pump();
    expect(settings.changed, isFalse);
  });
}
