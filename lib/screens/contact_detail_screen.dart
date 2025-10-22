import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/tracked_contact.dart';
import '../models/contact_record.dart';
import '../models/contact_note.dart';
import '../models/enums.dart';
import '../providers/contacts_provider.dart';
import '../providers/anonymity_provider.dart';
import '../services/communication_service.dart';
import '../services/database_service.dart';
import '../services/audio_recording_service.dart';
import '../services/transcription_service.dart';
import '../utils/priority_calculator.dart';
import '../utils/date_utils.dart' as app_date_utils;
import '../utils/birthday_utils.dart';
import '../utils/anonymization_utils.dart';
import '../widgets/priority_indicator.dart';
import '../widgets/note_dialog.dart';

/// Écran de détails d'un contact suivi
class ContactDetailScreen extends StatefulWidget {
  final int contactId;

  const ContactDetailScreen({
    super.key,
    required this.contactId,
  });

  @override
  State<ContactDetailScreen> createState() => _ContactDetailScreenState();
}

class _ContactDetailScreenState extends State<ContactDetailScreen> {
  final CommunicationService _communicationService = CommunicationService();
  final DatabaseService _databaseService = DatabaseService();
  final AudioRecordingService _audioService = AudioRecordingService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _playingAudioPath;
  bool _isPlaying = false;

