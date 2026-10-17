import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../models/note.dart';

enum ExportFormat { txt, pdf, doc, md }

class ExportService {
  ExportService._();

  static String _safeFileName(String title) {
    final cleaned = title
        .trim()
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '')
        .replaceAll(RegExp(r'\s+'), '_');
    return cleaned.isEmpty || cleaned == '_' ? 'note' : cleaned;
  }

  static String toTxt(Note note) {
    final buffer = StringBuffer();
    buffer.writeln(note.displayTitle);
    if (note.tags.isNotEmpty) {
      buffer.writeln('Tags: ${note.tags.join(', ')}');
    }
    buffer.writeln('Created: ${DateFormat('d MMM yyyy, h:mm a').format(note.createdAt)}');
    buffer.writeln('-' * 40);
    buffer.write(note.body);
    return buffer.toString();
  }

  static String toMd(Note note) {
    final buffer = StringBuffer();
    buffer.writeln('# ${note.displayTitle}');
    buffer.writeln();
    if (note.tags.isNotEmpty) {
      final tags = <String>[];
      for (final tag in note.tags) {
        tags.add('#${tag.replaceAll(' ', '-')}');
      }
      buffer.writeln('**Tags:** ${tags.join(' ')}');
    }
    final created =
        DateFormat('d MMM yyyy, h:mm a').format(note.createdAt);
    buffer.writeln('**Created:** $created');
    buffer.writeln();
    buffer.write(note.body);
    return buffer.toString();
  }

  static Future<Uint8List> toPdf(Note note) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(48),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              note.displayTitle,
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Text(
            [
              if (note.tags.isNotEmpty) 'Tags: ${note.tags.join(', ')}',
              'Created: ${DateFormat('d MMM yyyy, h:mm a').format(note.createdAt)}',
            ].join('   |   '),
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 12, bottom: 12),
            child: pw.Divider(),
          ),
          ...note.body.split('\n').map(
                (line) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 6),
                  child: pw.Text(
                    line.isEmpty ? ' ' : line,
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ),
              ),
        ],
      ),
    );
    return doc.save();
  }

  static String toDoc(Note note) {
    String esc(String s) => s
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');

    final paragraphs = note.body
        .split('\n')
        .map((line) => '<p>${esc(line.isEmpty ? '&nbsp;' : line)}</p>')
        .join();

    return '''
<html xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:w="urn:schemas-microsoft-com:office:word" xmlns="http://www.w3.org/TR/REC-html40">
<head>
<meta charset="utf-8">
<title>${esc(note.displayTitle)}</title>
<!--[if gte mso 9]><xml><w:WordDocument><w:View>Print</w:View></w:WordDocument></xml><![endif]-->
<style>
body { font-family: Calibri, sans-serif; font-size: 12pt; }
h1 { font-size: 20pt; }
.meta { color: #666666; font-size: 9pt; }
</style>
</head>
<body>
<h1>${esc(note.displayTitle)}</h1>
<p class="meta">${note.tags.isNotEmpty ? 'Tags: ${esc(note.tags.join(', '))}<br>' : ''}Created: ${DateFormat('d MMM yyyy, h:mm a').format(note.createdAt)}</p>
<hr>
$paragraphs
</body>
</html>
''';
  }

  static Future<void> shareNote(Note note, ExportFormat format) async {
    final dir = await getTemporaryDirectory();
    final name = _safeFileName(note.displayTitle);
    late final File file;
    late final String mimeType;

    switch (format) {
      case ExportFormat.txt:
        file = File('${dir.path}/$name.txt');
        await file.writeAsString(toTxt(note), flush: true);
        mimeType = 'text/plain';
      case ExportFormat.pdf:
        file = File('${dir.path}/$name.pdf');
        await file.writeAsBytes(await toPdf(note), flush: true);
        mimeType = 'application/pdf';
      case ExportFormat.doc:
        file = File('${dir.path}/$name.doc');
        await file.writeAsString(toDoc(note), flush: true);
        mimeType = 'application/msword';
      case ExportFormat.md:
        file = File('${dir.path}/$name.md');
        await file.writeAsString(toMd(note), flush: true);
        mimeType = 'text/markdown';
    }

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: mimeType)],
        subject: note.displayTitle,
      ),
    );
  }

  static Future<void> shareBackup(List<Note> notes) async {
    final dir = await getTemporaryDirectory();
    final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final file = File('${dir.path}/notepad_backup_$stamp.json');
    final payload = jsonEncode({
      'app': 'notepad',
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'notes': notes.map((n) => n.toJson()).toList(),
    });
    await file.writeAsString(payload, flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/json')],
        subject: 'Notepad backup',
      ),
    );
  }

  static Note noteFromText(String content) {
    final lines = content.replaceAll('\r\n', '\n').split('\n');
    var title = '';
    var bodyStart = 0;
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      title = line.replaceFirst(RegExp(r'^#{1,6}\s+'), '');
      bodyStart = i + 1;
      break;
    }
    final body = lines.skip(bodyStart).join('\n');
    return Note(title: title, body: body.trim());
  }

  static List<Note> parseBackup(String content) {
    final decoded = jsonDecode(content);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Not a Notepad backup file');
    }
    final list = decoded['notes'];
    if (list is! List) {
      throw const FormatException('Backup contains no notes');
    }
    return list
        .whereType<Map<String, dynamic>>()
        .map(Note.fromJson)
        .toList();
  }
}
