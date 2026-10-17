import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/note.dart';
import '../providers/notes_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/note_card.dart';
import 'editor_screen.dart';
import 'settings_screen.dart';
import 'trash_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _searchOpen = false;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openEditor(Note note) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EditorScreen(note: note)),
    );
  }

  Future<void> _deleteNote(Note note) async {
    final messenger = ScaffoldMessenger.of(context);
    final notes = context.read<NotesProvider>();
    await notes.remove(note);
    messenger.showSnackBar(
      SnackBar(
        content: Text('"${note.displayTitle}" moved to trash'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => notes.restore(note),
        ),
      ),
    );
  }

  void _toggleSearch() {
    setState(() {
      _searchOpen = !_searchOpen;
      if (!_searchOpen) {
        _searchController.clear();
        context.read<NotesProvider>().setQuery('');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final notes = context.watch<NotesProvider>();
    final viewGrid = context.watch<SettingsProvider>().viewGrid;
    final filtered = notes.filtered;
    final tags = notes.allTags;

    return Scaffold(
      appBar: AppBar(
        title: _searchOpen
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search notes…',
                  isDense: true,
                ),
                onChanged: (value) =>
                    context.read<NotesProvider>().setQuery(value),
              )
            : const Text('Notepad'),
        actions: [
          IconButton(
            tooltip: _searchOpen ? 'Close search' : 'Search',
            icon: Icon(_searchOpen ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
          ),
          PopupMenuButton<SortMode>(
            tooltip: 'Sort',
            icon: const Icon(Icons.sort),
            onSelected: (mode) => context.read<NotesProvider>().setSortMode(mode),
            itemBuilder: (context) => const [
              PopupMenuItem(value: SortMode.updated, child: Text('Last updated')),
              PopupMenuItem(value: SortMode.created, child: Text('Date created')),
              PopupMenuItem(value: SortMode.title, child: Text('Title A–Z')),
            ],
          ),
          IconButton(
            tooltip: viewGrid ? 'List view' : 'Grid view',
            icon: Icon(viewGrid ? Icons.view_list : Icons.grid_view),
            onPressed: () {
              final settings = context.read<SettingsProvider>();
              settings.setViewGrid(!settings.viewGrid);
            },
          ),
          IconButton(
            tooltip: 'Trash',
            icon: const Icon(Icons.restore_from_trash_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TrashScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (tags.isNotEmpty || notes.activeTag != null)
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: const Text('All'),
                      selected: notes.activeTag == null,
                      showCheckmark: false,
                      onSelected: (_) =>
                          context.read<NotesProvider>().setActiveTag(null),
                    ),
                  ),
                  for (final tag in tags)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: TagChip(
                        tag: tag,
                        selected: notes.activeTag == tag,
                        onSelected: (_) => context
                            .read<NotesProvider>()
                            .setActiveTag(notes.activeTag == tag ? null : tag),
                      ),
                    ),
                ],
              ),
            ),
          Expanded(
            child: notes.loading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? _EmptyState(
                        searching: notes.query.isNotEmpty ||
                            notes.activeTag != null,
                        onNew: () => _openEditor(Note()),
                      )
                    : viewGrid
                        ? GridView.builder(
                            padding:
                                const EdgeInsets.fromLTRB(16, 8, 16, 96),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              mainAxisExtent: 176,
                            ),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final note = filtered[index];
                              return NoteGridCard(
                                note: note,
                                onTap: () => _openEditor(note),
                                onPin: () => context
                                    .read<NotesProvider>()
                                    .togglePin(note),
                                onDelete: () => _deleteNote(note),
                              );
                            },
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                            itemCount: filtered.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final note = filtered[index];
                              return NoteCard(
                                note: note,
                                onTap: () => _openEditor(note),
                                onPin: () =>
                                    context.read<NotesProvider>().togglePin(note),
                                onDelete: () => _deleteNote(note),
                              );
                            },
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(Note()),
        icon: const Icon(Icons.add),
        label: const Text('New note'),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.searching, required this.onNew});

  final bool searching;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              searching ? Icons.search_off : Icons.edit_note,
              size: 72,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              searching ? 'No matching notes' : 'No notes yet',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              searching
                  ? 'Try a different search or tag.'
                  : 'Tap "New note" to write your first note.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            if (!searching) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onNew,
                icon: const Icon(Icons.add),
                label: const Text('New note'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
