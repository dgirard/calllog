import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/event.dart';
import '../models/enums.dart';
import '../providers/events_provider.dart';
import '../providers/contacts_provider.dart';

/// Écran pour modifier un événement existant
class EditEventScreen extends StatefulWidget {
  final int eventId;

  const EditEventScreen({
    super.key,
    required this.eventId,
  });

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  EventCategory _category = EventCategory.other;
  EventStatus _status = EventStatus.active;
  List<int> _selectedContactIds = [];

  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasEndDate = false;
  Event? _originalEvent;

  @override
  void initState() {
    super.initState();
    _loadEvent();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadEvent() async {
    try {
      final provider = context.read<EventsProvider>();
      await provider.loadEvents();

      final event = provider.events.firstWhere(
        (e) => e.id == widget.eventId,
        orElse: () => throw Exception('Événement non trouvé'),
      );

      // Charger les contacts associés
      final contactIds = await provider.getEventContactIds(event.id!);

      setState(() {
        _originalEvent = event;
        _titleController.text = event.title;
        _descriptionController.text = event.description ?? '';
        _startDate = event.startDate;
        _endDate = event.endDate;
        _hasEndDate = event.endDate != null;
        _category = event.category;
        _status = event.status;
        _selectedContactIds = contactIds;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
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

    if (_originalEvent == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Modifier l\'événement'),
        ),
        body: const Center(
          child: Text('Événement non trouvé'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier l\'événement'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Titre
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informations générales',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Titre *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.title),
                          hintText: 'Ex: Vacances d\'été',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Le titre est obligatoire';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                          hintText: 'Ex: Voyage en famille à la montagne',
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Catégorie et Statut
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Catégorie et statut',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<EventCategory>(
                        value: _category,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                          labelText: 'Catégorie',
                        ),
                        items: EventCategory.values.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Row(
                              children: [
                                Text(
                                  category.icon,
                                  style: const TextStyle(fontSize: 20),
                                ),
                                const SizedBox(width: 8),
                                Text(category.displayName),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _category = value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<EventStatus>(
                        value: _status,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.flag),
                          labelText: 'Statut',
                        ),
                        items: EventStatus.values.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(status.displayName),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _status = value);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Dates
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dates',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Date de début
                      _DatePickerTile(
                        label: 'Date de début *',
                        date: _startDate,
                        onDateSelected: (date) {
                          setState(() {
                            _startDate = date;
                            // Si la date de fin est avant la date de début, on la réinitialise
                            if (_endDate != null && _endDate!.isBefore(_startDate)) {
                              _endDate = null;
                              _hasEndDate = false;
                            }
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      // Switch pour activer la date de fin
                      SwitchListTile(
                        title: const Text('Événement sur plusieurs jours'),
                        value: _hasEndDate,
                        onChanged: (value) {
                          setState(() {
                            _hasEndDate = value;
                            if (!value) {
                              _endDate = null;
                            } else {
                              _endDate = _startDate;
                            }
                          });
                        },
                      ),

                      // Date de fin (si activée)
                      if (_hasEndDate) ...[
                        const SizedBox(height: 16),
                        _DatePickerTile(
                          label: 'Date de fin',
                          date: _endDate ?? _startDate,
                          minDate: _startDate,
                          onDateSelected: (date) {
                            setState(() => _endDate = date);
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Sélection des contacts
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Participants',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_selectedContactIds.isNotEmpty)
                            Chip(
                              label: Text('${_selectedContactIds.length}'),
                              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Sélectionnez les contacts concernés par cet événement',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      _ContactsSelector(
                        selectedContactIds: _selectedContactIds,
                        onContactsChanged: (contactIds) {
                          setState(() => _selectedContactIds = contactIds);
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Bouton Enregistrer
              ElevatedButton(
                onPressed: _isSaving ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Enregistrer les modifications',
                        style: TextStyle(fontSize: 16),
                      ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final updatedEvent = Event(
        id: _originalEvent!.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        startDate: _startDate,
        endDate: _hasEndDate ? _endDate : null,
        category: _category,
        status: _status,
      );

      await context.read<EventsProvider>().updateEvent(updatedEvent, _selectedContactIds);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Événement modifié avec succès'),
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
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

/// Widget pour sélectionner une date
class _DatePickerTile extends StatelessWidget {
  final String label;
  final DateTime date;
  final DateTime? minDate;
  final ValueChanged<DateTime> onDateSelected;

  const _DatePickerTile({
    required this.label,
    required this.date,
    required this.onDateSelected,
    this.minDate,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE d MMMM yyyy', 'fr_FR');

    return InkWell(
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: minDate ?? DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
          locale: const Locale('fr', 'FR'),
        );

        if (pickedDate != null) {
          onDateSelected(pickedDate);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Colors.grey),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateFormat.format(date),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}

/// Widget pour sélectionner des contacts
class _ContactsSelector extends StatelessWidget {
  final List<int> selectedContactIds;
  final ValueChanged<List<int>> onContactsChanged;

  const _ContactsSelector({
    required this.selectedContactIds,
    required this.onContactsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ContactsProvider>(
      builder: (context, provider, child) {
        final contacts = provider.contacts;

        if (contacts.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Aucun contact disponible.\nAjoutez d\'abord des contacts depuis l\'écran principal.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return Container(
          constraints: const BoxConstraints(maxHeight: 200),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              final contact = contacts[index];
              final isSelected = selectedContactIds.contains(contact.id);

              return CheckboxListTile(
                title: Text(contact.contactName),
                subtitle: Text(contact.category.displayName),
                value: isSelected,
                onChanged: (value) {
                  final updatedIds = List<int>.from(selectedContactIds);
                  if (value == true && contact.id != null) {
                    updatedIds.add(contact.id!);
                  } else {
                    updatedIds.remove(contact.id);
                  }
                  onContactsChanged(updatedIds);
                },
              );
            },
          ),
        );
      },
    );
  }
}