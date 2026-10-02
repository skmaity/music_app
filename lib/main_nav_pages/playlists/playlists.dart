import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_app/const/theme/tokens.dart';
import 'package:music_app/model/track_ref.dart';
import 'package:music_app/repositories/library_repository.dart';

class Playlists extends StatefulWidget {
  const Playlists({super.key, this.repository});

  final LibraryRepository? repository;

  @override
  State<Playlists> createState() => _PlaylistsState();
}

class _PlaylistsState extends State<Playlists> {
  late final LibraryRepository _repository =
      widget.repository ?? Get.find<LibraryRepository>();
  List<LibraryPlaylist> _playlists = const [];
  List<LibraryPlaylistEntry> _entries = const [];
  LibraryPlaylist? _selected;
  TrackSource? _sourceFilter;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final playlists = await _repository.listPlaylists();
      if (!mounted) return;
      setState(() {
        _playlists = playlists;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Your playlists could not be loaded.';
      });
    }
  }

  Future<void> _openPlaylist(LibraryPlaylist playlist) async {
    setState(() {
      _selected = playlist;
      _loading = true;
      _error = null;
    });
    try {
      final entries = await _repository.listPlaylistEntries(playlist.id);
      if (!mounted || _selected?.id != playlist.id) return;
      setState(() {
        _entries = entries;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || _selected?.id != playlist.id) return;
      setState(() {
        _loading = false;
        _error = 'This playlist could not be loaded.';
      });
    }
  }

  Future<String?> _askForName(String title, {String initial = ''}) async {
    final controller = TextEditingController(text: initial);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 80,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(labelText: 'Playlist name'),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  Future<void> _createPlaylist() async {
    final name = await _askForName('New playlist');
    if (name == null) return;
    final id = 'playlist-${DateTime.now().microsecondsSinceEpoch}';
    await _repository.createPlaylist(id: id, name: name);
    await _loadPlaylists();
  }

  Future<void> _renameSelected() async {
    final selected = _selected;
    if (selected == null) return;
    final name = await _askForName('Rename playlist', initial: selected.name);
    if (name == null) return;
    await _repository.renamePlaylist(selected.id, name);
    final renamed = LibraryPlaylist(
      id: selected.id,
      name: name,
      createdAt: selected.createdAt,
      updatedAt: DateTime.now(),
      entryCount: selected.entryCount,
    );
    if (!mounted) return;
    setState(() => _selected = renamed);
  }

  Future<void> _deleteSelected() async {
    final selected = _selected;
    if (selected == null) return;
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete playlist?'),
            content: Text(
                '“${selected.name}” will be removed. Songs stay in your library.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    await _repository.deletePlaylist(selected.id);
    if (!mounted) return;
    setState(() {
      _selected = null;
      _entries = const [];
    });
    await _loadPlaylists();
  }

  Future<void> _removeEntry(LibraryPlaylistEntry entry) async {
    await _repository.removePlaylistEntry(entry.id);
    final selected = _selected;
    if (selected != null) await _openPlaylist(selected);
  }

  Future<void> _reorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final reordered = List<LibraryPlaylistEntry>.from(_entries);
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);
    setState(() => _entries = reordered);
    try {
      await _repository.reorderPlaylistEntries(
        _selected!.id,
        reordered.map((entry) => entry.id).toList(growable: false),
      );
      final selected = _selected;
      if (selected != null) await _openPlaylist(selected);
    } catch (_) {
      final selected = _selected;
      if (selected != null) await _openPlaylist(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.lg, Space.md, Space.lg, 0),
        child: _selected == null
            ? _buildOverview(context)
            : _buildDetails(context),
      ),
    );
  }

  Widget _buildOverview(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Library',
                  style: Theme.of(context).textTheme.headlineMedium),
            ),
            IconButton.filledTonal(
              tooltip: 'New playlist',
              onPressed: _createPlaylist,
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),
        const SizedBox(height: Space.lg),
        Expanded(child: _buildOverviewBody(context)),
      ],
    );
  }

  Widget _buildOverviewBody(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return _ErrorState(message: _error!, retry: _loadPlaylists);
    }
    if (_playlists.isEmpty) {
      return const _LibraryMessage(
        icon: Icons.queue_music_rounded,
        title: 'No playlists yet',
        message: 'Create one, then add songs from any Nyro source.',
      );
    }
    return ListView.separated(
      itemCount: _playlists.length,
      separatorBuilder: (_, __) => const SizedBox(height: Space.sm),
      itemBuilder: (context, index) {
        final playlist = _playlists[index];
        final count = playlist.entryCount;
        return Card(
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            minTileHeight: 64,
            leading: const Icon(Icons.queue_music_rounded),
            title: Text(playlist.name),
            subtitle: Text('$count ${count == 1 ? 'song' : 'songs'}'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _openPlaylist(playlist),
          ),
        );
      },
    );
  }

  Widget _buildDetails(BuildContext context) {
    final selected = _selected!;
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Back to playlists',
              onPressed: () => setState(() {
                _selected = null;
                _entries = const [];
                _error = null;
              }),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            Expanded(
              child: Text(
                selected.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Playlist options',
              onSelected: (value) {
                if (value == 'rename') _renameSelected();
                if (value == 'delete') _deleteSelected();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'rename', child: Text('Rename')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
        const SizedBox(height: Space.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              FilterChip(
                label: const Text('All sources'),
                selected: _sourceFilter == null,
                onSelected: (_) => setState(() => _sourceFilter = null),
              ),
              for (final source in TrackSource.values
                  .where((source) => source != TrackSource.local)) ...[
                const SizedBox(width: Space.sm),
                FilterChip(
                  label: Text(source.label),
                  selected: _sourceFilter == source,
                  onSelected: (_) => setState(() => _sourceFilter = source),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: Space.sm),
        Expanded(child: _buildDetailsBody(context)),
      ],
    );
  }

  Widget _buildDetailsBody(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return _ErrorState(
        message: _error!,
        retry: () => _openPlaylist(_selected!),
      );
    }
    if (_entries.isEmpty) {
      return const _LibraryMessage(
        icon: Icons.music_note_rounded,
        title: 'This playlist is empty',
        message: 'Use a Nyro Server or YouTube song’s menu to add tracks.',
      );
    }
    final visibleEntries = _sourceFilter == null
        ? _entries
        : _entries
            .where((entry) => entry.track.source == _sourceFilter)
            .toList(growable: false);
    if (visibleEntries.isEmpty) {
      return const _LibraryMessage(
        icon: Icons.filter_alt_off_rounded,
        title: 'No songs from this source',
        message: 'Choose All sources to see the complete playlist.',
      );
    }
    if (_sourceFilter != null) {
      return ListView.builder(
        itemCount: visibleEntries.length,
        itemBuilder: (context, index) =>
            _entryCard(visibleEntries[index], index, draggable: false),
      );
    }
    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      itemCount: _entries.length,
      onReorder: _reorder,
      itemBuilder: (context, index) =>
          _entryCard(_entries[index], index, draggable: true),
    );
  }

  Widget _entryCard(
    LibraryPlaylistEntry entry,
    int index, {
    required bool draggable,
  }) {
    return Card(
      key: ValueKey(entry.id),
      margin: const EdgeInsets.only(bottom: Space.sm),
      child: ListTile(
        minTileHeight: 68,
        contentPadding: const EdgeInsets.only(left: Space.md, right: Space.xs),
        title: Text(entry.track.title,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Row(
          children: [
            Flexible(
              child: Text(
                entry.track.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: Space.sm),
            _SourceBadge(label: entry.track.source.label),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Remove ${entry.track.title}',
              onPressed: () => _removeEntry(entry),
              icon: const Icon(Icons.remove_circle_outline_rounded),
            ),
            if (draggable)
              ReorderableDragStartListener(
                index: index,
                child: const Padding(
                  padding: EdgeInsets.all(Space.sm),
                  child: Icon(Icons.drag_handle_rounded),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SourceBadge extends StatelessWidget {
  const _SourceBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Space.sm, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.glassEdge),
        borderRadius: BorderRadius.circular(Radii.full),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

class _LibraryMessage extends StatelessWidget {
  const _LibraryMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40),
            const SizedBox(height: Space.md),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: Space.sm),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.retry});

  final String message;
  final VoidCallback retry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: Space.md),
          OutlinedButton(onPressed: retry, child: const Text('Try again')),
        ],
      ),
    );
  }
}
