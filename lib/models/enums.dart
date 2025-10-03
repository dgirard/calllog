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
  call, // Appel téléphonique
  sms,  // SMS
}

/// Contexte du contact
enum ContactContext {
  normal,   // Contact normal
  birthday, // Contact pour anniversaire
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
