/// Modèle représentant la relation many-to-many entre Event et TrackedContact
class EventContact {
  final int? id;
  final int eventId;
  final int trackedContactId;
  final DateTime createdAt;

  EventContact({
    this.id,
    required this.eventId,
    required this.trackedContactId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Convertit la relation en Map pour la base de données
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'event_id': eventId,
      'tracked_contact_id': trackedContactId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Crée une relation depuis une Map de la base de données
  factory EventContact.fromMap(Map<String, dynamic> map) {
    return EventContact(
      id: map['id'],
      eventId: map['event_id'],
      trackedContactId: map['tracked_contact_id'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  @override
  String toString() {
    return 'EventContact{id: $id, eventId: $eventId, trackedContactId: $trackedContactId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventContact &&
           other.eventId == eventId &&
           other.trackedContactId == trackedContactId;
  }

  @override
  int get hashCode => Object.hash(eventId, trackedContactId);
}