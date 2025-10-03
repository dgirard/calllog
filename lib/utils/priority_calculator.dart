import '../models/tracked_contact.dart';
import '../models/enums.dart';
import 'constants.dart';
import 'birthday_utils.dart';

/// Utilitaires pour calculer la priorité des contacts

/// Calcule la priorité d'un contact en fonction de son dernier contact et de son anniversaire
Priority calculatePriority(TrackedContact contact) {
  // Priorité maximale si c'est l'anniversaire aujourd'hui
  if (isBirthdayToday(contact.birthday)) {
    return Priority.birthday;
  }

  // Si pas de dernier contact, priorité haute
  if (contact.lastContactDate == null) {
    return Priority.high;
  }

  final daysSinceContact = DateTime.now()
      .difference(contact.lastContactDate!)
      .inDays;

  final expectedDelay = getExpectedDelay(contact.frequency);

  // Calcul de la priorité
  if (daysSinceContact > expectedDelay) {
    return Priority.high; // En retard
  } else if (daysSinceContact > (expectedDelay * mediumPriorityThreshold)) {
    return Priority.medium; // Bientôt
  } else {
    return Priority.low; // À jour
  }
}

/// Retourne le délai attendu en jours pour une fréquence donnée
int getExpectedDelay(CallFrequency frequency) {
  return frequencyDurations[frequency] ?? 30;
}

/// Calcule le nombre de jours jusqu'au prochain contact prévu
int getDaysUntilNextContact(TrackedContact contact) {
  if (contact.lastContactDate == null) {
    return 0; // Devrait être contacté immédiatement
  }

  final expectedDelay = getExpectedDelay(contact.frequency);
  final daysSinceContact = DateTime.now()
      .difference(contact.lastContactDate!)
      .inDays;

  final daysRemaining = expectedDelay - daysSinceContact;

  return daysRemaining > 0 ? daysRemaining : 0;
}

/// Retourne le nombre de jours de retard (valeur positive si en retard)
int getDaysOverdue(TrackedContact contact) {
  if (contact.lastContactDate == null) {
    return 999; // Valeur élevée pour tri
  }

  final expectedDelay = getExpectedDelay(contact.frequency);
  final daysSinceContact = DateTime.now()
      .difference(contact.lastContactDate!)
      .inDays;

  final overdue = daysSinceContact - expectedDelay;

  return overdue > 0 ? overdue : 0;
}

/// Compare deux contacts pour le tri par priorité
/// Retourne un nombre négatif si a doit être avant b
int compareContactsByPriority(TrackedContact a, TrackedContact b) {
  // 1. Anniversaire aujourd'hui en premier
  final aBirthdayToday = isBirthdayToday(a.birthday);
  final bBirthdayToday = isBirthdayToday(b.birthday);

  if (aBirthdayToday && !bBirthdayToday) return -1;
  if (!aBirthdayToday && bBirthdayToday) return 1;

  // 2. Anniversaires proches (dans les 7 jours)
  final aBirthdaySoon = isBirthdaySoon(a.birthday);
  final bBirthdaySoon = isBirthdaySoon(b.birthday);

  if (aBirthdaySoon && !bBirthdaySoon) return -1;
  if (!aBirthdaySoon && bBirthdaySoon) return 1;

  // Si les deux ont un anniversaire proche, trier par jours restants
  if (aBirthdaySoon && bBirthdaySoon) {
    final aDays = daysUntilBirthday(a.birthday) ?? 999;
    final bDays = daysUntilBirthday(b.birthday) ?? 999;
    if (aDays != bDays) return aDays.compareTo(bDays);
  }

  // 3. Priorité de contact
  final aPriority = calculatePriority(a);
  final bPriority = calculatePriority(b);

  final priorityOrder = {
    Priority.birthday: 0,
    Priority.high: 1,
    Priority.medium: 2,
    Priority.low: 3,
  };

  final aPriorityValue = priorityOrder[aPriority] ?? 3;
  final bPriorityValue = priorityOrder[bPriority] ?? 3;

  if (aPriorityValue != bPriorityValue) {
    return aPriorityValue.compareTo(bPriorityValue);
  }

  // 4. Si même priorité, trier par délai écoulé (du plus ancien au plus récent)
  final aOverdue = getDaysOverdue(a);
  final bOverdue = getDaysOverdue(b);

  if (aOverdue != bOverdue) {
    return bOverdue.compareTo(aOverdue); // Ordre décroissant (plus en retard d'abord)
  }

  // 5. Par défaut, ordre alphabétique
  return a.contactName.compareTo(b.contactName);
}

/// Trie une liste de contacts par priorité
List<TrackedContact> sortContactsByPriority(List<TrackedContact> contacts) {
  final sortedList = List<TrackedContact>.from(contacts);
  sortedList.sort(compareContactsByPriority);
  return sortedList;
}
