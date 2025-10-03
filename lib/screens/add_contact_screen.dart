import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../models/enums.dart';
import '../models/tracked_contact.dart';
import '../providers/contacts_provider.dart';
import '../services/contacts_service.dart';
import '../services/permission_service.dart';

/// Écran d'ajout d'un nouveau contact suivi
class AddContactScreen extends StatefulWidget {
  const AddContactScreen({super.key});

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final ContactsService _contactsService = ContactsService();
  final PermissionService _permissionService = PermissionService();

  // Contact sélectionné depuis Android
  Contact? _selectedContact;
  String? _selectedPhoneNumber;

  // Champs du formulaire
  CallFrequency _selectedFrequency = CallFrequency.weekly;
  ContactCategory _selectedCategory = ContactCategory.friends;
  DateTime? _birthday;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await _permissionService.requestContactsPermission();
  }

  Future<void> _selectContact() async {
    setState(() => _isLoading = true);

    try {
      final hasPermission = await _permissionService.requestContactsPermission();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permission d\'accès aux contacts requise'),
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      final contacts = await _contactsService.getAllContacts();
      if (!mounted) return;

      // Afficher le sélecteur de contact
      final selectedContact = await showDialog<Contact>(
        context: context,
        builder: (context) => _ContactPickerDialog(contacts: contacts),
      );

      if (selectedContact != null && mounted) {
        // Si le contact a plusieurs numéros, demander lequel utiliser
        String? phoneNumber;
        if (selectedContact.phones.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ce contact n\'a pas de numéro de téléphone'),
            ),
          );
          setState(() => _isLoading = false);
          return;
        } else if (selectedContact.phones.length == 1) {
          phoneNumber = selectedContact.phones.first.number;
        } else {
          phoneNumber = await showDialog<String>(
            context: context,
            builder: (context) => _PhonePickerDialog(
              phones: selectedContact.phones,
            ),
          );
        }

        if (phoneNumber != null) {
          // Récupérer l'anniversaire si disponible
          final birthday = _contactsService.getContactBirthday(selectedContact);

          setState(() {
            _selectedContact = selectedContact;
            _selectedPhoneNumber = phoneNumber;
            _birthday = birthday;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
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
      setState(() {
        _birthday = selectedDate;
      });
    }
  }

  Future<void> _saveContact() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedContact == null || _selectedPhoneNumber == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un contact'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final newContact = TrackedContact(
        contactId: _selectedContact!.id,
        contactName: _selectedContact!.displayName,
        contactPhone: _selectedPhoneNumber!,
        frequency: _selectedFrequency,
        category: _selectedCategory,
        lastContactDate: DateTime.now(),
        birthday: _birthday,
      );

      await context.read<ContactsProvider>().addContact(newContact);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contact ajouté avec succès'),
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un contact'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Sélection du contact
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(
                          _selectedContact?.displayName ?? 'Sélectionner un contact',
                        ),
                        subtitle: _selectedPhoneNumber != null
                            ? Text(_selectedPhoneNumber!)
                            : const Text('Aucun contact sélectionné'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: _selectContact,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Fréquence
                    const Text(
                      'Fréquence de contact',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<CallFrequency>(
                      value: _selectedFrequency,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.schedule),
                      ),
                      items: CallFrequency.values.map((frequency) {
                        return DropdownMenuItem(
                          value: frequency,
                          child: Text(frequency.displayName),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedFrequency = value);
                        }
                      },
                    ),

                    const SizedBox(height: 24),

                    // Catégorie
                    const Text(
                      'Catégorie',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<ContactCategory>(
                      segments: ContactCategory.values.map((category) {
                        return ButtonSegment(
                          value: category,
                          label: Text(category.displayName),
                          icon: Icon(_getCategoryIcon(category)),
                        );
                      }).toList(),
                      selected: {_selectedCategory},
                      onSelectionChanged: (Set<ContactCategory> selected) {
                        setState(() => _selectedCategory = selected.first);
                      },
                    ),

                    const SizedBox(height: 24),

                    // Anniversaire
                    const Text(
                      'Date d\'anniversaire (optionnel)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.cake),
                        title: Text(
                          _birthday != null
                              ? '${_birthday!.day.toString().padLeft(2, '0')}/${_birthday!.month.toString().padLeft(2, '0')}/${_birthday!.year}'
                              : 'Aucune date sélectionnée',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_birthday != null)
                              IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () {
                                  setState(() => _birthday = null);
                                },
                              ),
                            const Icon(Icons.calendar_today, size: 16),
                          ],
                        ),
                        onTap: _selectBirthday,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Bouton Sauvegarder
                    ElevatedButton(
                      onPressed: _saveContact,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Ajouter le contact',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  IconData _getCategoryIcon(ContactCategory category) {
    switch (category) {
      case ContactCategory.family:
        return Icons.family_restroom;
      case ContactCategory.friends:
        return Icons.people;
      case ContactCategory.professional:
        return Icons.work;
    }
  }
}

/// Dialog pour sélectionner un contact
class _ContactPickerDialog extends StatefulWidget {
  final List<Contact> contacts;

  const _ContactPickerDialog({required this.contacts});

  @override
  State<_ContactPickerDialog> createState() => _ContactPickerDialogState();
}

class _ContactPickerDialogState extends State<_ContactPickerDialog> {
  String _searchQuery = '';
  late List<Contact> _filteredContacts;

  @override
  void initState() {
    super.initState();
    _filteredContacts = widget.contacts;
  }

  void _filterContacts(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _filteredContacts = widget.contacts.where((contact) {
        return contact.displayName.toLowerCase().contains(_searchQuery);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Rechercher un contact...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _filterContacts,
              autofocus: true,
            ),
          ),

          // Liste des contacts
          Expanded(
            child: _filteredContacts.isEmpty
                ? const Center(
                    child: Text('Aucun contact trouvé'),
                  )
                : ListView.builder(
                    itemCount: _filteredContacts.length,
                    itemBuilder: (context, index) {
                      final contact = _filteredContacts[index];
                      return ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.person),
                        ),
                        title: Text(contact.displayName),
                        subtitle: contact.phones.isNotEmpty
                            ? Text(contact.phones.first.number)
                            : const Text('Pas de numéro'),
                        onTap: () => Navigator.pop(context, contact),
                      );
                    },
                  ),
          ),

          // Bouton Annuler
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog pour sélectionner un numéro de téléphone
class _PhonePickerDialog extends StatelessWidget {
  final List<Phone> phones;

  const _PhonePickerDialog({required this.phones});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sélectionner un numéro'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: phones.map((phone) {
          return ListTile(
            leading: const Icon(Icons.phone),
            title: Text(phone.number),
            subtitle: Text(phone.label.name),
            onTap: () => Navigator.pop(context, phone.number),
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
      ],
    );
  }
}
