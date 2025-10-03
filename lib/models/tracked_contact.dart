import 'enums.dart';

/// Modèle représentant un contact suivi dans l'application
class TrackedContact {
  final int? id;
  final String contactId; // ID du contact Android
  final String contactName;
  final String contactPhone;
  final CallFrequency frequency;
  final ContactCategory category;
  final DateTime? lastContactDate;
  final DateTime? birthday; // Date d'anniversaire (nullable)
  final DateTime createdAt;
  final DateTime updatedAt;

  TrackedContact({
    this.id,
    required this.contactId,
    required this.contactName,
    required this.contactPhone,
    required this.frequency,
    required this.category,
    this.lastContactDate,
    this.birthday,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Convertit l'objet en Map pour SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'contact_id': contactId,
      'contact_name': contactName,
      'contact_phone': contactPhone,
      'frequency': frequency.toJson(),
      'category': category.toJson(),
      'last_contact_date': lastContactDate?.toIso8601String(),
      'birthday': birthday?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Crée un objet depuis une Map SQLite
  factory TrackedContact.fromMap(Map<String, dynamic> map) {
    return TrackedContact(
      id: map['id'] as int?,
      contactId: map['contact_id'] as String,
      contactName: map['contact_name'] as String,
      contactPhone: map['contact_phone'] as String,
      frequency: CallFrequencyExtension.fromJson(map['frequency'] as String),
      category: ContactCategoryExtension.fromJson(map['category'] as String),
      lastContactDate: map['last_contact_date'] != null
          ? DateTime.parse(map['last_contact_date'] as String)
          : null,
      birthday: map['birthday'] != null
          ? DateTime.parse(map['birthday'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Crée une copie avec des modifications
  TrackedContact copyWith({
    int? id,
    String? contactId,
    String? contactName,
    String? contactPhone,
    CallFrequency? frequency,
    ContactCategory? category,
    DateTime? lastContactDate,
    DateTime? birthday,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TrackedContact(
      id: id ?? this.id,
      contactId: contactId ?? this.contactId,
      contactName: contactName ?? this.contactName,
      contactPhone: contactPhone ?? this.contactPhone,
      frequency: frequency ?? this.frequency,
      category: category ?? this.category,
      lastContactDate: lastContactDate ?? this.lastContactDate,
      birthday: birthday ?? this.birthday,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'TrackedContact(id: $id, name: $contactName, phone: $contactPhone, '
        'frequency: ${frequency.displayName}, category: ${category.displayName}, '
        'lastContact: $lastContactDate, birthday: $birthday)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TrackedContact &&
        other.id == id &&
        other.contactId == contactId &&
        other.contactName == contactName &&
        other.contactPhone == contactPhone;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        contactId.hashCode ^
        contactName.hashCode ^
        contactPhone.hashCode;
  }
}
