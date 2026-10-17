import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/note.dart';
import '../providers/notes_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/export_sheet.dart';
import '../widgets/note_card.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key, required this.note});

  final Note note;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  Timer? _debounce;
  late bool _isNew;
  bool _dirty = false;
  String _status = 'Saved';

  Note get note => widget.note;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: note.title);
    _bodyController = TextEditingController(text: note.body);
    _isNew = note.id == null;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _onChanged() {
    _dirty = true;
    setState(() => _status = 'Saving…');
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), _flush);
  }

  Future<void> _flush() async {
    if (!_dirty) return;
    note.title = _titleController.text;
    note.body = _bodyController.text;
    if (_isNew && note.title.trim().isEmpty && note.body.trim().isEmpty) {
      return;
    }
    await context.read<NotesProvider>().save(note);
    _isNew = false;
    _dirty = false;
    if (mounted) setState(() => _status = 'Saved');
  }

  Future<void> _delete() async {
    if (_isNew) {
      Navigator.of(context).pop();
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Move to trash?'),
        content: Text(
          '"${note.displayTitle}" will be kept in Trash for '
          '${NotesProvider.trashRetentionDays} days, then deleted '
          'permanently.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Move to trash'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<NotesProvider>().remove(note);
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _editTags() async {
    final controller = TextEditingController();
    final newTag = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add tag'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 24,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'e.g. Work, Ideas'),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (newTag != null && newTag.trim().isNotEmpty && mounted) {
      final tag = newTag.trim();
      if (!note.tags.contains(tag)) {
        setState(() => note.tags.add(tag));
        _onChanged();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final editorFontSize =
        context.watch<SettingsProvider>().editorFontSize;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        _debounce?.cancel();
        await _flush();
        if (context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          actions: [
            IconButton(
              tooltip: note.pinned ? 'Unpin' : 'Pin',
              icon: Icon(
                note.pinned ? Icons.push_pin : Icons.push_pin_outlined,
                color: note.pinned ? theme.colorScheme.primary : null,
              ),
              onPressed: () async {
                if (_isNew) return;
                await context.read<NotesProvider>().togglePin(note);
                setState(() {});
              },
            ),
            IconButton(
              tooltip: 'Export',
              icon: const Icon(Icons.ios_share),
              onPressed: () async {
                _debounce?.cancel();
                await _flush();
                if (context.mounted) showExportSheet(context, note);
              },
            ),
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  children: [
                    TextField(
                      controller: _titleController,
                      onChanged: (_) => _onChanged(),
                      textCapitalization: TextCapitalization.sentences,
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                      decoration: const InputDecoration(
                        hintText: 'Title',
                        filled: false,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                    if (note.tags.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            for (final tag in note.tags.toList())
                              TagChip(
                                tag: tag,
                                selected: true,
                                onDeleted: () {
                                  setState(() => note.tags.remove(tag));
                                  _onChanged();
                                },
                              ),
                          ],
                        ),
                      ),
                    TextField(
                      controller: _bodyController,
                      onChanged: (_) => _onChanged(),
                      textCapitalization: TextCapitalization.sentences,
                      minLines: 12,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        height: 1.5,
                        fontSize: editorFontSize,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Start writing…',
                        filled: false,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  border: Border(top: BorderSide(color: theme.dividerColor)),
                ),
                child: Row(
                  children: [
                    Text(
                      '${note.wordCount} words · ${note.charCount} chars'
                      '${note.readingMinutes > 0 ? ' · ${note.readingMinutes} min read' : ''}',
                      style: theme.textTheme.labelMedium
                          ?.copyWith(color: theme.colorScheme.outline),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _status,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: _status == 'Saved'
                            ? theme.colorScheme.outline
                            : theme.colorScheme.primary,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _editTags,
                      icon: const Icon(Icons.label_outline, size: 18),
                      label: const Text('Tags'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
