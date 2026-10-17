import 'package:flutter/material.dart';

import '../models/note.dart';
import '../services/export_service.dart';

Future<void> showExportSheet(BuildContext context, Note note) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              'Export "${note.displayTitle}"',
              style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.text_snippet_outlined),
            title: const Text('Plain text'),
            subtitle: const Text('.txt'),
            onTap: () => _export(sheetContext, note, ExportFormat.txt),
          ),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf_outlined),
            title: const Text('PDF document'),
            subtitle: const Text('.pdf'),
            onTap: () => _export(sheetContext, note, ExportFormat.pdf),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Word document'),
            subtitle: const Text('.doc'),
            onTap: () => _export(sheetContext, note, ExportFormat.doc),
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('Markdown'),
            subtitle: const Text('.md'),
            onTap: () => _export(sheetContext, note, ExportFormat.md),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

Future<void> _export(
  BuildContext sheetContext,
  Note note,
  ExportFormat format,
) async {
  Navigator.of(sheetContext).pop();
  final messenger = ScaffoldMessenger.maybeOf(sheetContext);
  messenger?.showSnackBar(
    const SnackBar(content: Text('Preparing export…')),
  );
  try {
    await ExportService.shareNote(note, format);
  } catch (e) {
    messenger?.showSnackBar(
      SnackBar(content: Text('Export failed: $e')),
    );
  }
}
