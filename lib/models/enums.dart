/// Fréquence d'appel pour un contact
enum CallFrequency {
  weekly,     // Toutes les semaines
  biweekly,   // Toutes les 2 semaines
  monthly,    // Tous les mois
  quarterly,  // Tous les 3 mois
  yearly,     // Tous les ans
}

/// Catégorie d'un contact
enum ContactCategory {
  family,       // Famille
  friends,      // Amis
  professional, // Professionnel
}

/// Niveau de priorité d'un contact
enum Priority {
  high,     // Priorité haute (en retard)
  medium,   // Priorité moyenne (à appeler bientôt)
  low,      // Priorité basse (à jour)
  birthday, // Priorité anniversaire (maximale)
}

/// Méthode de contact utilisée
enum ContactMethod {
  call,  // Appel téléphonique
  sms,   // SMS
  other, // Autre (rencontre en personne, etc.)
}

/// Contexte du contact
enum ContactContext {
  normal,   // Contact normal
  birthday, // Contact pour anniversaire
}

/// Catégorie d'une note
enum NoteCategory {
  general,      // Note générale
  preference,   // Préférence personnelle
  gift,         // Cadeau donné/reçu
  conversation, // Sujet de conversation
  transcript,   // Transcript de conversation (long)
  action,       // Action/Rappel
  event,        // Événement
}

/// Importance d'une note
enum NoteImportance {
  low,    // Basse
  medium, // Moyenne
  high,   // Haute
}

/// Extensions pour faciliter la conversion et l'affichage

extension CallFrequencyExtension on CallFrequency {
  String toJson() {
    return toString().split('.').last;
  }

  static CallFrequency fromJson(String value) {
    return CallFrequency.values.firstWhere(
      (e) => e.toString().split('.').last == value,
      orElse: () => CallFrequency.monthly,
    );
  }

  String get displayName {
    switch (this) {
      case CallFrequency.weekly:
        return 'Hebdomadaire';
      case CallFrequency.biweekly:
        return 'Bihebdomadaire';
      case CallFrequency.monthly:
        return 'Mensuel';
      case CallFrequency.quarterly:
        return 'Trimestriel';
      case CallFrequency.yearly:
        return 'Annuel';
    }
  }
}

extension ContactCategoryExtension on ContactCategory {
  String toJson() {
    return toString().split('.').last;
  }

  static ContactCategory fromJson(String value) {
    return ContactCategory.values.firstWhere(
      (e) => e.toString().split('.').last == value,
      orElse: () => ContactCategory.friends,
    );
  }

  String get displayName {
    switch (this) {
      case ContactCategory.family:
        return 'Famille';
      case ContactCategory.friends:
        return 'Amis';
      case ContactCategory.professional:
        return 'Professionnel';
    }
  }
}

extension PriorityExtension on Priority {
  String toJson() {
    return toString().split('.').last;
  }

  static Priority fromJson(String value) {
    return Priority.values.firstWhere(
      (e) => e.toString().split('.').last == value,
      orElse: () => Priority.low,
    );
  }

  String get displayName {
    switch (this) {
      case Priority.high:
        return 'Haute';
      case Priority.medium:
        return 'Moyenne';
      case Priority.low:
        return 'Basse';
      case Priority.birthday:
        return 'Anniversaire';
    }
  }
}

extension ContactMethodExtension on ContactMethod {
  String toJson() {
    return toString().split('.').last;
  }

  static ContactMethod fromJson(String value) {
    return ContactMethod.values.firstWhere(
      (e) => e.toString().split('.').last == value,
      orElse: () => ContactMethod.call,
    );
  }

  String get displayName {
    switch (this) {
      case ContactMethod.call:
        return 'Appel';
      case ContactMethod.sms:
        return 'SMS';
      case ContactMethod.other:
        return 'Autre';
    }
  }
}

extension ContactContextExtension on ContactContext {
  String toJson() {
    return toString().split('.').last;
  }

  static ContactContext fromJson(String value) {
    return ContactContext.values.firstWhere(
      (e) => e.toString().split('.').last == value,
      orElse: () => ContactContext.normal,
    );
  }

  String get displayName {
    switch (this) {
      case ContactContext.normal:
        return 'Normal';
      case ContactContext.birthday:
        return 'Anniversaire';
    }
  }
}

extension NoteCategoryExtension on NoteCategory {
  String toJson() {
    return toString().split('.').last;
  }

  static NoteCategory fromJson(String value) {
    return NoteCategory.values.firstWhere(
      (e) => e.toString().split('.').last == value,
      orElse: () => NoteCategory.general,
    );
  }

