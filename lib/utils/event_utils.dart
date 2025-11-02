import 'package:intl/intl.dart';
import '../models/event.dart';
import '../models/enums.dart';

/// Retourne true si l'événement est à venir
bool isUpcomingEvent(Event event) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final eventStart = DateTime(
    event.startDate.year,
    event.startDate.month,
    event.startDate.day,
  );

  return eventStart.isAfter(today) || eventStart.isAtSameMomentAs(today);
}

/// Retourne true si l'événement est passé
bool isPastEvent(Event event) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final eventEnd = event.endDate != null
      ? DateTime(
          event.endDate!.year,
          event.endDate!.month,
          event.endDate!.day,
        )
      : DateTime(
          event.startDate.year,
          event.startDate.month,
          event.startDate.day,
        );

  return eventEnd.isBefore(today);
}

/// Retourne true si l'événement est en cours
bool isOngoingEvent(Event event) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final eventStart = DateTime(
    event.startDate.year,
    event.startDate.month,
    event.startDate.day,
  );
  final eventEnd = event.endDate != null
      ? DateTime(
          event.endDate!.year,
          event.endDate!.month,
          event.endDate!.day,
        )
      : eventStart;

  return (eventStart.isBefore(today) || eventStart.isAtSameMomentAs(today)) &&
         (eventEnd.isAfter(today) || eventEnd.isAtSameMomentAs(today));
}

/// Retourne le nombre de jours jusqu'à l'événement
int? daysUntilEvent(Event event) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final eventStart = DateTime(
    event.startDate.year,
    event.startDate.month,
    event.startDate.day,
  );

  if (eventStart.isBefore(today)) return null;

  return eventStart.difference(today).inDays;
}

/// Formate la durée de l'événement
String formatEventDuration(Event event) {
  if (event.endDate == null) {
    return '1 jour';
  }

  final duration = event.endDate!.difference(event.startDate).inDays + 1;
  return '$duration jour${duration > 1 ? 's' : ''}';
}

/// Formate une plage de dates
String formatDateRange(DateTime startDate, DateTime? endDate) {
  final dateFormat = DateFormat('d MMMM', 'fr_FR');
  final yearFormat = DateFormat('y', 'fr_FR');

  final startStr = dateFormat.format(startDate);
  final startYear = yearFormat.format(startDate);

  if (endDate == null) {
    return '$startStr $startYear';
  }

  final endStr = dateFormat.format(endDate);
  final endYear = yearFormat.format(endDate);

  // Si même année, on l'affiche qu'une fois
  if (startYear == endYear) {
    if (startStr == endStr) {
      return '$startStr $startYear';
    }
    return '$startStr au $endStr $startYear';
  } else {
    return '$startStr $startYear au $endStr $endYear';
  }
}

/// Formate une date courte
String formatShortDate(DateTime date) {
  final format = DateFormat('dd/MM', 'fr_FR');
  return format.format(date);
}

/// Formate une date complète
String formatFullDate(DateTime date) {
  final format = DateFormat('EEEE d MMMM yyyy', 'fr_FR');
  return format.format(date);
}

/// Trie les événements par date de début
List<Event> sortEventsByDate(List<Event> events, {bool ascending = true}) {
  final sorted = List<Event>.from(events);
  sorted.sort((a, b) {
    final comparison = a.startDate.compareTo(b.startDate);
    return ascending ? comparison : -comparison;
  });
  return sorted;
}

/// Filtre les événements par catégorie
List<Event> filterEventsByCategory(List<Event> events, EventCategory category) {
  return events.where((event) => event.category == category).toList();
}

/// Filtre les événements par statut
List<Event> filterEventsByStatus(List<Event> events, EventStatus status) {
  return events.where((event) => event.status == status).toList();
}

