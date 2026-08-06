/// The player's repeat setting. `off` -> `all` -> `one`, in the order the
/// player page's repeat button cycles through on each tap.
///
/// `all` wraps [SongController.playNextSong] at the end of the queue the way
/// it always used to unconditionally; `off` is the new behaviour of stopping
/// there instead; `one` replays the track that just finished rather than
/// advancing at all. See `SongController.playNextSong` for how the three are
/// told apart.
enum RepeatMode { off, all, one }
