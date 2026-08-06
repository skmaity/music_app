import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class UseridController extends GetxController {
  /// The id, once it has been read. Empty until then — bind to this for
  /// display, but use [id] anywhere the value is actually sent somewhere.
  RxString userId = ''.obs;

  /// Backs [id]. A `late final Future<String>` — what this used to be —
  /// can't be reassigned, and Settings' "reset identity" action needs to do
  /// exactly that: swap the resolved id for a freshly minted one without
  /// tearing down the controller. A plain mutable field can be replaced
  /// wholesale; [id] below is the stable getter over it.
  Future<String> _idFuture = Future.value('');

  /// Resolves to the stable per-install id.
  ///
  /// Await this rather than reading [userId] directly. The read comes off disk
  /// and nothing used to wait for it, so anything asking in the first moments
  /// of a session sent `userid: ""` — which every endpoint rejects as a missing
  /// field, with a `success: false` the app then threw away.
  ///
  /// A getter over [_idFuture] rather than the future stored directly, so
  /// [resetIdentity] can point it at a new future without changing this
  /// contract. `SongController._postFavourite` and
  /// `UserFavouriteController.getUserFavourites` both do
  /// `await Get.find<UseridController>().id` — that keeps compiling and
  /// keeps working unchanged; a call already mid-await captured the old
  /// future by reference and resolves to the old id, and every call after
  /// [resetIdentity] returns reads the new one.
  Future<String> get id => _idFuture;

  @override
  void onInit() {
    super.onInit();
    // Start the read at launch rather than on the first favourite.
    _idFuture = _load();
    _idFuture.ignore();
  }

  Future<String> _load() async {
    final prefs = await SharedPreferences.getInstance();

    final stored = prefs.getString('user_id');
    if (stored != null && stored.isNotEmpty) return userId.value = stored;

    final created = const Uuid().v4();
    await prefs.setString('user_id', created);
    return userId.value = created;
  }

  /// Clears the stored uuid and mints a new one — Settings' "reset identity"
  /// action. Callers should go through `SettingsController.resetIdentity()`
  /// instead of this directly: that also clears the favourites list and the
  /// current track's heart, both of which hang off the id this replaces and
  /// don't know to refresh themselves just because it changed.
  Future<String> resetIdentity() async {
    final prefs = await SharedPreferences.getInstance();
    final created = const Uuid().v4();
    await prefs.setString('user_id', created);
    userId.value = created;
    _idFuture = Future.value(created);
    return created;
  }
}
