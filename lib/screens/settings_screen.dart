import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/backup_service.dart';
import '../services/call_log_service.dart';
import '../services/database_service.dart';
import '../providers/anonymity_provider.dart';

/// Écran des paramètres
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final BackupService _backupService = BackupService();
  final CallLogService _callLogService = CallLogService();
  final DatabaseService _databaseService = DatabaseService();
  bool _isLoading = false;
  Map<String, int>? _stats;
  DateTime? _lastSyncTime;
  int _syncDays = 30;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await _backupService.getBackupStats();
    setState(() => _stats = stats);
  }

  Future<void> _exportData() async {
    setState(() => _isLoading = true);

    try {
      final filePath = await _backupService.saveToFile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Données exportées vers:\n$filePath'),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'export: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _importData() async {
    // Confirmer l'import
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Importer des données'),
        content: const Text(
          'L\'import va ajouter les contacts du fichier à vos données existantes.\n\nContinuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Importer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await _backupService.importFromFile();
      await _loadStats();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Données importées avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'import: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _syncCalls() async {
    setState(() => _isLoading = true);

    try {
      final synced = await _callLogService.syncCallsWithTrackedContacts(
        since: DateTime.now().subtract(Duration(days: _syncDays)),
      );

      setState(() => _lastSyncTime = DateTime.now());
      await _loadStats();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$synced appel(s) synchronisé(s)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la synchronisation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cleanupDuplicates() async {
    setState(() => _isLoading = true);

    try {
      final deleted = await _databaseService.cleanupDuplicates();
      await _loadStats();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$deleted doublon(s) supprimé(s)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du nettoyage: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _clearAllHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Effacer tout l\'historique ?'),
        content: const Text(
          'Cela va supprimer TOUT l\'historique de contacts pour TOUS les contacts suivis.\n\n'
          'Vous pourrez ensuite resynchroniser les appels avec les bonnes dates.\n\n'
          'Cette action est irréversible. Continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Effacer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final contacts = await _databaseService.getContacts();
      int totalDeleted = 0;

      for (var contact in contacts) {
        if (contact.id != null) {
          final deleted = await _databaseService.deleteContactHistory(contact.id!);
          totalDeleted += deleted;
        }
      }

      await _loadStats();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$totalDeleted entrée(s) supprimée(s)'),
            backgroundColor: Colors.green,
          ),
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
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // Section Synchronisation
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Synchronisation des appels',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Dernière synchronisation
                if (_lastSyncTime != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Dernière sync: ${_lastSyncTime!.day}/${_lastSyncTime!.month} à ${_lastSyncTime!.hour}:${_lastSyncTime!.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ),

                // Bouton synchroniser
                ListTile(
                  leading: const Icon(Icons.sync, color: Colors.blue),
                  title: const Text('Synchroniser maintenant'),
                  subtitle: Text('Analyser les $_syncDays derniers jours'),
                  onTap: _syncCalls,
                  trailing: const Icon(Icons.chevron_right),
                ),

                // Période de synchronisation
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Période de synchronisation'),
                  subtitle: Text('$_syncDays jours'),
                  trailing: DropdownButton<int>(
                    value: _syncDays,
                    items: const [
                      DropdownMenuItem(value: 7, child: Text('7 jours')),
                      DropdownMenuItem(value: 14, child: Text('14 jours')),
                      DropdownMenuItem(value: 30, child: Text('30 jours')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _syncDays = value);
                      }
                    },
                  ),
                ),

                // Nettoyer les doublons
                ListTile(
                  leading: const Icon(Icons.cleaning_services, color: Colors.orange),
                  title: const Text('Nettoyer les doublons'),
                  subtitle: const Text('Supprimer les entrées en double dans l\'historique'),
                  onTap: _cleanupDuplicates,
                  trailing: const Icon(Icons.chevron_right),
                ),

                // Effacer tout l'historique
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text('Effacer tout l\'historique'),
                  subtitle: const Text('Supprimer toutes les entrées pour resynchroniser'),
                  onTap: _clearAllHistory,
                  trailing: const Icon(Icons.chevron_right),
                ),

                const Divider(),

                // Section Sauvegarde
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Sauvegarde et restauration',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Statistiques
                if (_stats != null)
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.info_outline, size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Données actuelles',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  Text(
                                    '${_stats!['contacts']}',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text(
                                    'Contacts',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  Text(
                                    '${_stats!['records']}',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text(
                                    'Interactions',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                // Export
                ListTile(
                  leading: const Icon(Icons.upload_file, color: Colors.blue),
                  title: const Text('Exporter les données'),
                  subtitle: const Text('Sauvegarde au format JSON'),
                  onTap: _exportData,
                  trailing: const Icon(Icons.chevron_right),
                ),

                const Divider(),

                // Import
                ListTile(
                  leading: const Icon(Icons.download, color: Colors.green),
                  title: const Text('Importer des données'),
                  subtitle: const Text('Depuis un fichier JSON'),
                  onTap: _importData,
                  trailing: const Icon(Icons.chevron_right),
                ),

                const SizedBox(height: 16),

                // Info sur backup automatique
                Card(
                  margin: const EdgeInsets.all(16),
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.cloud_done, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'Backup automatique activé',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Vos données sont automatiquement sauvegardées par Android. '
                          'Lors d\'une mise à jour de l\'application, vos contacts seront conservés.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Mode anonyme
                const Divider(),
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Mode démonstration',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                Consumer<AnonymityProvider>(
                  builder: (context, anonymityProvider, child) {
                    return SwitchListTile(
                      secondary: const Icon(Icons.privacy_tip, color: Colors.purple),
                      title: const Text('Mode anonyme'),
                      subtitle: const Text('Masquer noms et numéros pour démo/vidéo'),
                      value: anonymityProvider.isAnonymousModeEnabled,
                      onChanged: (bool value) {
                        anonymityProvider.setAnonymousMode(value);
                      },
                    );
                  },
                ),

                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.purple.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.purple.shade700, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'À quoi sert le mode anonyme ?',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.purple.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Active ce mode pour faire des captures d\'écran ou vidéos de démo. '
                          'Les noms de famille seront remplacés par des ******, et les 4 derniers chiffres '
                          'des numéros de téléphone seront masqués.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // À propos
                const Divider(),
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'À propos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Version'),
                  subtitle: const Text('1.0.1'),
                ),

                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('CallLog'),
                  subtitle: const Text('Gestionnaire de contacts'),
                ),
              ],
            ),
    );
  }
}
