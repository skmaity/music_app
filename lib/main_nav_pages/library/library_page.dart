import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_app/const/theme/tokens.dart';
import 'package:music_app/controller/song_controller.dart';
import 'package:music_app/global_widgets/empty_state.dart';
import 'package:music_app/global_widgets/page_header.dart';
import 'package:music_app/global_widgets/song_tile.dart';
import 'package:music_app/model/track_ref.dart';
import 'package:music_app/services/local_media_index.dart';

enum LocalLibraryGrouping { title, artist, album }

class LocalLibraryPage extends StatefulWidget {
  const LocalLibraryPage({super.key, this.index, this.title = 'Songs'});

  final LocalMediaIndex? index;
  final String title;

  @override
  State<LocalLibraryPage> createState() => _LocalLibraryPageState();
}

class _LocalLibraryPageState extends State<LocalLibraryPage>
    with WidgetsBindingObserver {
  static const _pageSize = 100;
  late final LocalMediaIndex _index =
      widget.index ?? Get.find<LocalMediaIndex>();
  final ScrollController _scrollController = ScrollController();
  LocalMediaIndexResult? _result;
  Object? _error;
  bool _loading = true;
  String _query = '';
  LocalLibraryGrouping _grouping = LocalLibraryGrouping.title;
  int _visibleTrackCount = _pageSize;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_loadNextPageNearEnd);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _result?.permission == LocalMediaPermission.permanentlyDenied) {
      _refresh();
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
      _visibleTrackCount = _pageSize;
    });
    try {
      final result = await _index.refresh();
      if (!mounted) return;
      setState(() => _result = result);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PageHeader(widget.title),
        Expanded(child: _body()),
      ],
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ErrorState(
        headline: 'Could not scan this device',
        message: 'Nyro could not read the local media library.',
        onRetry: _refresh,
      );
    }

    final permission = _result?.permission ?? LocalMediaPermission.denied;
    if (permission != LocalMediaPermission.granted) {
      return _permissionState(permission);
    }

    final tracks = _sortedTracks(_index.search(_query));
    final visibleTracks =
        tracks.take(_visibleTrackCount).toList(growable: false);
    final entries = _entriesFor(visibleTracks);
    final songs =
        visibleTracks.map((track) => track.toSong()).toList(growable: false);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.gutter,
            Space.xs,
            Space.gutter,
            Space.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (value) => setState(() {
                    _query = value;
                    _visibleTrackCount = _pageSize;
                  }),
                  textInputAction: TextInputAction.search,
                  decoration: const InputDecoration(
                    labelText: 'Search local music',
                    hintText: 'Title, artist or album',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              ),
              const SizedBox(width: Space.sm),
              PopupMenuButton<LocalLibraryGrouping>(
                tooltip: 'Group local music',
                initialValue: _grouping,
                onSelected: (value) => setState(() {
                  _grouping = value;
                  _visibleTrackCount = _pageSize;
                }),
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: LocalLibraryGrouping.title,
                    child: Text('Title'),
                  ),
                  PopupMenuItem(
                    value: LocalLibraryGrouping.artist,
                    child: Text('Artist'),
                  ),
                  PopupMenuItem(
                    value: LocalLibraryGrouping.album,
                    child: Text('Album'),
                  ),
                ],
                icon: const Icon(Icons.sort_rounded),
              ),
            ],
          ),
        ),
        Expanded(
          child: tracks.isEmpty
              ? EmptyState(
                  headline: _query.trim().isEmpty
                      ? 'No local music found'
                      : 'No matches',
                  message: _query.trim().isEmpty
                      ? 'Add audio files to this device, then scan again.'
                      : 'Try another title or artist.',
                  actionLabel: _query.trim().isEmpty ? 'Scan again' : null,
                  onAction: _query.trim().isEmpty ? _refresh : null,
                )
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                    key: PageStorageKey(
                      'local:${widget.title}:${_grouping.name}:$_query',
                    ),
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      if (entry.header != null) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(
                            Space.gutter,
                            Space.lg,
                            Space.gutter,
                            Space.xs,
                          ),
                          child: Text(
                            entry.header!,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        );
                      }
                      final track = entry.track!;
                      final queueIndex = entry.queueIndex!;
                      final song = songs[queueIndex];
                      return SongTile(
                        key: ValueKey(track.stableKey),
                        song: song,
                        isPlaying: Get.isRegistered<SongController>() &&
                            Get.find<SongController>()
                                    .currentPlaying
                                    .value
                                    .identity ==
                                song.identity,
                        onTap: () => Get.find<SongController>()
                            .playQueue(songs, queueIndex),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _permissionState(LocalMediaPermission permission) {
    if (permission == LocalMediaPermission.unsupported) {
      return const EmptyState(
        headline: 'Local music is unavailable',
        message:
            'This device does not provide a supported local media library.',
        icon: Icons.phonelink_off_rounded,
      );
    }
    final permanentlyDenied =
        permission == LocalMediaPermission.permanentlyDenied;
    return EmptyState(
      headline: 'Media access is off',
      message: permanentlyDenied
          ? 'Enable Music and audio access in system settings to scan this device.'
          : 'Allow Music and audio access so Nyro can find songs on this device.',
      icon: Icons.library_music_outlined,
      actionLabel: permanentlyDenied ? 'Open settings' : 'Allow access',
      onAction: permanentlyDenied ? LocalMediaPlatform.openSettings : _refresh,
    );
  }

  void _loadNextPageNearEnd() {
    if (!_scrollController.hasClients ||
        _scrollController.position.extentAfter > 600) {
      return;
    }
    final total = _index.search(_query).length;
    if (_visibleTrackCount >= total) return;
    setState(() {
      final next = _visibleTrackCount + _pageSize;
      _visibleTrackCount = next < total ? next : total;
    });
  }

  String _groupFor(TrackRef track) => switch (_grouping) {
        LocalLibraryGrouping.title => '',
        LocalLibraryGrouping.artist => track.artist,
        LocalLibraryGrouping.album => _index.albumTitle(track),
      };

  List<TrackRef> _sortedTracks(List<TrackRef> tracks) {
    final sorted = List<TrackRef>.from(tracks);
    sorted.sort((a, b) {
      final groupOrder =
          _groupFor(a).toLowerCase().compareTo(_groupFor(b).toLowerCase());
      return groupOrder != 0
          ? groupOrder
          : a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
    return sorted;
  }

  List<_LocalListEntry> _entriesFor(List<TrackRef> tracks) {
    final entries = <_LocalListEntry>[];
    String? previousGroup;
    for (var i = 0; i < tracks.length; i++) {
      final group = _groupFor(tracks[i]);
      if (group.isNotEmpty && group != previousGroup) {
        entries.add(_LocalListEntry.header(group));
        previousGroup = group;
      }
      entries.add(_LocalListEntry.track(tracks[i], i));
    }
    return entries;
  }
}

class _LocalListEntry {
  const _LocalListEntry.header(this.header)
      : track = null,
        queueIndex = null;

  const _LocalListEntry.track(this.track, this.queueIndex) : header = null;

  final String? header;
  final TrackRef? track;
  final int? queueIndex;
}
