import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/note.dart';

class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  static const String _dbName = 'notepad.db';

  Database? _db;

  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    final path = p.join(await getDatabasesPath(), _dbName);
    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE notes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            body TEXT NOT NULL,
            tags TEXT NOT NULL DEFAULT '',
            pinned INTEGER NOT NULL DEFAULT 0,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            deleted_at INTEGER
          )
        ''');
        await db.execute(
            'CREATE INDEX idx_notes_updated_at ON notes(updated_at)');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE notes ADD COLUMN deleted_at INTEGER');
        }
      },
    );
  }

  Future<List<Note>> allNotes() async {
    final db = await database;
    final rows = await db.query('notes', orderBy: 'updated_at DESC');
    return rows.map(Note.fromMap).toList();
  }

  Future<Note> insert(Note note) async {
    final db = await database;
    final id = await db.insert('notes', note.toMap());
    note.id = id;
    return note;
  }

  Future<void> update(Note note) async {
    final db = await database;
    await db
        .update('notes', note.toMap(), where: 'id = ?', whereArgs: [note.id]);
  }

  Future<void> delete(int id) async {
    final db = await database;
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteExpired({required int cutoffMillis}) async {
    final db = await database;
    await db.delete(
      'notes',
      where: 'deleted_at IS NOT NULL AND deleted_at < ?',
      whereArgs: [cutoffMillis],
    );
  }

  Future<void> deleteAll() async {
    final db = await database;
    await db.delete('notes');
  }

  Future<void> insertAll(List<Note> notes) async {
    final db = await database;
    final batch = db.batch();
    for (final note in notes) {
      batch.insert('notes', note.toMap());
    }
    await batch.commit(noResult: true);
  }
}
