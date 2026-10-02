import 'package:flutter_test/flutter_test.dart';
import 'package:music_app/controller/settings_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _SettingsWithoutCache extends SettingsController {
  @override
  Future<void> refreshImageCacheSize() async {}
}

Future<_SettingsWithoutCache> _load(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  final settings = _SettingsWithoutCache()..onInit();
  for (var attempts = 0; attempts < 20 && !settings.isReady.value; attempts++) {
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  expect(settings.isReady.value, isTrue);
  return settings;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('legacy autoplay off migrates to recommendation autoplay off', () async {
    final settings = await _load({'settings_autoplay_enabled': false});
    expect(settings.recommendationAutoplayEnabled.value, isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('settings_recommendation_autoplay_enabled'), isFalse);
  });

  test('new recommendation preference takes precedence over legacy flag',
      () async {
    final settings = await _load({
      'settings_autoplay_enabled': false,
      'settings_recommendation_autoplay_enabled': true,
    });
    expect(settings.recommendationAutoplayEnabled.value, isTrue);
    await settings.setRecommendationAutoplayEnabled(false);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('settings_recommendation_autoplay_enabled'), isFalse);
  });

  test('fresh install defaults recommendations on', () async {
    final settings = await _load({});
    expect(settings.recommendationAutoplayEnabled.value, isTrue);
  });
}