/// Retourne les événements d'un mois donné
List<Event> getEventsForMonth(List<Event> events, DateTime month) {
  final firstDay = DateTime(month.year, month.month, 1);
  final lastDay = DateTime(month.year, month.month + 1, 0);

  return events.where((event) {
    // Vérifier si l'événement commence dans le mois
    final startInMonth = event.startDate.isAfter(firstDay.subtract(const Duration(days: 1))) &&
                        event.startDate.isBefore(lastDay.add(const Duration(days: 1)));

    // Vérifier si l'événement se termine dans le mois
    final endInMonth = event.endDate != null &&
                      event.endDate!.isAfter(firstDay.subtract(const Duration(days: 1))) &&
                      event.endDate!.isBefore(lastDay.add(const Duration(days: 1)));

    // Vérifier si l'événement traverse le mois
    final spansMonth = event.startDate.isBefore(firstDay) &&
                      (event.endDate != null && event.endDate!.isAfter(lastDay));

    return startInMonth || endInMonth || spansMonth;
  }).toList();
}

/// Retourne les événements d'une semaine donnée
List<Event> getEventsForWeek(List<Event> events, DateTime weekStart) {
  final weekEnd = weekStart.add(const Duration(days: 6));

  return events.where((event) {
    final eventEnd = event.endDate ?? event.startDate;

    // L'événement commence ou se termine dans la semaine
    final startsInWeek = event.startDate.isAfter(weekStart.subtract(const Duration(days: 1))) &&
                         event.startDate.isBefore(weekEnd.add(const Duration(days: 1)));

    final endsInWeek = eventEnd.isAfter(weekStart.subtract(const Duration(days: 1))) &&
                       eventEnd.isBefore(weekEnd.add(const Duration(days: 1)));

    // L'événement traverse la semaine
    final spansWeek = event.startDate.isBefore(weekStart) && eventEnd.isAfter(weekEnd);

    return startsInWeek || endsInWeek || spansWeek;
  }).toList();
}

/// Retourne les événements du jour
List<Event> getEventsForDay(List<Event> events, DateTime day) {
  final dayStart = DateTime(day.year, day.month, day.day);
  final dayEnd = dayStart.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));

  return events.where((event) {
    final eventEnd = event.endDate ?? event.startDate;

    // L'événement se déroule ce jour
    return (event.startDate.isAtSameMomentAs(dayStart) || event.startDate.isBefore(dayEnd)) &&
           (eventEnd.isAtSameMomentAs(dayStart) || eventEnd.isAfter(dayStart));
  }).toList();
}

/// Groupe les événements par catégorie
Map<EventCategory, List<Event>> groupEventsByCategory(List<Event> events) {
  final grouped = <EventCategory, List<Event>>{};

  for (final event in events) {
    grouped.putIfAbsent(event.category, () => []).add(event);
  }

  return grouped;
}

/// Groupe les événements par mois
Map<DateTime, List<Event>> groupEventsByMonth(List<Event> events) {
  final grouped = <DateTime, List<Event>>{};

  for (final event in events) {
    final monthKey = DateTime(event.startDate.year, event.startDate.month, 1);
    grouped.putIfAbsent(monthKey, () => []).add(event);
  }

  return Map.fromEntries(
    grouped.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
  );
}

/// Retourne un résumé de l'événement pour l'affichage
String getEventSummary(Event event) {
  final duration = formatEventDuration(event);
  final dateRange = formatDateRange(event.startDate, event.endDate);
  return '$dateRange ($duration)';
}

/// Retourne la couleur suggérée pour la catégorie
int getEventCategoryColor(EventCategory category) {
  switch (category) {
    case EventCategory.vacation:
      return 0xFF2196F3; // Bleu
    case EventCategory.weekend:
      return 0xFF4CAF50; // Vert
    case EventCategory.shopping:
      return 0xFFFF9800; // Orange
    case EventCategory.birthday:
      return 0xFFE91E63; // Rose
    case EventCategory.almanac:
      return 0xFF9C27B0; // Violet
    case EventCategory.fullMoon:
      return 0xFF3F51B5; // Indigo
    case EventCategory.holiday:
      return 0xFFF44336; // Rouge
    case EventCategory.medical:
      return 0xFF009688; // Teal
    case EventCategory.meeting:
      return 0xFFFFC107; // Amber
    case EventCategory.restaurant:
      return 0xFF795548; // Brun
    case EventCategory.conference:
      return 0xFF673AB7; // Violet profond
    case EventCategory.other:
      return 0xFF607D8B; // Gris bleu
  }
}