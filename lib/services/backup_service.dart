import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'database_service.dart';
import '../models/tracked_contact.dart';
import '../models/contact_record.dart';

/// Service de sauvegarde et restauration des données
class BackupService {
  final DatabaseService _databaseService = DatabaseService();

  /// Exporte toutes les données en JSON
  Future<Map<String, dynamic>> exportData() async {
    try {
      // Récupérer tous les contacts
      final contacts = await _databaseService.getContacts();

      // Récupérer tout l'historique
      final Map<int, List<ContactRecord>> allHistory = {};
      for (var contact in contacts) {
        if (contact.id != null) {
          final history = await _databaseService.getContactHistory(contact.id!);
          allHistory[contact.id!] = history;
        }
      }

      // Créer la structure JSON
      return {
        'version': '1.0.0',
        'exportDate': DateTime.now().toIso8601String(),
        'contacts': contacts.map((c) => c.toMap()).toList(),
        'history': allHistory.map(
          (key, value) => MapEntry(
            key.toString(),
            value.map((r) => r.toMap()).toList(),
          ),
        ),
      };
    } catch (e) {
      throw Exception('Erreur lors de l\'export des données: $e');
    }
  }

  /// Sauvegarde les données dans un fichier JSON
  Future<String> saveToFile() async {
    try {
      // Exporter les données
      final data = await exportData();
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);

      // Obtenir le répertoire de téléchargements
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception('Impossible de trouver le répertoire de sauvegarde');
      }

      // Créer le nom de fichier avec date
      final timestamp = DateTime.now().toIso8601String().split('.')[0].replaceAll(':', '-');
      final fileName = 'calllog_backup_$timestamp.json';
      final filePath = '${directory.path}/$fileName';

      // Écrire le fichier
      final file = File(filePath);
      await file.writeAsString(jsonString);

      return filePath;
    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde: $e');
    }
  }

  /// Importe les données depuis un fichier JSON
  Future<void> importFromFile() async {
    try {
      // Sélectionner le fichier
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) {
        throw Exception('Aucun fichier sélectionné');
      }

      // Lire le fichier
      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final data = json.decode(jsonString) as Map<String, dynamic>;

      // Valider la version
      if (data['version'] == null) {
        throw Exception('Format de fichier invalide');
      }

      // Importer les données
      await importData(data);
    } catch (e) {
      throw Exception('Erreur lors de l\'import: $e');
    }
  }

  /// Importe les données depuis une structure JSON
  Future<void> importData(Map<String, dynamic> data) async {
    try {
      // Supprimer toutes les données existantes (optionnel - demander confirmation)
      // Pour l'instant, on ajoute sans supprimer

      // Mapper les IDs anciens vers nouveaux
      final Map<int, int> idMapping = {};

      // Importer les contacts
      final contactsList = data['contacts'] as List;
      for (var contactMap in contactsList) {
        final contact = TrackedContact.fromMap(contactMap as Map<String, dynamic>);
        final oldId = contact.id;

        // Créer un nouveau contact (sans ID pour auto-increment)
        final newContact = contact.copyWith(id: null);
        final newId = await _databaseService.insertContact(newContact);

        if (oldId != null) {
          idMapping[oldId] = newId;
        }
      }

      // Importer l'historique
      final historyMap = data['history'] as Map<String, dynamic>;
      for (var entry in historyMap.entries) {
        final oldContactId = int.parse(entry.key);
        final newContactId = idMapping[oldContactId];

        if (newContactId != null) {
          final recordsList = entry.value as List;
          for (var recordMap in recordsList) {
            final record = ContactRecord.fromMap(recordMap as Map<String, dynamic>);
            // Créer un nouvel enregistrement avec le nouveau ID de contact
            final newRecord = ContactRecord(
              trackedContactId: newContactId,
              contactDate: record.contactDate,
              contactMethod: record.contactMethod,
              contactType: record.contactType,
              context: record.context,
            );
            await _databaseService.insertContactRecord(newRecord);
          }
        }
      }
    } catch (e) {
      throw Exception('Erreur lors de l\'import des données: $e');
    }
  }

  /// Obtient les statistiques du backup
  Future<Map<String, int>> getBackupStats() async {
    try {
      final contacts = await _databaseService.getContacts();
      int totalRecords = 0;

      for (var contact in contacts) {
        if (contact.id != null) {
          final history = await _databaseService.getContactHistory(contact.id!);
          totalRecords += history.length;
        }
      }

      return {
        'contacts': contacts.length,
        'records': totalRecords,
      };
    } catch (e) {
      return {'contacts': 0, 'records': 0};
    }
  }
}
