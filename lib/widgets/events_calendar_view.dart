import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/event.dart';
import '../models/enums.dart';
import '../providers/events_provider.dart';
import '../screens/event_detail_screen.dart';
import '../screens/add_event_screen.dart';
import 'calendar_event_marker.dart';

/// Vue calendrier pour afficher les événements
class EventsCalendarView extends StatefulWidget {
  const EventsCalendarView({super.key});

  @override
  State<EventsCalendarView> createState() => _EventsCalendarViewState();
}

class _EventsCalendarViewState extends State<EventsCalendarView> {
  late final ValueNotifier<List<Event>> _selectedEvents;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  /// Récupère les événements pour un jour donné
  List<Event> _getEventsForDay(DateTime day) {
    final provider = context.read<EventsProvider>();
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));

    return provider.events.where((event) {
      final eventEnd = event.endDate ?? event.startDate;

      // L'événement se déroule ce jour
      return (event.startDate.isAtSameMomentAs(dayStart) || event.startDate.isBefore(dayEnd)) &&
             (eventEnd.isAtSameMomentAs(dayStart) || eventEnd.isAfter(dayStart));
    }).toList();
  }

  /// Récupère tous les événements pour le mois affiché
  Map<DateTime, List<Event>> _getEventsForMonth() {
    final provider = context.read<EventsProvider>();
    final firstDay = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final lastDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);

    final eventsMap = <DateTime, List<Event>>{};

    for (var day = firstDay; day.isBefore(lastDay.add(const Duration(days: 1))); day = day.add(const Duration(days: 1))) {
      final dayKey = DateTime(day.year, day.month, day.day);
      final dayEvents = _getEventsForDay(dayKey);
      if (dayEvents.isNotEmpty) {
        eventsMap[dayKey] = dayEvents;
      }
    }

    return eventsMap;
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _selectedEvents.value = _getEventsForDay(selectedDay);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EventsProvider>(
      builder: (context, provider, child) {
        final eventsMap = _getEventsForMonth();

        return Column(
          children: [
            // Calendrier
            Card(
              margin: const EdgeInsets.all(8.0),
              elevation: 2,
              child: TableCalendar<Event>(
                locale: 'fr_FR',
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                eventLoader: (day) {
                  return _getEventsForDay(day);
                },
                startingDayOfWeek: StartingDayOfWeek.monday,
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  weekendTextStyle: const TextStyle(color: Colors.blue),
                  holidayTextStyle: const TextStyle(color: Colors.red),
                  selectedDecoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle: const TextStyle(color: Colors.white),
                  todayDecoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  markersMaxCount: 1,
                  markerDecoration: const BoxDecoration(),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: true,
                  titleCentered: true,
                  formatButtonShowsNext: false,
                  formatButtonDecoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  formatButtonTextStyle: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 13.0,
                  ),
                  titleTextFormatter: (date, locale) {
                    return DateFormat.yMMMM(locale).format(date).toUpperCase();
                  },
                ),
                daysOfWeekStyle: const DaysOfWeekStyle(
                  weekdayStyle: TextStyle(fontSize: 13),
                  weekendStyle: TextStyle(fontSize: 13, color: Colors.blue),
                ),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, day, events) {
                    if (events.isEmpty) return null;
                    return Positioned(
                      bottom: 1,
                      child: CalendarEventMarker(
                        events: events as List<Event>,
                        maxMarkers: 3,
                      ),
                    );
                  },
                ),
                onDaySelected: _onDaySelected,
                onFormatChanged: (format) {
                  if (_calendarFormat != format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  }
                },
                onPageChanged: (focusedDay) {
                  setState(() {
                    _focusedDay = focusedDay;
                  });
                },
              ),
            ),

            const SizedBox(height: 8.0),

            // Liste des événements du jour sélectionné
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedDay != null
                        ? 'Événements du ${DateFormat('d MMMM', 'fr_FR').format(_selectedDay!)}'
                        : 'Sélectionnez un jour',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_selectedDay != null)
                    TextButton.icon(
                      icon: const Icon(Icons.add, size: 20),
                      label: const Text('Ajouter'),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddEventScreen(
                              initialDate: _selectedDay,
                            ),
                          ),
                        );
                        setState(() {
                          _selectedEvents.value = _getEventsForDay(_selectedDay!);
                        });
                      },
                    ),
                ],
              ),
            ),

            const SizedBox(height: 8.0),

            // Liste des événements
            Expanded(
              child: ValueListenableBuilder<List<Event>>(
                valueListenable: _selectedEvents,
                builder: (context, events, _) {
                  if (events.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_busy,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun événement ce jour',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddEventScreen(
                                    initialDate: _selectedDay,
                                  ),
                                ),
                              );
                              setState(() {
                                _selectedEvents.value = _getEventsForDay(_selectedDay!);
                              });
                            },
                            child: const Text('Ajouter un événement'),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return _buildEventTile(event);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  /// Construit une tuile d'événement pour la liste
  Widget _buildEventTile(Event event) {
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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 1,
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getCategoryColor(event.category).withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              event.category.icon,
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ),
        title: Text(
          event.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: isArchived ? TextDecoration.lineThrough : null,
            color: isArchived ? Colors.grey : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.category.displayName,
              style: TextStyle(
                fontSize: 12,
                color: _getCategoryColor(event.category),
              ),
            ),
            if (event.description != null && event.description!.isNotEmpty)
              Text(
                event.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        trailing: _buildEventBadge(event, isOngoing, isPast, isArchived, daysUntil),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventDetailScreen(eventId: event.id!),
            ),
          );
          setState(() {
            _selectedEvents.value = _getEventsForDay(_selectedDay!);
          });
        },
      ),
    );
  }

  /// Construit le badge de statut pour un événement
  Widget? _buildEventBadge(Event event, bool isOngoing, bool isPast, bool isArchived, int daysUntil) {
    if (isArchived) {
      return const Icon(Icons.archive, size: 20, color: Colors.grey);
    }

    if (isOngoing) {
      return Container(
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
      );
    }

    if (!isPast && daysUntil == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'AUJOURD\'HUI',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    if (event.duration > 1) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '${event.duration}j',
          style: TextStyle(
            color: Colors.blue[700],
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return null;
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