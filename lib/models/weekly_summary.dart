import '../models/tracked_contact.dart';
import '../models/event.dart';

/// Modèle de données pour le résumé hebdomadaire
class WeeklySummary {
  final List<TrackedContact> callsToMake;
  final List<TrackedContact> upcomingBirthdays;
  final List<Event> weekEvents;
  final DateTime generatedAt;
  final String? summaryText;

  WeeklySummary({
    required this.callsToMake,
    required this.upcomingBirthdays,
    required this.weekEvents,
    required this.generatedAt,
    this.summaryText,
  });

  /// Nombre total d'éléments dans le résumé
  int get totalItems =>
      callsToMake.length + upcomingBirthdays.length + weekEvents.length;

  /// Indique si le résumé contient des données
  bool get hasContent => totalItems > 0;

  /// Retourne une copie avec le texte du résumé mis à jour
  WeeklySummary withSummaryText(String text) {
    return WeeklySummary(
      callsToMake: callsToMake,
      upcomingBirthdays: upcomingBirthdays,
      weekEvents: weekEvents,
      generatedAt: generatedAt,
      summaryText: text,
    );
  }

  /// Formate le résumé pour l'affichage debug
  @override
  String toString() {
    return '''
WeeklySummary {
  callsToMake: ${callsToMake.length} contacts,
  upcomingBirthdays: ${upcomingBirthdays.length} birthdays,
  weekEvents: ${weekEvents.length} events,
  generatedAt: $generatedAt,
  hasSummaryText: ${summaryText != null}
}
''';
  }
}

/// Données pour une tâche d'appel
class CallTask {
  final TrackedContact contact;
  final int daysOverdue;
  final String priority;

  CallTask({
    required this.contact,
    required this.daysOverdue,
    required this.priority,
  });

  String get displayText {
    if (daysOverdue > 0) {
      return '${contact.contactName} (${daysOverdue} jours de retard)';
    } else {
      return contact.contactName;
    }
  }
}

/// Données pour un anniversaire
class BirthdayReminder {
  final TrackedContact contact;
  final int daysUntil;
  final DateTime birthDate;

  BirthdayReminder({
    required this.contact,
    required this.daysUntil,
    required this.birthDate,
  });

  String get displayText {
    if (daysUntil == 0) {
      return '${contact.contactName} (aujourd\'hui !)';
    } else if (daysUntil == 1) {
      return '${contact.contactName} (demain)';
    } else {
      return '${contact.contactName} (dans $daysUntil jours)';
    }
  }
}

/// Type de résumé
enum SummaryType {
  weekly,
  daily,
  monthly,
}

/// Extension pour le type de résumé
extension SummaryTypeExtension on SummaryType {
  String get displayName {
    switch (this) {
      case SummaryType.weekly:
        return 'Hebdomadaire';
      case SummaryType.daily:
        return 'Quotidien';
      case SummaryType.monthly:
        return 'Mensuel';
    }
  }

  int get daysRange {
    switch (this) {
      case SummaryType.weekly:
        return 7;
      case SummaryType.daily:
        return 1;
      case SummaryType.monthly:
        return 30;
    }
  }
}