import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/event.dart';
import '../models/enums.dart';
import '../providers/events_provider.dart';
import '../providers/contacts_provider.dart';
import '../utils/event_utils.dart';

/// Écran de détail d'un événement
class EventDetailScreen extends StatefulWidget {
  final int eventId;

  const EventDetailScreen({
    super.key,
    required this.eventId,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  Event? _event;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvent();
  }

  Future<void> _loadEvent() async {
    setState(() => _isLoading = true);
    try {
      final provider = context.read<EventsProvider>();
      await provider.loadEvents();
      final event = provider.events.firstWhere(
        (e) => e.id == widget.eventId,
        orElse: () => throw Exception('Événement non trouvé'),
      );
      setState(() {
        _event = event;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Chargement...'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_event == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Événement'),
        ),
        body: const Center(
          child: Text('Événement non trouvé'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_event!.title),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 8),
                    Text('Modifier'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'archive',
                child: Row(
                  children: [
                    Icon(
                      _event!.status == EventStatus.active
                          ? Icons.archive
                          : Icons.unarchive,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(_event!.status == EventStatus.active
                        ? 'Archiver'
                        : 'Désarchiver'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Supprimer', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Carte d'information principale
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Catégorie et statut
                    Row(
                      children: [
                        Chip(
                          avatar: Text(
                            _event!.category.icon,
                            style: const TextStyle(fontSize: 16),
                          ),
                          label: Text(_event!.category.displayName),
                          backgroundColor:
                              Theme.of(context).primaryColor.withOpacity(0.1),
                        ),
                        const SizedBox(width: 8),
                        if (_event!.status == EventStatus.archived)
                          const Chip(
                            label: Text('Archivé'),
                            backgroundColor: Colors.grey,
                            labelStyle: TextStyle(color: Colors.white),
                          ),
                        if (isOngoingEvent(_event!))
                          Chip(
                            label: const Text('En cours'),
                            backgroundColor: Colors.green.withOpacity(0.8),
                            labelStyle: const TextStyle(color: Colors.white),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Titre
                    Text(
                      _event!.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),

                    if (_event!.description != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _event!.description!,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Carte des dates
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Dates',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Date de début
                    _DateRow(
                      label: 'Début',
                      date: formatFullDate(_event!.startDate),
                    ),

                    if (_event!.endDate != null) ...[
                      const SizedBox(height: 8),
                      _DateRow(
                        label: 'Fin',
                        date: formatFullDate(_event!.endDate!),
                      ),
                      const SizedBox(height: 8),
                      _DateRow(
                        label: 'Durée',
                        date: formatEventDuration(_event!),
                      ),
                    ],

                    // Temps relatif
                    if (isUpcomingEvent(_event!)) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Dans ${daysUntilEvent(_event!)} jour(s)',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Carte des participants
            Consumer<EventsProvider>(
              builder: (context, eventsProvider, child) {
                return FutureBuilder<List<int>>(
                  future: eventsProvider.getEventContactIds(_event!.id!),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      );
                    }

                    final contactIds = snapshot.data!;

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.people, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Participants',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                  ],
                                ),
                                if (contactIds.isNotEmpty)
                                  Chip(
                                    label: Text('${contactIds.length}'),
                                    backgroundColor: Theme.of(context)
                                        .primaryColor
                                        .withOpacity(0.1),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            if (contactIds.isEmpty)
                              const Text(
                                'Aucun participant associé',
                                style: TextStyle(color: Colors.grey),
                              )
                            else
                              Consumer<ContactsProvider>(
                                builder: (context, contactsProvider, child) {
                                  final contacts = contactsProvider.contacts
                                      .where((c) => contactIds.contains(c.id))
                                      .toList();

                                  return Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: contacts.map((contact) {
                                      return InkWell(
                                        onTap: () {
                                          Navigator.pushNamed(
                                            context,
                                            '/contact-detail',
                                            arguments: contact.id,
                                          );
                                        },
                                        child: Chip(
                                          avatar: CircleAvatar(
                                            child: Text(
                                              contact.contactName[0]
                                                  .toUpperCase(),
                                              style: const TextStyle(
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                          label: Text(contact.contactName),
                                        ),
                                      );
                                    }).toList(),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(String action) async {
    switch (action) {
      case 'edit':
        await Navigator.pushNamed(
          context,
          '/edit-event',
          arguments: _event!.id,
        );
        _loadEvent(); // Recharger l'événement après modification
        break;

      case 'archive':
        final provider = context.read<EventsProvider>();
        if (_event!.status == EventStatus.active) {
          await provider.archiveEvent(_event!.id!);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Événement archivé'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          await provider.unarchiveEvent(_event!.id!);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Événement désarchivé'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
        _loadEvent(); // Recharger pour afficher le nouveau statut
        break;

      case 'delete':
        _confirmDelete();
        break;
    }
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Supprimer l\'événement ?'),
          content: Text(
            'Voulez-vous vraiment supprimer "${_event!.title}" ?\nCette action est irréversible.',
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

    if (confirm == true && mounted) {
      try {
        await context.read<EventsProvider>().deleteEvent(_event!.id!);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Événement supprimé'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
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

/// Widget pour afficher une ligne de date
class _DateRow extends StatelessWidget {
  final String label;
  final String date;

  const _DateRow({
    required this.label,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            date,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}