import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:notepad/models/note.dart';
import 'package:notepad/services/export_service.dart';

void main() {
  group('Note model', () {
    test('round-trips through map', () {
      final note = Note(
        title: 'Groceries',
        body: 'Milk\nEggs',
        tags: ['Home', 'Shopping'],
        pinned: true,
      );
      final restored = Note.fromMap(note.toMap());
      expect(restored.title, 'Groceries');
      expect(restored.body, 'Milk\nEggs');
      expect(restored.tags, ['Home', 'Shopping']);
      expect(restored.pinned, isTrue);
    });

    test('round-trips through json (backup format)', () {
      final note = Note(title: 'Todo', body: '- call dentist', tags: ['Health']);
      final restored = Note.fromJson(
        Map<String, dynamic>.from(
          note.toJson(),
        ),
      );
      expect(restored.title, 'Todo');
      expect(restored.tags, ['Health']);
    });

    test('counts words and previews', () {
      final note = Note(title: '', body: 'one two  three');
      expect(note.wordCount, 3);
      expect(note.displayTitle, 'Untitled note');
      expect(note.preview, 'one two  three');
    });

    test('counts characters and reading time', () {
      final note = Note(title: 'Hi', body: 'one two three');
      expect(note.charCount, 15);
      expect(note.readingMinutes, 1);
    });

    test('serializes trash timestamp in database map', () {
      final deleted = DateTime(2026, 1, 2, 3, 4);
      final note = Note(title: 'x', deletedAt: deleted);
      expect(note.inTrash, isTrue);
      final map = note.toMap();
      expect(map['deleted_at'], deleted.millisecondsSinceEpoch);
      final restored = Note.fromMap(map);
      expect(restored.deletedAt, deleted);
    });

    test('active notes have null deleted_at', () {
      final note = Note(title: 'x');
      expect(note.inTrash, isFalse);
      expect(note.toMap()['deleted_at'], isNull);
      expect(Note.fromMap(note.toMap()).deletedAt, isNull);
    });

    test('backup round-trips trash timestamp', () {
      final deleted = DateTime(2026, 5, 6, 7, 8);
      final note = Note(title: 'secret', body: 'hidden', deletedAt: deleted);
      final back = Note.fromJson(note.toJson());
      expect(back.deletedAt, deleted);
      expect(back.inTrash, isTrue);
    });
  });

  group('ExportService', () {
    test('txt export contains title and body', () {
      final note = Note(title: 'My Note', body: 'Hello world');
      final txt = ExportService.toTxt(note);
      expect(txt, contains('My Note'));
      expect(txt, contains('Hello world'));
    });

    test('doc export is word-compatible html', () {
      final note = Note(title: 'Report', body: 'Line 1\nLine 2');
      final doc = ExportService.toDoc(note);
      expect(doc, contains('<html'));
      expect(doc, contains('Report'));
      expect(doc, contains('<p>Line 1</p>'));
    });

    test('pdf export produces a document', () async {
      final note = Note(title: 'Pdf note', body: 'Content');
      final bytes = await ExportService.toPdf(note);
      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.sublist(0, 4)), '%PDF');
    });

    test('markdown export uses markdown syntax', () {
      final note = Note(title: 'Journal', body: 'Day one', tags: ['Personal']);
      final md = ExportService.toMd(note);
      expect(md, contains('# Journal'));
      expect(md, contains('#Personal'));
      expect(md, contains('Day one'));
    });

    test('noteFromText uses first line as title', () {
      final note = ExportService.noteFromText('# Meeting notes\n\nAction items');
      expect(note.title, 'Meeting notes');
      expect(note.body, 'Action items');
    });

    test('noteFromText handles plain text without heading', () {
      final note = ExportService.noteFromText('Shopping\nmilk, eggs');
      expect(note.title, 'Shopping');
      expect(note.body, 'milk, eggs');
    });

    test('backup parses exported notes', () {
      final notes = [
        Note(title: 'A', body: '1'),
        Note(title: 'B', body: '2'),
      ];
      final payload = jsonEncode({
        'app': 'notepad',
        'version': 1,
        'notes': notes.map((n) => n.toJson()).toList(),
      });
      final parsed = ExportService.parseBackup(payload);
      expect(parsed.length, 2);
      expect(parsed.first.title, 'A');
    });
  });
}
