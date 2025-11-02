import 'enums.dart';

/// Modèle représentant un événement important
class Event {
  final int? id;
  final String title;
  final String? description;
  final DateTime startDate;
  final DateTime? endDate;
  final EventCategory category;
  final EventStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Event({
    this.id,
    required this.title,
    this.description,
    required this.startDate,
    this.endDate,
    required this.category,
    this.status = EventStatus.active,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Convertit l'événement en Map pour la base de données
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'category': category.toJson(),
      'status': status.toJson(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Crée un événement depuis une Map de la base de données
  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      startDate: DateTime.parse(map['start_date']),
      endDate: map['end_date'] != null ? DateTime.parse(map['end_date']) : null,
      category: EventCategoryExtension.fromJson(map['category']),
      status: EventStatusExtension.fromJson(map['status']),
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  /// Crée une copie de l'événement avec des modifications
  Event copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    EventCategory? category,
    EventStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      category: category ?? this.category,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Vérifie si l'événement est à venir
  bool get isUpcoming {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventStart = DateTime(startDate.year, startDate.month, startDate.day);
    return eventStart.isAfter(today) || eventStart.isAtSameMomentAs(today);
  }

  /// Vérifie si l'événement est passé
  bool get isPast {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventEnd = endDate != null
        ? DateTime(endDate!.year, endDate!.month, endDate!.day)
        : DateTime(startDate.year, startDate.month, startDate.day);
    return eventEnd.isBefore(today);
  }

  /// Vérifie si l'événement est en cours
  bool get isOngoing {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventStart = DateTime(startDate.year, startDate.month, startDate.day);
    final eventEnd = endDate != null
        ? DateTime(endDate!.year, endDate!.month, endDate!.day)
        : eventStart;
    return (eventStart.isBefore(today) || eventStart.isAtSameMomentAs(today)) &&
           (eventEnd.isAfter(today) || eventEnd.isAtSameMomentAs(today));
  }

  /// Retourne le nombre de jours jusqu'à l'événement
  int? get daysUntil {
    if (!isUpcoming) return null;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventStart = DateTime(startDate.year, startDate.month, startDate.day);

    return eventStart.difference(today).inDays;
  }

  /// Retourne la durée de l'événement en jours
  int get duration {
    if (endDate == null) return 1;
    return endDate!.difference(startDate).inDays + 1;
  }

  @override
  String toString() {
    return 'Event{id: $id, title: $title, startDate: $startDate, endDate: $endDate, category: $category, status: $status}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Event && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}