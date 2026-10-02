import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:music_app/controller/settings_controller.dart';
import 'package:music_app/main_nav_pages/library/library_page.dart';
import 'package:music_app/services/local_media_index.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(LocalMediaPlatform.channel, (call) async {
      if (call.method == 'loadArtwork') return null;
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(LocalMediaPlatform.channel, null);
    Get.reset();
  });

  testWidgets('local library explains denied access at 320px', (tester) async {
    await _setPhoneSurface(tester);
    final index = LocalMediaIndex(
      gateway: const _FakeGateway(LocalMediaPermission.denied),
    );

    await _pumpLibrary(tester, index);

    expect(find.text('Media access is off'), findsOneWidget);
    expect(find.text('Allow access'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('permanent denial offers Android settings recovery',
      (tester) async {
    await _setPhoneSurface(tester);
    final index = LocalMediaIndex(
      gateway: const _FakeGateway(LocalMediaPermission.permanentlyDenied),
    );

    await _pumpLibrary(tester, index);

    expect(find.text('Open settings'), findsOneWidget);
    expect(find.textContaining('system settings'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('populated local library fits at 320px', (tester) async {
    await _setPhoneSurface(tester);
    final index = LocalMediaIndex(
      gateway: const _FakeGateway(
        LocalMediaPermission.granted,
        records: [
          LocalMediaRecord(
            contentUri: 'content://media/external/audio/media/1',
            title: 'Small-screen song',
            artist: 'Nyro Artist',
            album: 'Pocket Album',
          ),
        ],
      ),
    );

    await _pumpLibrary(tester, index);

    expect(find.text('Small-screen song'), findsOneWidget);
    expect(find.text('Search local music'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('large local library reveals the next page near list end',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final records = [
      for (var id = 0; id < 125; id += 1)
        LocalMediaRecord(
          contentUri: 'content://media/external/audio/media/$id',
          title: 'Track $id',
          artist: 'Artist',
        ),
    ];
    final index = LocalMediaIndex(
      gateway: _FakeGateway(
        LocalMediaPermission.granted,
        records: records,
      ),
    );

    await _pumpLibrary(tester, index);
    expect(find.text('Track 99'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('Track 99'),
      500,
      scrollable: find.byType(Scrollable).last,
      maxScrolls: 40,
    );
    await tester.pumpAndSettle();

    expect(find.text('Track 99'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _setPhoneSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(320, 640));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Future<void> _pumpLibrary(
  WidgetTester tester,
  LocalMediaIndex index,
) async {
  Get.put<SettingsController>(_TestSettingsController());
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(body: LocalLibraryPage(index: index)),
    ),
  );
  await tester.pumpAndSettle();
}

class _TestSettingsController extends SettingsController {
  // The production onInit performs preference and cache I/O. This test double
  // only supplies the already-initialized reduced-motion observable.
  @override
  // ignore: must_call_super
  void onInit() {}
}

class _FakeGateway implements LocalMediaGateway {
  const _FakeGateway(this.permission, {this.records = const []});

  final LocalMediaPermission permission;
  final List<LocalMediaRecord> records;

  @override
  Future<LocalMediaPermission> checkPermission() async => permission;

  @override
  Future<List<LocalMediaRecord>> queryAudio() async {
    if (permission != LocalMediaPermission.granted) {
      throw StateError('MediaStore must not be queried');
    }
    return records;
  }

  @override
  Future<LocalMediaPermission> requestPermission() async => permission;
}
