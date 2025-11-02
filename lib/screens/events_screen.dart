import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/event.dart';
import '../models/enums.dart';
import '../models/view_mode.dart';
import '../providers/events_provider.dart';
import '../widgets/event_card.dart';
import '../widgets/event_filter_chips.dart';
import '../widgets/empty_state.dart';
import '../widgets/events_calendar_view.dart';

/// Écran principal pour afficher la liste des événements
class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  EventFilter _currentFilter = EventFilter.upcoming;
  ViewMode _viewMode = ViewMode.list;

  @override
  void initState() {
    super.initState();
    // Charger les événements au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventsProvider>().loadEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Événements'),
        actions: [
          // Bouton pour basculer entre les vues
          IconButton(
            icon: Icon(
              _viewMode == ViewMode.list
                ? Icons.calendar_month
                : Icons.view_list,
            ),
            onPressed: () {
              setState(() {
                _viewMode = _viewMode == ViewMode.list
                  ? ViewMode.calendar
                  : ViewMode.list;
              });
            },
            tooltip: _viewMode == ViewMode.list
              ? 'Vue calendrier'
              : 'Vue liste',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<EventsProvider>().loadEvents(),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _viewMode == ViewMode.calendar
        ? const EventsCalendarView()
        : Column(
            children: [
              // Chips de filtrage (seulement en vue liste)
              EventFilterChips(
                currentFilter: _currentFilter,
                onFilterChanged: (filter) {
                  setState(() => _currentFilter = filter);
                },
              ),

              // Liste des événements
              Expanded(
                child: Consumer<EventsProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.error != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Erreur : ${provider.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => provider.loadEvents(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final filteredEvents = _getFilteredEvents(provider);

                if (filteredEvents.isEmpty) {
                  String emptyMessage;
                  String emptyTitle;

                  switch (_currentFilter) {
                    case EventFilter.upcoming:
                      emptyTitle = 'Aucun événement à venir';
                      emptyMessage = 'Créez un nouvel événement pour commencer';
                      break;
                    case EventFilter.past:
                      emptyTitle = 'Aucun événement passé';
                      emptyMessage = 'Les événements terminés apparaîtront ici';
                      break;
                    case EventFilter.archived:
                      emptyTitle = 'Aucun événement archivé';
                      emptyMessage = 'Les événements archivés apparaîtront ici';
                      break;
                    case EventFilter.all:
                      emptyTitle = 'Aucun événement';
                      emptyMessage = 'Créez votre premier événement !';
                      break;
                  }

                  return EmptyState(
                    icon: Icons.event,
                    title: emptyTitle,
                    message: emptyMessage,
                    actionLabel: _currentFilter == EventFilter.archived
                        ? null
                        : 'Créer un événement',
                    onActionPressed: _currentFilter == EventFilter.archived
                        ? null
                        : () => Navigator.pushNamed(context, '/add-event'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => provider.loadEvents(),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 88),
                    itemCount: filteredEvents.length,
                    itemBuilder: (context, index) {
                      final event = filteredEvents[index];
                      return EventCard(
                        event: event,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/event-detail',
                            arguments: event.id,
                          );
                        },
                        onLongPress: () => _showEventOptions(context, event),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/add-event'),
        tooltip: 'Nouvel événement',
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Retourne les événements filtrés selon le filtre actuel
  List<Event> _getFilteredEvents(EventsProvider provider) {
    switch (_currentFilter) {
      case EventFilter.upcoming:
        return provider.getUpcomingEvents();
      case EventFilter.past:
        return provider.getPastEvents();
      case EventFilter.archived:
        return provider.getArchivedEvents();
      case EventFilter.all:
        return provider.events;
    }
  }

  /// Affiche les options pour un événement (archive, supprime, etc.)
  void _showEventOptions(BuildContext context, Event event) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Modifier'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(
                    context,
                    '/edit-event',
                    arguments: event.id,
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  event.status == EventStatus.active ? Icons.archive : Icons.unarchive,
                ),
                title: Text(
                  event.status == EventStatus.active ? 'Archiver' : 'Désarchiver',
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final provider = context.read<EventsProvider>();
                  if (event.status == EventStatus.active) {
                    await provider.archiveEvent(event.id!);
                  } else {
                    await provider.unarchiveEvent(event.id!);
                  }

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          event.status == EventStatus.active
                              ? 'Événement archivé'
                              : 'Événement désarchivé',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(context, event);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Annuler'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Confirme la suppression d'un événement
  Future<void> _confirmDelete(BuildContext context, Event event) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Supprimer l\'événement ?'),
          content: Text(
            'Voulez-vous vraiment supprimer "${event.title}" ?\nCette action est irréversible.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirm == true && context.mounted) {
      try {
        await context.read<EventsProvider>().deleteEvent(event.id!);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Événement supprimé'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur : $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}