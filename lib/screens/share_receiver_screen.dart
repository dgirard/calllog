import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tracked_contact.dart';
import '../models/contact_note.dart';
import '../models/enums.dart';
import '../providers/contacts_provider.dart';

/// Écran pour sélectionner un contact et attacher le texte partagé comme transcript
class ShareReceiverScreen extends StatefulWidget {
  final String sharedText;

  const ShareReceiverScreen({super.key, required this.sharedText});

  @override
  State<ShareReceiverScreen> createState() => _ShareReceiverScreenState();
}

class _ShareReceiverScreenState extends State<ShareReceiverScreen> {
  TrackedContact? _selectedContact;
  bool _isSaving = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attacher le transcript à un contact'),
      ),
      body: Column(
        children: [
          // Aperçu du texte partagé
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.text_snippet, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'Transcript reçu (${widget.sharedText.length} caractères)',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.sharedText.length > 200
                      ? '${widget.sharedText.substring(0, 200)}...'
                      : widget.sharedText,
                  style: const TextStyle(fontSize: 14),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Instructions
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Sélectionnez un contact pour attacher ce transcript :',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),

          const SizedBox(height: 16),

          // Barre de recherche
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un contact...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          const SizedBox(height: 16),

          // Liste des contacts
          Expanded(
            child: Consumer<ContactsProvider>(
              builder: (context, provider, child) {
                // Filtrer les contacts selon la recherche
                final allContacts = provider.contacts;
                final contacts = _searchQuery.isEmpty
                    ? allContacts
                    : allContacts.where((contact) {
                        return contact.contactName.toLowerCase().contains(_searchQuery) ||
                               contact.contactPhone.contains(_searchQuery);
                      }).toList();

                if (contacts.isEmpty) {
                  return Center(
                    child: Text(
                      _searchQuery.isEmpty
                          ? 'Aucun contact suivi disponible'
                          : 'Aucun contact trouvé pour "$_searchQuery"',
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: contacts.length,
                  itemBuilder: (context, index) {
                    final contact = contacts[index];
                    final isSelected = _selectedContact?.id == contact.id;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      color: isSelected ? Colors.blue.shade100 : null,
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            contact.contactName[0].toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          contact.contactName,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(contact.contactPhone),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle, color: Colors.blue)
                            : null,
                        onTap: () {
                          setState(() {
                            _selectedContact = contact;
                          });
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Bouton de sauvegarde
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _selectedContact == null || _isSaving
                      ? null
                      : _saveTranscript,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? 'Enregistrement...' : 'Enregistrer le transcript'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveTranscript() async {
    if (_selectedContact == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final provider = Provider.of<ContactsProvider>(context, listen: false);

      // Créer une note de type transcript
      final note = ContactNote(
        trackedContactId: _selectedContact!.id!,
        content: widget.sharedText,
        category: NoteCategory.transcript,
        importance: NoteImportance.medium,
        isPinned: false,
        isActionItem: false,
        createdAt: DateTime.now(),
      );

      await provider.addNote(_selectedContact!.id!, note);

      if (mounted) {
        // Afficher un message de succès
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '📝 Transcript ajouté à ${_selectedContact!.contactName}',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Fermer cet écran et naviguer vers la fiche du contact
        Navigator.of(context).pop();
        Navigator.of(context).pushReplacementNamed(
          '/contact-detail',
          arguments: _selectedContact!.id!,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}
