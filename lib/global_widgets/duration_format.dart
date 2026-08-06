/// Duration formatting shared by the player page's seek bar, the sleep-timer
/// countdown in the "more" sheet, and anywhere else a duration needs to be
/// written or spoken the same way.
///
/// Both functions used to be private statics on `_PlayerPageState`. They
/// moved here once the sleep timer's countdown (armed from a different file)
/// needed the same `0:42` formatting the seek bar already had — duplicating a
/// four-line function across two files is exactly how the app's old spacing
/// and colour values drifted.
library;

/// `0:42`, not `00:42`. Minutes are not zero-padded — no clock, player or
/// stopwatch anywhere in the app writes a track under a minute as `00:42`.
String formatClock(Duration d) {
  final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '${d.inMinutes}:$seconds';
}

/// Screen readers say "one colon twenty three" for `1:23` — no unit, no
/// meaning. Used wherever a duration needs to be announced rather than read.
String formatSpoken(Duration d) {
  final m = d.inMinutes;
  final s = d.inSeconds.remainder(60);
  return '$m ${m == 1 ? 'minute' : 'minutes'} '
      '$s ${s == 1 ? 'second' : 'seconds'}';
}
