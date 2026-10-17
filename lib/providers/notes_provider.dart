import 'package:flutter/foundation.dart';

import '../models/note.dart';
import '../services/database_service.dart';

enum SortMode { updated, created, title }

class NotesProvider extends ChangeNotifier {
  static const int trashRetentionDays = 30;

  List<Note> notes = [];
  String query = '';
  String? activeTag;
  SortMode sortMode = SortMode.updated;
  bool loading = true;

  List<Note> get active =>
      notes.where((n) => n.deletedAt == null).toList();

  List<Note> get trashed {
    final list = notes.where((n) => n.deletedAt != null).toList()
      ..sort((a, b) => b.deletedAt!.compareTo(a.deletedAt!));
    return list;
  }

  int get trashCount => trashed.length;

  Future<void> load() async {
    loading = true;
    notifyListeners();
    final cutoff = DateTime.now()
        .subtract(const Duration(days: trashRetentionDays))
        .millisecondsSinceEpoch;
    await DatabaseService.instance.deleteExpired(cutoffMillis: cutoff);
    notes = await DatabaseService.instance.allNotes();
    loading = false;
    notifyListeners();
  }

  Set<String> get allTags {
    final tags = <String>{};
    for (final note in active) {
      tags.addAll(note.tags);
    }
    final sorted = tags.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return sorted.toSet();
  }

  List<Note> get filtered {
    final q = query.trim().toLowerCase();
    var list = notes.where((note) {
      if (note.deletedAt != null) return false;
      final matchesQuery = q.isEmpty ||
          note.title.toLowerCase().contains(q) ||
          note.body.toLowerCase().contains(q) ||
          note.tags.any((t) => t.toLowerCase().contains(q));
      final matchesTag = activeTag == null || note.tags.contains(activeTag);
      return matchesQuery && matchesTag;
    }).toList();

    int compare(Note a, Note b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      switch (sortMode) {
        case SortMode.created:
          return b.createdAt.compareTo(a.createdAt);
        case SortMode.title:
          return a.displayTitle.toLowerCase().compareTo(b.displayTitle.toLowerCase());
        case SortMode.updated:
          return b.updatedAt.compareTo(a.updatedAt);
      }
    }

    list.sort(compare);
    return list;
  }

  Future<Note> add(Note note) async {
    final saved = await DatabaseService.instance.insert(note);
    notes.insert(0, saved);
    notifyListeners();
    return saved;
  }

  Future<void> save(Note note) async {
    note.updatedAt = DateTime.now();
    if (note.id == null) {
      await add(note);
    } else {
      await DatabaseService.instance.update(note);
      final index = notes.indexWhere((n) => n.id == note.id);
      if (index != -1) notes[index] = note;
      notifyListeners();
    }
  }

  Future<void> togglePin(Note note) async {
    note.pinned = !note.pinned;
    await DatabaseService.instance.update(note);
    notifyListeners();
  }

  Future<void> remove(Note note) async {
    if (note.id == null) return;
    note.deletedAt = DateTime.now();
    await DatabaseService.instance.update(note);
    notifyListeners();
  }

  Future<void> restore(Note note) async {
    note.deletedAt = null;
    if (note.id == null) return;
    await DatabaseService.instance.update(note);
    notifyListeners();
  }

  Future<void> deleteForever(Note note) async {
    if (note.id == null) {
      notes.remove(note);
      notifyListeners();
      return;
    }
    await DatabaseService.instance.delete(note.id!);
    notes.removeWhere((n) => n.id == note.id);
    notifyListeners();
  }

  Future<void> emptyTrash() async {
    for (final note in trashed) {
      if (note.id != null) {
        await DatabaseService.instance.delete(note.id!);
      }
    }
    notes.removeWhere((n) => n.deletedAt != null);
    notifyListeners();
  }

  Future<void> replaceAll(List<Note> imported) async {
    await DatabaseService.instance.deleteAll();
    notes = [];
    notifyListeners();
    await DatabaseService.instance.insertAll(imported);
    await load();
  }

  void setQuery(String value) {
    query = value;
    notifyListeners();
  }

  void setActiveTag(String? tag) {
    activeTag = tag;
    notifyListeners();
  }

  void setSortMode(SortMode mode) {
    sortMode = mode;
    notifyListeners();
  }
}
