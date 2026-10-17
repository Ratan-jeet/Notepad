class Note {
  Note({
    this.id,
    this.title = '',
    this.body = '',
    List<String>? tags,
    this.pinned = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.deletedAt,
  })  : tags = tags ?? <String>[],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  int? id;
  String title;
  String body;
  List<String> tags;
  bool pinned;
  final DateTime createdAt;
  DateTime updatedAt;
  DateTime? deletedAt;

  bool get inTrash => deletedAt != null;

  String get displayTitle =>
      title.trim().isEmpty ? 'Untitled note' : title.trim();

  String get preview {
    final text = body.trim();
    if (text.isEmpty) return title.trim().isEmpty ? 'Empty note' : '';
    return text;
  }

  int get wordCount {
    var count = 0;
    for (final part in body.split(RegExp(r'\s+'))) {
      if (part.trim().isNotEmpty) count++;
    }
    return count;
  }

  int get charCount => title.length + body.length;

  int get readingMinutes => (wordCount / 200).ceil();

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'title': title,
        'body': body,
        'tags': tags.join('|'),
        'pinned': pinned ? 1 : 0,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
        'deleted_at': deletedAt?.millisecondsSinceEpoch,
      };

  factory Note.fromMap(Map<String, dynamic> map) => Note(
        id: map['id'] as int?,
        title: map['title'] as String? ?? '',
        body: map['body'] as String? ?? '',
        tags: (map['tags'] as String? ?? '')
            .split('|')
            .where((t) => t.trim().isNotEmpty)
            .map((t) => t.trim())
            .toList(),
        pinned: (map['pinned'] as int? ?? 0) == 1,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
            (map['created_at'] as int?) ?? 0),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(
            (map['updated_at'] as int?) ?? 0),
        deletedAt: map['deleted_at'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(map['deleted_at'] as int),
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'body': body,
        'tags': tags,
        'pinned': pinned,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory Note.fromJson(Map<String, dynamic> json) => Note(
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
        pinned: json['pinned'] as bool? ?? false,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
            DateTime.now(),
        deletedAt: DateTime.tryParse(json['deletedAt'] as String? ?? ''),
      );
}
