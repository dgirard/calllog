import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/event.dart';
import '../models/enums.dart';
import '../providers/events_provider.dart';
import '../providers/contacts_provider.dart';
import '../services/audio_recording_service.dart';
import '../services/transcription_service.dart';
import '../services/event_parsing_service.dart';

/// Écran pour ajouter un nouvel événement
class AddEventScreen extends StatefulWidget {
  final DateTime? initialDate;

  const AddEventScreen({
    super.key,
    this.initialDate,
  });

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  late DateTime _startDate;
  DateTime? _endDate;
  EventCategory _category = EventCategory.other;
  List<int> _selectedContactIds = [];

  bool _isLoading = false;
  bool _hasEndDate = false;

  // Audio related state
  final AudioRecordingService _audioService = AudioRecordingService();
  bool _isRecording = false;
  bool _isTranscribing = false;
  bool _isParsing = false;
  Timer? _recordingTimer;
  Duration _recordingDuration = Duration.zero;
  String? _audioTranscript;
  ParsedEventData? _parsedEventData;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvel événement'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Audio recording card
              _buildAudioRecordingCard(),

              const SizedBox(height: 16),

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

              // Catégorie
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Catégorie',
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

              // Bouton Créer
              ElevatedButton(
                onPressed: _isLoading ? null : _saveEvent,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Créer l\'événement',
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

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final event = Event(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        startDate: _startDate,
        endDate: _hasEndDate ? _endDate : null,
        category: _category,
        status: EventStatus.active,
      );

      await context.read<EventsProvider>().addEvent(event, _selectedContactIds);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Événement créé avec succès'),
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
        setState(() => _isLoading = false);
      }
    }
  }

  // ==================== AUDIO RECORDING METHODS ====================

  Widget _buildAudioRecordingCard() {
    return Card(
      color: _isRecording ? Colors.red[50] : Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              _isRecording ? Icons.mic : Icons.mic_none,
              size: 48,
              color: _isRecording ? Colors.red : Colors.blue,
            ),
            const SizedBox(height: 16),
            Text(
              _isRecording
                ? 'Enregistrement en cours...'
                : 'Décrivez votre événement à voix haute',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            if (_isRecording) ...[
              const SizedBox(height: 8),
              Text(
                _formatDuration(_recordingDuration),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: (_isTranscribing || _isParsing)
                ? null
                : (_isRecording ? _stopRecording : _startRecording),
              icon: Icon(_isRecording ? Icons.stop : Icons.mic),
              label: Text(
                _isRecording
                  ? 'Arrêter'
                  : 'Enregistrer',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isRecording ? Colors.red : Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            ),

            // Loading states
            if (_isTranscribing) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              const Text('Transcription en cours...'),
            ],
            if (_isParsing) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              const Text('Analyse de l\'événement...'),
            ],

            // Show transcript if available
            if (_audioTranscript != null && !_isParsing) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Transcription :',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _audioTranscript!,
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ],

            // Show parsed data success
            if (_parsedEventData != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Événement détecté ! Vérifiez les informations ci-dessous.',
                        style: TextStyle(
                          color: Colors.green[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _startRecording() async {
    // Check if API is configured
    final isConfigured = await TranscriptionService.isConfigured();
    if (!isConfigured) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configurez d\'abord la clé API Gemini dans les paramètres'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Generate a temporary ID for the recording (using large number as placeholder for event recording)
    final tempId = 999999;

    final result = await _audioService.startRecording(contactId: tempId);
    if (result.isFailure) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error!.message),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isRecording = true;
      _recordingDuration = Duration.zero;
      _audioTranscript = null;
      _parsedEventData = null;
    });

    // Start timer for recording duration
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _recordingDuration = Duration(seconds: timer.tick);
        });
      }
    });
  }

  Future<void> _stopRecording() async {
    _recordingTimer?.cancel();

    setState(() {
      _isRecording = false;
      _isTranscribing = true;
    });

    // Stop recording and get audio file
    final recordResult = await _audioService.stopRecording();
    if (recordResult.isFailure) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(recordResult.error!.message),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isTranscribing = false);
      }
      return;
    }

    final audioPath = recordResult.data!.path;

    // Transcribe audio
    final transcript = await TranscriptionService.transcribeAudio(audioPath);
    if (transcript == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transcription impossible. Vérifiez votre connexion.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isTranscribing = false);
      }
      return;
    }

    setState(() {
      _audioTranscript = transcript;
      _isTranscribing = false;
      _isParsing = true;
    });

    // Parse event data from transcript
    final parsedEvent = await EventParsingService.parseEventFromText(transcript);

    setState(() {
      _isParsing = false;
    });

    if (parsedEvent == null || parsedEvent.confidence < 0.3) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'extraire les détails. Essayez d\'être plus précis.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Pre-fill form with parsed data
    setState(() {
      _parsedEventData = parsedEvent;
      _titleController.text = parsedEvent.title;
      if (parsedEvent.description != null) {
        _descriptionController.text = parsedEvent.description!;
      }
      _startDate = parsedEvent.startDate;
      _endDate = parsedEvent.endDate;
      _hasEndDate = parsedEvent.endDate != null;
      _category = parsedEvent.category;
    });

    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Événement extrait avec ${(parsedEvent.confidence * 100).toStringAsFixed(0)}% de confiance',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '${duration.inMinutes}:$seconds';
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