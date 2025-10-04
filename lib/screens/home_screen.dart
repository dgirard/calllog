import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/contacts_provider.dart';
import '../providers/filters_provider.dart';
import '../services/communication_service.dart';
import '../services/call_log_service.dart';
import '../widgets/contact_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/filter_chips.dart';
import '../models/enums.dart';

/// Écran d'accueil affichant la liste des contacts
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CommunicationService _communicationService = CommunicationService();
  final CallLogService _callLogService = CallLogService();

  @override
  void initState() {
    super.initState();
    // Charger les contacts au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    // Charger les contacts
    await context.read<ContactsProvider>().loadContacts();

    // Synchroniser les appels en arrière-plan
    _syncCallsInBackground();
  }

  Future<void> _syncCallsInBackground() async {
    try {
      // Synchroniser depuis les 30 derniers jours
      final synced = await _callLogService.syncCallsWithTrackedContacts(
        since: DateTime.now().subtract(const Duration(days: 30)),
      );

      if (synced > 0 && mounted) {
        // Recharger les contacts pour afficher les mises à jour
        await context.read<ContactsProvider>().loadContacts();

        // Afficher une notification discrète
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$synced appel(s) synchronisé(s)'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Erreur silencieuse, ne pas déranger l'utilisateur
    }
  }

  Future<void> _refreshContacts() async {
    await context.read<ContactsProvider>().loadContacts();
  }

  void _handleCallTap(int contactId, String phoneNumber) async {
    try {
      await _communicationService.makeCallAndRecord(
        contactId,
        phoneNumber,
        context: ContactContext.normal,
      );
      // Recharger les contacts pour mettre à jour la liste
      if (mounted) {
        await context.read<ContactsProvider>().loadContacts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  void _handleSmsTap(int contactId, String phoneNumber) async {
    try {
      await _communicationService.sendSmsAndRecord(
        contactId,
        phoneNumber,
        context: ContactContext.normal,
      );
      // Recharger les contacts
      if (mounted) {
        await context.read<ContactsProvider>().loadContacts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CallLog'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            tooltip: 'Paramètres',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshContacts,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Consumer2<ContactsProvider, FiltersProvider>(
        builder: (context, contactsProvider, filtersProvider, child) {
          if (contactsProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (contactsProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Erreur: ${contactsProvider.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshContacts,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          // Appliquer les filtres
          final sortedContacts = contactsProvider.getSortedContacts();
          final filteredContacts = filtersProvider.applyFilters(sortedContacts);

          return Column(
            children: [
              // Chips de filtrage - TOUJOURS VISIBLES
              const FilterChips(),

              // Contenu principal
              Expanded(
                child: filteredContacts.isEmpty
                    ? EmptyState(
                        icon: contactsProvider.contacts.isEmpty
                            ? Icons.contacts_outlined
                            : Icons.filter_alt_off_outlined,
                        title: contactsProvider.contacts.isEmpty
                            ? 'Aucun contact suivi'
                            : 'Aucun contact correspondant',
                        message: contactsProvider.contacts.isEmpty
                            ? 'Ajoutez votre premier contact pour commencer !'
                            : 'Modifiez vos filtres pour voir plus de contacts',
                        actionLabel: contactsProvider.contacts.isEmpty
                            ? 'Ajouter un contact'
                            : null,
                        onActionPressed: contactsProvider.contacts.isEmpty
                            ? () => Navigator.pushNamed(context, '/add-contact')
                            : null,
                      )
                    : RefreshIndicator(
                        onRefresh: _refreshContacts,
                        child: ListView.builder(
                          itemCount: filteredContacts.length,
                          itemBuilder: (context, index) {
                            final contact = filteredContacts[index];
                            return ContactCard(
                              contact: contact,
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/contact-detail',
                                  arguments: contact.id,
                                );
                              },
                              onCallTap: () => _handleCallTap(
                                contact.id!,
                                contact.contactPhone,
                              ),
                              onSmsTap: () => _handleSmsTap(
                                contact.id!,
                                contact.contactPhone,
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/add-contact'),
        tooltip: 'Ajouter un contact',
        child: const Icon(Icons.add),
      ),
    );
  }
}
