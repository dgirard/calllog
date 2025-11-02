import 'package:flutter/material.dart';
import '../models/event.dart';
import '../models/enums.dart';

/// Widget pour afficher les marqueurs d'événements sur le calendrier
class CalendarEventMarker extends StatelessWidget {
  final List<Event> events;
  final int maxMarkers;

  const CalendarEventMarker({
    super.key,
    required this.events,
    this.maxMarkers = 5,
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const SizedBox.shrink();
    }

    // Grouper les événements par catégorie et compter
    final Map<EventCategory, int> categoryCounts = {};
    for (final event in events) {
      if (event.status == EventStatus.active) {
        categoryCounts[event.category] = (categoryCounts[event.category] ?? 0) + 1;
      }
    }

    if (categoryCounts.isEmpty) {
      return const SizedBox.shrink();
    }

    // Créer les marqueurs
    final markers = <Widget>[];
    int markerCount = 0;

    for (final entry in categoryCounts.entries) {
      if (markerCount >= maxMarkers) {
        break;
      }

      for (int i = 0; i < entry.value && markerCount < maxMarkers; i++) {
        markers.add(
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: _getCategoryColor(entry.key),
              shape: BoxShape.circle,
            ),
          ),
        );
        markerCount++;
      }
    }

    // Si plus d'événements que de marqueurs max, ajouter un indicateur
    final totalEvents = categoryCounts.values.reduce((a, b) => a + b);
    if (totalEvents > maxMarkers) {
      markers.add(
        Container(
          margin: const EdgeInsets.only(left: 2),
          child: Text(
            '+${totalEvents - maxMarkers}',
            style: TextStyle(
              fontSize: 9,
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: markers,
    );
  }

  /// Retourne la couleur associée à la catégorie
  Color _getCategoryColor(EventCategory category) {
    switch (category) {
      case EventCategory.vacation:
        return Colors.blue;
      case EventCategory.weekend:
        return Colors.green;
      case EventCategory.shopping:
        return Colors.orange;
      case EventCategory.birthday:
        return Colors.pink;
      case EventCategory.almanac:
        return Colors.purple;
      case EventCategory.fullMoon:
        return Colors.indigo;
      case EventCategory.holiday:
        return Colors.red;
      case EventCategory.medical:
        return Colors.teal;
      case EventCategory.meeting:
        return Colors.amber;
      case EventCategory.restaurant:
        return Colors.brown;
      case EventCategory.conference:
        return Colors.deepPurple;
      case EventCategory.other:
        return Colors.grey;
    }
  }
}