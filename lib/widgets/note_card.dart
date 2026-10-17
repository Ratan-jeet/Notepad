import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/note.dart';
import '../theme/app_theme.dart';

class TagChip extends StatelessWidget {
  const TagChip({
    super.key,
    required this.tag,
    this.selected = false,
    this.onSelected,
    this.onDeleted,
  });

  final String tag;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.tagColor(tag);
    return FilterChip(
      label: Text(tag),
      selected: selected,
      onSelected: onSelected,
      onDeleted: onDeleted,
      showCheckmark: false,
      selectedColor: color.withValues(alpha: 0.20),
      backgroundColor: color.withValues(alpha: 0.10),
      labelStyle: TextStyle(
        color: selected ? color : color.withValues(alpha: 0.9),
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        fontSize: 13,
      ),
      side: BorderSide(color: color.withValues(alpha: 0.45)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      visualDensity: VisualDensity.compact,
    );
  }
}

class NoteGridCard extends StatelessWidget {
  const NoteGridCard({
    super.key,
    required this.note,
    required this.onTap,
    required this.onPin,
    required this.onDelete,
  });

  final Note note;
  final VoidCallback onTap;
  final VoidCallback onPin;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = note.tags.isNotEmpty
        ? AppTheme.tagColor(note.tags.first)
        : theme.colorScheme.primary;
    final date = DateFormat('d MMM yyyy').format(note.updatedAt);

    return Dismissible(
      key: ValueKey('grid-note-${note.id ?? note.hashCode}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete_outline,
            color: theme.colorScheme.onErrorContainer),
      ),
      onDismissed: (_) => onDelete(),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onPin,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        note.displayTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (note.pinned)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Icon(
                          Icons.push_pin,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Text(
                    note.preview,
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ),
                Text(
                  date,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.outline),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NoteCard extends StatelessWidget {
  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    required this.onPin,
    required this.onDelete,
  });

  final Note note;
  final VoidCallback onTap;
  final VoidCallback onPin;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = note.tags.isNotEmpty
        ? AppTheme.tagColor(note.tags.first)
        : theme.colorScheme.primary;
    final date = DateFormat('d MMM yyyy • h:mm a').format(note.updatedAt);

    return Dismissible(
      key: ValueKey('note-${note.id ?? note.hashCode}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete_outline, color: theme.colorScheme.onErrorContainer),
      ),
      onDismissed: (_) => onDelete(),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          onLongPress: onPin,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  height: 74,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              note.displayTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          if (note.pinned)
                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: Icon(
                                Icons.push_pin,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                        ],
                      ),
                      if (note.preview.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          note.preview,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            date,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                          const Spacer(),
                          PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            iconSize: 20,
                            splashRadius: 18,
                            onSelected: (value) {
                              if (value == 'pin') onPin();
                              if (value == 'delete') onDelete();
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'pin',
                                child: Text(
                                  note.pinned ? 'Unpin' : 'Pin to top',
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Move to trash'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (note.tags.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              for (final tag in note.tags.take(3))
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.tagColor(tag)
                                        .withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    tag,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: AppTheme.tagColor(tag),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