  TrackedContact? _contact;
  List<ContactRecord> _history = [];
  List<ContactNote> _notes = [];
  bool _isLoading = true;
  bool _isRecording = false;
  Timer? _recordingTimer;
  Duration _recordingDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadContactDetails();
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _audioService.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadContactDetails() async {
    setState(() => _isLoading = true);

    try {
      final contact = await _databaseService.getTrackedContactById(widget.contactId);
      final history = await _databaseService.getContactHistory(widget.contactId);
      final notes = await _databaseService.getNotes(widget.contactId);

      if (mounted) {
        setState(() {
          _contact = contact;
          _history = history;
          _notes = notes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _handleCallTap() async {
    if (_contact == null) return;

    try {
      await _communicationService.makeCallAndRecord(
        _contact!.id!,
        _contact!.contactPhone,
        context: ContactContext.normal,
      );
      await _loadContactDetails();
      if (mounted) {
        context.read<ContactsProvider>().loadContacts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _handleSmsTap() async {
    if (_contact == null) return;

    try {
      await _communicationService.sendSmsAndRecord(
        _contact!.id!,
        _contact!.contactPhone,
        context: ContactContext.normal,
      );
      await _loadContactDetails();
      if (mounted) {
        context.read<ContactsProvider>().loadContacts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _handleSkip() async {
    if (_contact == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Marquer comme contacté ?'),
        content: const Text(
          'Cela va mettre à jour la date de dernier contact sans appeler.\n\nUtile si vous vous êtes vu en personne.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Enregistrer un contact "autre"
        await _databaseService.recordContact(
          trackedContactId: _contact!.id!,
          contactMethod: ContactMethod.other,
          context: ContactContext.normal,
        );

        // Mettre à jour la date de dernier contact
        final updated = TrackedContact(
          id: _contact!.id,
          contactId: _contact!.contactId,
          contactName: _contact!.contactName,
          contactPhone: _contact!.contactPhone,
          frequency: _contact!.frequency,
          category: _contact!.category,
          lastContactDate: DateTime.now(),
          birthday: _contact!.birthday,
          createdAt: _contact!.createdAt,
          updatedAt: DateTime.now(),
        );
        await _databaseService.updateTrackedContact(updated);

        await _loadContactDetails();
        if (mounted) {
          context.read<ContactsProvider>().loadContacts();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contact marqué comme effectué'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    }
  }

  Future<void> _handleBirthdaySmsTap() async {
    if (_contact == null) return;

    try {
      final firstName = _contact!.contactName.split(' ').first;
      await _communicationService.sendBirthdaySms(
        _contact!.contactPhone,
        firstName,
      );
      await _databaseService.recordContact(
        trackedContactId: _contact!.id!,
        contactMethod: ContactMethod.sms,
        context: ContactContext.birthday,
      );
      await _loadContactDetails();
      if (mounted) {
        context.read<ContactsProvider>().loadContacts();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SMS d\'anniversaire envoyé !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _editContact() async {
    if (_contact == null) return;

    final result = await showDialog<TrackedContact>(
      context: context,
      builder: (context) => _EditContactDialog(contact: _contact!),
    );

    if (result != null) {
      try {
        await _databaseService.updateTrackedContact(result);
        await _loadContactDetails();
        if (mounted) {
          context.read<ContactsProvider>().loadContacts();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contact mis à jour'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    }
  }

  Future<void> _resetLastContact() async {
    if (_contact == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Réinitialiser le dernier contact ?'),
        content: const Text(
          'Cela va effacer la date du dernier contact. Le contact apparaîtra comme "Jamais contacté".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Créer un nouveau contact avec lastContactDate à null
        final updated = TrackedContact(
          id: _contact!.id,
          contactId: _contact!.contactId,
          contactName: _contact!.contactName,
          contactPhone: _contact!.contactPhone,
          frequency: _contact!.frequency,
          category: _contact!.category,
          lastContactDate: null, // Réinitialiser à null
          birthday: _contact!.birthday,
          createdAt: _contact!.createdAt,
          updatedAt: DateTime.now(),
        );
        await _databaseService.updateTrackedContact(updated);
        await _loadContactDetails();
        if (mounted) {
          context.read<ContactsProvider>().loadContacts();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dernier contact réinitialisé'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    }
  }

  Future<void> _addNote() async {
    if (_contact == null) return;

    final result = await showDialog<NoteDialogResult>(
      context: context,
      builder: (context) => const NoteDialog(),
    );

    if (result != null) {
      try {
        final note = ContactNote(
          trackedContactId: _contact!.id!,
          content: result.content,
          category: result.category,
          importance: result.importance,
          isPinned: result.isPinned,
          isActionItem: result.isActionItem,
          dueDate: result.dueDate,
          createdAt: DateTime.now(),
        );

        await _databaseService.insertNote(note);
        await _loadContactDetails();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Note ajoutée'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    }
  }

  Future<void> _editNote(ContactNote note) async {
    final result = await showDialog<NoteDialogResult>(
      context: context,
      builder: (context) => NoteDialog(note: note),
    );

    if (result != null) {
      try {
        final updatedNote = note.copyWith(
          content: result.content,
          category: result.category,
          importance: result.importance,
          isPinned: result.isPinned,
          isActionItem: result.isActionItem,
          dueDate: result.dueDate,
          updatedAt: DateTime.now(),
        );

        await _databaseService.updateNote(updatedNote);
        await _loadContactDetails();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Note modifiée'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    }
  }

  Future<void> _viewNoteFullscreen(ContactNote note) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(note.category.icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Expanded(child: Text(note.category.displayName)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Text(note.content),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _editNote(note);
            },
            child: const Text('Modifier'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteNote(ContactNote note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la note ?'),
        content: const Text('Cette action est irréversible.'),
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
      ),
    );

    if (confirmed == true && note.id != null) {
      try {
        await _databaseService.deleteNote(note.id!);
        await _loadContactDetails();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Note supprimée'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteContact() async {
    if (_contact == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le contact ?'),
        content: Text(
          'Voulez-vous vraiment supprimer ${_contact!.contactName} de vos contacts suivis ?\n\nL\'historique sera également supprimé.',
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
      ),
    );

    if (confirmed == true) {
      try {
        await context.read<ContactsProvider>().deleteContact(widget.contactId);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contact supprimé'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    }
  }

  Future<void> _startRecording() async {
    if (_contact == null) return;

    final result = await _audioService.startRecording(contactId: _contact!.id!);

    if (result.isSuccess) {
      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
      });

      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        final duration = _audioService.getCurrentDuration();
        if (duration != null && mounted) {
          setState(() {
            _recordingDuration = duration;
          });
        }
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error!.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    if (_contact == null) return;

    _recordingTimer?.cancel();

    final result = await _audioService.stopRecording();

    if (result.isSuccess) {
      setState(() {
        _isRecording = false;
        _recordingDuration = Duration.zero;
      });

      final metadata = result.data!;

      // Afficher un message de traitement
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enregistrement sauvegardé, transcription en cours...'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Lancer la transcription en arrière-plan
      String noteContent = 'Enregistrement audio (${_formatDuration(metadata.duration)})';

      // Vérifier si la transcription est configurée
      final isConfigured = await TranscriptionService.isConfigured();
      if (isConfigured) {
        // Transcrire l'audio
        final transcription = await TranscriptionService.transcribeAudio(metadata.path);

        if (transcription != null && transcription.isNotEmpty) {
          noteContent = transcription;

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✓ Transcription réussie !'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          noteContent = 'Enregistrement audio (${_formatDuration(metadata.duration)})\n\n⚠️ Transcription impossible\n\nFichier: ${metadata.path}';

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Transcription échouée - Audio sauvegardé'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      } else {
        noteContent = 'Enregistrement audio (${_formatDuration(metadata.duration)})\n\nℹ️ Transcription non configurée\n\nConfigurez une clé API Gemini dans les paramètres pour activer la transcription automatique.\n\nFichier: ${metadata.path}';

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Audio sauvegardé - Configurez Gemini pour la transcription'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }

      // Créer une note de type transcript avec le contenu (transcrit ou non)
      final note = ContactNote(
        trackedContactId: _contact!.id!,
        content: noteContent,
        audioPath: metadata.path,
        category: NoteCategory.transcript,
        importance: NoteImportance.medium,
        isPinned: false,
        isActionItem: false,
        createdAt: metadata.createdAt,
      );

      await context.read<ContactsProvider>().addNote(_contact!.id!, note);
      await _loadContactDetails();
    } else {
      setState(() {
        _isRecording = false;
        _recordingDuration = Duration.zero;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error!.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Future<void> _toggleAudioPlayback(String audioPath) async {
    try {
      if (_playingAudioPath == audioPath && _isPlaying) {
        // Pause si on joue déjà ce fichier
        await _audioPlayer.pause();
        setState(() {
          _isPlaying = false;
        });
      } else if (_playingAudioPath == audioPath && !_isPlaying) {
        // Resume si c'est le même fichier en pause
        await _audioPlayer.resume();
        setState(() {
          _isPlaying = true;
        });
      } else {
        // Nouveau fichier
        await _audioPlayer.stop();
        await _audioPlayer.play(DeviceFileSource(audioPath));
        setState(() {
          _playingAudioPath = audioPath;
          _isPlaying = true;
        });

        // Écouter la fin de lecture
        _audioPlayer.onPlayerComplete.listen((_) {
          if (mounted) {
            setState(() {
              _isPlaying = false;
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de lecture: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chargement...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_contact == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Erreur')),
        body: const Center(child: Text('Contact introuvable')),
      );
    }

    final priority = calculatePriority(_contact!);
    final isBirthday = isBirthdayToday(_contact!.birthday);
    final birthdayCountdown = getBirthdayCountdownText(_contact!.birthday);

    final anonymityProvider = context.watch<AnonymityProvider>();
    final isAnonymous = anonymityProvider.isAnonymousModeEnabled;

    // Anonymiser si mode activé
    final displayName = isAnonymous
        ? anonymizeName(_contact!.contactName)
        : _contact!.contactName;
    final displayPhone = isAnonymous
        ? anonymizePhoneNumber(_contact!.contactPhone)
        : _contact!.contactPhone;

    return Scaffold(
      appBar: AppBar(
        title: Text(displayName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editContact,
            tooltip: 'Modifier',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteContact,
            tooltip: 'Supprimer',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadContactDetails,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // En-tête du contact
              Container(
                padding: const EdgeInsets.all(24),
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                child: Column(
                  children: [
                    // Avatar
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Text(
                        displayName[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Nom
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    // Numéro
                    const SizedBox(height: 4),
                    Text(
                      displayPhone,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),

                    // Priorité
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        PriorityIndicator(priority: priority, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          priority.displayName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    // Badge anniversaire
                    if (isBirthday || birthdayCountdown.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.pink.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🎂', style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            Text(
                              birthdayCountdown.isEmpty
                                  ? 'Anniversaire aujourd\'hui !'
                                  : birthdayCountdown,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.pink.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Boutons d'action
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _handleCallTap,
                            icon: const Icon(Icons.phone),
                            label: const Text('Appeler'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _handleSmsTap,
                            icon: const Icon(Icons.message),
                            label: const Text('SMS'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Bouton d'enregistrement audio
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isRecording ? _stopRecording : _startRecording,
                        icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                        label: Text(
                          _isRecording
                            ? 'Arrêter l\'enregistrement (${_formatDuration(_recordingDuration)})'
                            : 'Enregistrer un mémo audio',
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: _isRecording ? Colors.red : Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _handleSkip,
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Marquer comme contacté'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Bouton SMS anniversaire si c'est bientôt
              if (isBirthday || birthdayCountdown.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton.icon(
                    onPressed: _handleBirthdaySmsTap,
                    icon: const Icon(Icons.cake),
                    label: const Text('Envoyer SMS d\'anniversaire'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Informations
              _InfoSection(
                contact: _contact!,
                onResetLastContact: _resetLastContact,
              ),

              const SizedBox(height: 16),

              // Notes
              _NotesSection(
                notes: _notes,
                onAddNote: _addNote,
                onEditNote: _editNote,
                onDeleteNote: _deleteNote,
                onViewNote: _viewNoteFullscreen,
              ),

              const SizedBox(height: 16),

              // Historique
              _HistorySection(history: _history),
            ],
          ),
        ),
      ),
    );
  }
}

/// Section d'informations du contact
class _InfoSection extends StatelessWidget {
  final TrackedContact contact;
  final VoidCallback onResetLastContact;

  const _InfoSection({
    required this.contact,
    required this.onResetLastContact,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _InfoRow(
              icon: Icons.schedule,
              label: 'Fréquence',
              value: contact.frequency.displayName,
            ),
            const Divider(),
            _InfoRow(
              icon: Icons.category,
              label: 'Catégorie',
              value: contact.category.displayName,
            ),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: _InfoRow(
                    icon: Icons.access_time,
                    label: 'Dernier contact',
                    value: app_date_utils.getRelativeDateText(contact.lastContactDate),
                  ),
                ),
                if (contact.lastContactDate != null)
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    tooltip: 'Réinitialiser',
                    onPressed: onResetLastContact,
                  ),
              ],
            ),
            if (contact.birthday != null) ...[
              const Divider(),
              _InfoRow(
                icon: Icons.cake,
                label: 'Anniversaire',
                value:
                    '${contact.birthday!.day.toString().padLeft(2, '0')}/${contact.birthday!.month.toString().padLeft(2, '0')}/${contact.birthday!.year}',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget pour une ligne d'information
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Section d'historique des contacts
class _HistorySection extends StatelessWidget {
  final List<ContactRecord> history;

  const _HistorySection({required this.history});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Historique (${history.length})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (history.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'Aucun contact enregistré',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...history.map((record) {
                final isBirthday = record.context == ContactContext.birthday;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: record.contactMethod == ContactMethod.call
                        ? Colors.green.shade100
                        : Colors.blue.shade100,
                    child: Icon(
                      record.contactMethod == ContactMethod.call
                          ? Icons.phone
                          : Icons.message,
                      color: record.contactMethod == ContactMethod.call
                          ? Colors.green
                          : Colors.blue,
                    ),
                  ),
                  title: Text(
                    record.contactMethod == ContactMethod.call
                        ? 'Appel téléphonique'
                        : 'SMS',
                  ),
                  subtitle: Text(
                    app_date_utils.getRelativeDateText(record.contactDate),
                  ),
                  trailing: isBirthday
                      ? const Text('🎂', style: TextStyle(fontSize: 20))
                      : null,
                );
              }),
          ],
        ),
      ),
    );
  }
}

/// Dialog d'édition du contact
class _EditContactDialog extends StatefulWidget {
  final TrackedContact contact;

  const _EditContactDialog({required this.contact});

  @override
  State<_EditContactDialog> createState() => _EditContactDialogState();
}

class _EditContactDialogState extends State<_EditContactDialog> {
  late CallFrequency _frequency;
  late ContactCategory _category;
  late DateTime? _birthday;

  @override
  void initState() {
    super.initState();
    _frequency = widget.contact.frequency;
    _category = widget.contact.category;
    _birthday = widget.contact.birthday;
  }

  Future<void> _selectBirthday() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('fr', 'FR'),
      helpText: 'Sélectionner la date d\'anniversaire',
      cancelText: 'Annuler',
      confirmText: 'OK',
    );

    if (selectedDate != null) {
      setState(() => _birthday = selectedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Modifier le contact'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fréquence
            const Text(
              'Fréquence',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<CallFrequency>(
              value: _frequency,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: CallFrequency.values.map((freq) {
                return DropdownMenuItem(
                  value: freq,
                  child: Text(freq.displayName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _frequency = value);
                }
              },
            ),

            const SizedBox(height: 16),

            // Catégorie
            const Text(
              'Catégorie',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SegmentedButton<ContactCategory>(
              segments: ContactCategory.values.map((cat) {
                return ButtonSegment(
                  value: cat,
                  label: Text(cat.displayName),
                );
              }).toList(),
              selected: {_category},
              onSelectionChanged: (Set<ContactCategory> selected) {
                setState(() => _category = selected.first);
              },
            ),

            const SizedBox(height: 16),

            // Anniversaire
            const Text(
              'Anniversaire',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.cake),
              title: Text(
                _birthday != null
                    ? '${_birthday!.day.toString().padLeft(2, '0')}/${_birthday!.month.toString().padLeft(2, '0')}/${_birthday!.year}'
                    : 'Aucune date',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_birthday != null)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () => setState(() => _birthday = null),
                    ),
                  const Icon(Icons.calendar_today, size: 16),
                ],
              ),
              onTap: _selectBirthday,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: () {
            final updatedContact = widget.contact.copyWith(
              frequency: _frequency,
              category: _category,
              birthday: _birthday,
            );
            Navigator.pop(context, updatedContact);
          },
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}

/// Section des notes
class _NotesSection extends StatelessWidget {
  final List<ContactNote> notes;
  final VoidCallback onAddNote;
  final Function(ContactNote) onEditNote;
  final Function(ContactNote) onDeleteNote;
  final Function(ContactNote) onViewNote;

  const _NotesSection({
    required this.notes,
    required this.onAddNote,
    required this.onEditNote,
    required this.onDeleteNote,
    required this.onViewNote,
  });

  @override
  Widget build(BuildContext context) {
    final anonymityProvider = context.watch<AnonymityProvider>();
    final isAnonymous = anonymityProvider.isAnonymousModeEnabled;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notes (${notes.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.blue),
                  onPressed: onAddNote,
                  tooltip: 'Ajouter une note',
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (notes.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'Aucune note',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...notes.map((note) {
                // Anonymiser le contenu si mode activé
                final displayContent = isAnonymous
                    ? note.content.replaceAll(RegExp(r'[a-zA-ZÀ-ÿ]{3,}'), '****')
                    : note.content;

                // Déterminer si l'action est en retard
                final isOverdue = note.isActionItem &&
                    note.dueDate != null &&
                    note.dueDate!.isBefore(DateTime.now()) &&
                    !note.isCompleted;

                // Détecter les notes longues (transcripts)
                final isLongNote = note.category == NoteCategory.transcript || note.content.length > 200;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: note.isPinned
                      ? Colors.blue.shade50
                      : (note.isActionItem ? Colors.orange.shade50 : Colors.amber.shade50),
                  child: ListTile(
                    leading: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(note.category.icon, style: const TextStyle(fontSize: 24)),
                      ],
                    ),
                    onTap: isLongNote ? () => onViewNote(note) : null,
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayContent,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Badges
                        if (note.isPinned)
                          const Text('📌', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 4),
                        Text(note.importance.icon, style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              app_date_utils.getRelativeDateText(note.createdAt),
                              style: const TextStyle(fontSize: 12),
                            ),
                            if (isLongNote) ...[
                              const SizedBox(width: 8),
                              const Text(
                                '👁️ Appuyer pour lire',
                                style: TextStyle(fontSize: 11, color: Colors.blue),
                              ),
                            ],
                          ],
                        ),
                        if (note.isActionItem) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                note.isCompleted
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                size: 16,
                                color: note.isCompleted ? Colors.green : Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                note.dueDate != null
                                    ? 'Échéance: ${note.dueDate!.day}/${note.dueDate!.month}'
                                    : 'Pas d\'échéance',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isOverdue ? Colors.red : Colors.grey,
                                  fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              if (isOverdue)
                                const Text(
                                  ' ⚠️ En retard',
                                  style: TextStyle(fontSize: 11, color: Colors.red),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Bouton play si audioPath existe
                        if (note.audioPath != null)
                          IconButton(
                            icon: Icon(
                              note.audioPath == context.findAncestorStateOfType<_ContactDetailScreenState>()?._playingAudioPath &&
                                  context.findAncestorStateOfType<_ContactDetailScreenState>()?._isPlaying == true
                                  ? Icons.pause_circle
                                  : Icons.play_circle,
                              size: 28,
                              color: Colors.blue,
                            ),
                            onPressed: () {
                              context.findAncestorStateOfType<_ContactDetailScreenState>()?._toggleAudioPlayback(note.audioPath!);
                            },
                            tooltip: 'Écouter',
                          ),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () => onEditNote(note),
                          tooltip: 'Modifier',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                          onPressed: () => onDeleteNote(note),
                          tooltip: 'Supprimer',
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