  String get displayName {
    switch (this) {
      case NoteCategory.general:
        return 'Général';
      case NoteCategory.preference:
        return 'Préférence';
      case NoteCategory.gift:
        return 'Cadeau';
      case NoteCategory.conversation:
        return 'Conversation';
      case NoteCategory.transcript:
        return 'Transcript';
      case NoteCategory.action:
        return 'Action';
      case NoteCategory.event:
        return 'Événement';
    }
  }

  String get icon {
    switch (this) {
      case NoteCategory.general:
        return '📌';
      case NoteCategory.preference:
        return '❤️';
      case NoteCategory.gift:
        return '🎁';
      case NoteCategory.conversation:
        return '💬';
      case NoteCategory.transcript:
        return '📝';
      case NoteCategory.action:
        return '🎯';
      case NoteCategory.event:
        return '📅';
    }
  }
}

extension NoteImportanceExtension on NoteImportance {
  String toJson() {
    return toString().split('.').last;
  }

  static NoteImportance fromJson(String value) {
    return NoteImportance.values.firstWhere(
      (e) => e.toString().split('.').last == value,
      orElse: () => NoteImportance.medium,
    );
  }

  String get displayName {
    switch (this) {
      case NoteImportance.low:
        return 'Basse';
      case NoteImportance.medium:
        return 'Moyenne';
      case NoteImportance.high:
        return 'Haute';
    }
  }

  String get icon {
    switch (this) {
      case NoteImportance.low:
        return '⚪';
      case NoteImportance.medium:
        return '🟡';
      case NoteImportance.high:
        return '🔴';
    }
  }
}

/// Catégorie d'un événement
enum EventCategory {
  vacation,    // Vacances
  weekend,     // Week-end
  shopping,    // Courses
  birthday,    // Anniversaires
  almanac,     // Almanach
  fullMoon,    // Pleine lune
  holiday,     // Jour férié
  medical,     // Médical/Santé
  meeting,     // Réunion/RDV
  restaurant,  // Restaurant
  conference,  // Conférence
  other,       // Autre
}

/// Statut d'un événement
enum EventStatus {
  active,    // Actif
  archived,  // Archivé
}

extension EventCategoryExtension on EventCategory {
  String toJson() {
    return toString().split('.').last;
  }

  static EventCategory fromJson(String value) {
    return EventCategory.values.firstWhere(
      (e) => e.toString().split('.').last == value,
      orElse: () => EventCategory.other,
    );
  }

  String get displayName {
    switch (this) {
      case EventCategory.vacation:
        return 'Vacances';
      case EventCategory.weekend:
        return 'Week-end';
      case EventCategory.shopping:
        return 'Courses';
      case EventCategory.birthday:
        return 'Anniversaire';
      case EventCategory.almanac:
        return 'Almanach';
      case EventCategory.fullMoon:
        return 'Pleine lune';
      case EventCategory.holiday:
        return 'Jour férié';
      case EventCategory.medical:
        return 'Médical';
      case EventCategory.meeting:
        return 'Réunion';
      case EventCategory.restaurant:
        return 'Restaurant';
      case EventCategory.conference:
        return 'Conférence';
      case EventCategory.other:
        return 'Autre';
    }
  }

  String get icon {
    switch (this) {
      case EventCategory.vacation:
        return '🏖️';
      case EventCategory.weekend:
        return '🏡';
      case EventCategory.shopping:
        return '🛒';
      case EventCategory.birthday:
        return '🎂';
      case EventCategory.almanac:
        return '📅';
      case EventCategory.fullMoon:
        return '🌕';
      case EventCategory.holiday:
        return '🎊';
      case EventCategory.medical:
        return '⚕️';
      case EventCategory.meeting:
        return '🤝';
      case EventCategory.restaurant:
        return '🍽️';
      case EventCategory.conference:
        return '🎤';
      case EventCategory.other:
        return '📌';
    }
  }
}

extension EventStatusExtension on EventStatus {
  String toJson() {
    return toString().split('.').last;
  }

  static EventStatus fromJson(String value) {
    return EventStatus.values.firstWhere(
      (e) => e.toString().split('.').last == value,
      orElse: () => EventStatus.active,
    );
  }

  String get displayName {
    switch (this) {
      case EventStatus.active:
        return 'Actif';
      case EventStatus.archived:
        return 'Archivé';
    }
  }

  String get icon {
    switch (this) {
      case EventStatus.active:
        return '✅';
      case EventStatus.archived:
        return '📦';
    }
  }
}
