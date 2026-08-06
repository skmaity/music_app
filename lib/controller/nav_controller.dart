import 'package:get/get.dart';

/// Which rail destination is showing, and which way the next switch travels.
///
/// This lived as a `State` field on the Dashboard, which meant nothing else
/// could move the user — so an empty state could describe the next step
/// ("browse songs") but never offer it.
class NavController extends GetxController {
  final RxInt index = 0.obs;

  /// `1` moving down the rail, `-1` moving up. Read by the page transition.
  double direction = 1;

  void go(int next) {
    if (next == index.value) return;
    direction = next > index.value ? 1 : -1;
    index.value = next;
  }
}

/// Rail order, so callers say what they mean.
abstract final class NavDestination {
  static const int quickPicks = 0;
  static const int songs = 1;
  static const int favourites = 2;
  static const int artists = 3;
  static const int settings = 4;
}
