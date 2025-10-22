import 'enums.dart';

/// Modèle représentant une note sur un contact
class ContactNote {
  final int? id;
  final int trackedContactId; // ID du contact suivi
  final String content; // Texte de la note
  final String? audioPath; // Chemin du fichier audio
  final NoteCategory category; // Catégorie de la note
  final NoteImportance importance; // Importance
  final bool isPinned; // Épinglée en haut
  final bool isActionItem; // Est-ce une action à faire ?
  final DateTime? dueDate; // Date d'échéance (pour actions)
  final bool isCompleted; // Action complétée
  final DateTime createdAt; // Date de création
  final DateTime? updatedAt; // Date de modification

  ContactNote({
    this.id,
    required this.trackedContactId,
    required this.content,
    this.audioPath,
    this.category = NoteCategory.general,
    this.importance = NoteImportance.medium,
    this.isPinned = false,
    this.isActionItem = false,
    this.dueDate,
    this.isCompleted = false,
    required this.createdAt,
    this.updatedAt,
  });

  /// Convertit l'objet en Map pour SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tracked_contact_id': trackedContactId,
      'content': content,
      'audio_path': audioPath,
      'category': category.toJson(),
      'importance': importance.toJson(),
      'is_pinned': isPinned ? 1 : 0,
      'is_action_item': isActionItem ? 1 : 0,
      'due_date': dueDate?.toIso8601String(),
      'is_completed': isCompleted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Crée un objet depuis une Map SQLite
  factory ContactNote.fromMap(Map<String, dynamic> map) {
    return ContactNote(
      id: map['id'] as int?,
      trackedContactId: map['tracked_contact_id'] as int,
      content: map['content'] as String,
      audioPath: map['audio_path'] as String?,
      category: NoteCategoryExtension.fromJson(map['category'] as String? ?? 'general'),
      importance: NoteImportanceExtension.fromJson(map['importance'] as String? ?? 'medium'),
      isPinned: (map['is_pinned'] as int? ?? 0) == 1,
      isActionItem: (map['is_action_item'] as int? ?? 0) == 1,
      dueDate: map['due_date'] != null ? DateTime.parse(map['due_date'] as String) : null,
      isCompleted: (map['is_completed'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  /// Crée une copie avec des modifications
  ContactNote copyWith({
    int? id,
    int? trackedContactId,
    String? content,
    String? audioPath,
    NoteCategory? category,
    NoteImportance? importance,
    bool? isPinned,
    bool? isActionItem,
    DateTime? dueDate,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ContactNote(
      id: id ?? this.id,
      trackedContactId: trackedContactId ?? this.trackedContactId,
      content: content ?? this.content,
      audioPath: audioPath ?? this.audioPath,
      category: category ?? this.category,
      importance: importance ?? this.importance,
      isPinned: isPinned ?? this.isPinned,
      isActionItem: isActionItem ?? this.isActionItem,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'ContactNote(id: $id, trackedContactId: $trackedContactId, '
        'content: ${content.substring(0, content.length > 20 ? 20 : content.length)}..., '
        'createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ContactNote &&
        other.id == id &&
        other.trackedContactId == trackedContactId &&
        other.content == content &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        trackedContactId.hashCode ^
        content.hashCode ^
        createdAt.hashCode;
  }
}
