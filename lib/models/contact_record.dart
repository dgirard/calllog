import 'enums.dart';

/// Modèle représentant un enregistrement de contact (appel ou SMS)
class ContactRecord {
  final int? id;
  final int trackedContactId; // ID du contact suivi
  final DateTime contactDate;
  final ContactMethod contactMethod; // Appel ou SMS
  final String contactType; // manual ou automatic
  final ContactContext context; // normal ou birthday

  ContactRecord({
    this.id,
    required this.trackedContactId,
    required this.contactDate,
    required this.contactMethod,
    this.contactType = 'manual',
    this.context = ContactContext.normal,
  });

  /// Convertit l'objet en Map pour SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tracked_contact_id': trackedContactId,
      'contact_date': contactDate.toIso8601String(),
      'contact_method': contactMethod.toJson(),
      'contact_type': contactType,
      'context': context.toJson(),
    };
  }

  /// Crée un objet depuis une Map SQLite
  factory ContactRecord.fromMap(Map<String, dynamic> map) {
    return ContactRecord(
      id: map['id'] as int?,
      trackedContactId: map['tracked_contact_id'] as int,
      contactDate: DateTime.parse(map['contact_date'] as String),
      contactMethod: ContactMethodExtension.fromJson(map['contact_method'] as String),
      contactType: map['contact_type'] as String,
      context: ContactContextExtension.fromJson(map['context'] as String),
    );
  }

  /// Crée une copie avec des modifications
  ContactRecord copyWith({
    int? id,
    int? trackedContactId,
    DateTime? contactDate,
    ContactMethod? contactMethod,
    String? contactType,
    ContactContext? context,
  }) {
    return ContactRecord(
      id: id ?? this.id,
      trackedContactId: trackedContactId ?? this.trackedContactId,
      contactDate: contactDate ?? this.contactDate,
      contactMethod: contactMethod ?? this.contactMethod,
      contactType: contactType ?? this.contactType,
      context: context ?? this.context,
    );
  }

  @override
  String toString() {
    return 'ContactRecord(id: $id, trackedContactId: $trackedContactId, '
        'date: $contactDate, method: ${contactMethod.displayName}, '
        'type: $contactType, context: ${context.displayName})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ContactRecord &&
        other.id == id &&
        other.trackedContactId == trackedContactId &&
        other.contactDate == contactDate;
  }

  @override
  int get hashCode {
    return id.hashCode ^ trackedContactId.hashCode ^ contactDate.hashCode;
  }
}
