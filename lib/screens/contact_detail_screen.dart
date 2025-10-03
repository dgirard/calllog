import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tracked_contact.dart';
import '../models/contact_record.dart';
import '../models/enums.dart';
import '../providers/contacts_provider.dart';
import '../services/communication_service.dart';
import '../services/database_service.dart';
import '../utils/priority_calculator.dart';
import '../utils/date_utils.dart' as app_date_utils;
import '../utils/birthday_utils.dart';
import '../widgets/priority_indicator.dart';

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

  TrackedContact? _contact;
  List<ContactRecord> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContactDetails();
  }

  Future<void> _loadContactDetails() async {
    setState(() => _isLoading = true);

    try {
      final contact = await _databaseService.getTrackedContactById(widget.contactId);
      final history = await _databaseService.getContactHistory(widget.contactId);

      if (mounted) {
        setState(() {
          _contact = contact;
          _history = history;
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

    return Scaffold(
      appBar: AppBar(
        title: Text(_contact!.contactName),
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
                        _contact!.contactName[0].toUpperCase(),
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
                      _contact!.contactName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    // Numéro
                    const SizedBox(height: 4),
                    Text(
                      _contact!.contactPhone,
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
                child: Row(
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
              _InfoSection(contact: _contact!),

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

  const _InfoSection({required this.contact});

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
            _InfoRow(
              icon: Icons.access_time,
              label: 'Dernier contact',
              value: app_date_utils.getRelativeDateText(contact.lastContactDate),
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
