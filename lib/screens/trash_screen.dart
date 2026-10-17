import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/note.dart';
import '../providers/notes_provider.dart';

class TrashScreen extends StatelessWidget {
  const TrashScreen({super.key});

  Future<void> _restore(BuildContext context, Note note) async {
    final notes = context.read<NotesProvider>();
    final messenger = ScaffoldMessenger.of(context);
    await notes.restore(note);
    messenger.showSnackBar(
      SnackBar(content: Text('"${note.displayTitle}" restored')),
    );
  }

  Future<void> _deleteForever(BuildContext context, Note note) async {
    final notes = context.read<NotesProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete forever?'),
        content: Text(
          '"${note.displayTitle}" will be permanently deleted. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete forever'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await notes.deleteForever(note);
    }
  }

  Future<void> _emptyTrash(BuildContext context) async {
    final notes = context.read<NotesProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Empty trash?'),
        content: Text(
          '${notes.trashCount} note(s) will be permanently deleted. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Empty trash'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await notes.emptyTrash();
      messenger.showSnackBar(
        const SnackBar(content: Text('Trash emptied')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final notes = context.watch<NotesProvider>();
    final theme = Theme.of(context);
    final trash = notes.trashed;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trash'),
        actions: [
          if (trash.isNotEmpty)
            TextButton(
              onPressed: () => _emptyTrash(context),
              child: const Text('Empty'),
            ),
        ],
      ),
      body: trash.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.restore_from_trash,
                      size: 72,
                      color: theme.colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text('Trash is empty',
                        style: theme.textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(
                      'Deleted notes stay here for '
                      '${NotesProvider.trashRetentionDays} days,\n'
                      'then are removed automatically.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: trash.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final note = trash[index];
                final deletedAt = note.deletedAt!;
                final autoDelete = deletedAt.add(
                  const Duration(days: NotesProvider.trashRetentionDays),
                );
                return Card(
                  child: ListTile(
                    title: Text(
                      note.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Deleted ${DateFormat('d MMM yyyy').format(deletedAt)}'
                      ' · auto-deletes ${DateFormat('d MMM').format(autoDelete)}',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: theme.colorScheme.outline),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Restore',
                          icon: const Icon(Icons.undo),
                          onPressed: () => _restore(context, note),
                        ),
                        IconButton(
                          tooltip: 'Delete forever',
                          icon: const Icon(Icons.delete_forever_outlined),
                          onPressed: () => _deleteForever(context, note),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
