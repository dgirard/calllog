import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/event.dart';
import '../models/enums.dart';
import '../providers/anonymity_provider.dart';

/// Widget représentant une carte d'événement
class EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const EventCard({
    super.key,
    required this.event,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isAnonymous = context.watch<AnonymityProvider>().isAnonymousModeEnabled;
    final displayTitle = isAnonymous ? '****' : event.title;
    final displayDescription = isAnonymous ? '****' : (event.description ?? '');

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventStart = DateTime(
      event.startDate.year,
      event.startDate.month,
      event.startDate.day,
    );

    final daysUntil = eventStart.difference(today).inDays;
    final isPast = event.isPast;
    final isOngoing = event.isOngoing;
    final isArchived = event.status == EventStatus.archived;

    // Couleur de la carte selon le statut
    Color? cardColor;
    if (isArchived) {
      cardColor = Colors.grey[100];
    } else if (isOngoing) {
      cardColor = Theme.of(context).primaryColor.withOpacity(0.05);
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: isArchived ? 1 : 2,
      color: cardColor,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icône de catégorie
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getCategoryColor(event.category).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    event.category.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Contenu principal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre et badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayTitle,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isArchived ? Colors.grey : null,
                              decoration: isArchived ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                        // Badges de statut
                        if (isOngoing) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'EN COURS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ] else if (!isPast && !isArchived && daysUntil <= 7) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: daysUntil == 0 ? Colors.red : Colors.orange,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              daysUntil == 0
                                  ? 'AUJOURD\'HUI'
                                  : 'Dans $daysUntil jour${daysUntil > 1 ? 's' : ''}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Catégorie
                    Text(
                      event.category.displayName,
                      style: TextStyle(
                        color: _getCategoryColor(event.category),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Dates
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDateRange(),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),

                    // Durée
                    if (event.duration > 1) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${event.duration} jours',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Description (aperçu)
                    if (displayDescription.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        displayDescription,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          fontStyle: isAnonymous ? FontStyle.italic : null,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Indicateur de navigation
              const SizedBox(width: 8),
              Icon(
                isArchived ? Icons.archive : Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Formate la plage de dates
  String _formatDateRange() {
    final dateFormat = DateFormat('d MMM', 'fr_FR');
    final yearFormat = DateFormat('y', 'fr_FR');

    final startStr = dateFormat.format(event.startDate);
    final startYear = yearFormat.format(event.startDate);

    if (event.endDate == null) {
      return '$startStr $startYear';
    }

    final endStr = dateFormat.format(event.endDate!);
    final endYear = yearFormat.format(event.endDate!);

    // Si même année, on l'affiche qu'une fois
    if (startYear == endYear) {
      if (startStr == endStr) {
        return '$startStr $startYear';
      }
      return '$startStr → $endStr $startYear';
    } else {
      return '$startStr $startYear → $endStr $endYear';
    }
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