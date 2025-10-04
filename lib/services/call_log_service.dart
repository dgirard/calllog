import 'package:flutter/services.dart';
import 'permission_service.dart';
import 'database_service.dart';
import '../models/enums.dart';

/// Service pour lire le journal d'appels Android
class CallLogService {
  static const platform = MethodChannel('com.example.calllog/call_log');
  final PermissionService _permissionService = PermissionService();
  final DatabaseService _databaseService = DatabaseService();

  /// Lit le journal d'appels Android depuis une date donnée
  Future<List<Map<String, dynamic>>> getCallsSince(DateTime since) async {
    try {
      // Vérifier la permission
      final hasPermission = await _permissionService.checkCallLogPermission();
      if (!hasPermission) {
        final granted = await _permissionService.requestCallLogPermission();
        if (!granted) {
          throw Exception('Permission de lecture du journal d\'appels refusée');
        }
      }

      // Appeler le code natif Android
      final timestamp = since.millisecondsSinceEpoch;
      final result = await platform.invokeMethod('getCallsSince', {
        'timestamp': timestamp,
      });

      if (result is List) {
        return result.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    } catch (e) {
      // Si la méthode native n'est pas implémentée, on retourne une liste vide
      // (pour permettre le développement sans le code natif)
      return [];
    }
  }

  /// Synchronise les appels avec les contacts suivis
  Future<int> syncCallsWithTrackedContacts({DateTime? since}) async {
    try {
      // Par défaut, synchroniser depuis les 30 derniers jours
      final sinceDate = since ?? DateTime.now().subtract(const Duration(days: 30));

      // Récupérer les appels sortants depuis la date
      final calls = await getCallsSince(sinceDate);

      // Récupérer tous les contacts suivis
      final trackedContacts = await _databaseService.getContacts();

      // Créer un map des numéros de téléphone -> contact ID
      final phoneToContactMap = <String, int>{};
      for (var contact in trackedContacts) {
        if (contact.id != null) {
          // Normaliser le numéro (enlever espaces, tirets, etc.)
          final normalizedPhone = _normalizePhoneNumber(contact.contactPhone);
          phoneToContactMap[normalizedPhone] = contact.id!;
        }
      }

      int syncedCount = 0;

      // Pour chaque appel, vérifier s'il correspond à un contact suivi
      for (var call in calls) {
        final phoneNumber = call['number'] as String?;
        final callDate = call['date'] as int?;
        final callType = call['type'] as int?;
        final duration = call['duration'] as int?;

        if (phoneNumber == null || callDate == null || callType == null || duration == null) {
          continue;
        }

        // Filtrer uniquement les appels sortants (type 2)
        if (callType != 2) continue;

        // Filtrer uniquement les appels de plus de 10 secondes
        if (duration < 10) continue;

        final normalizedPhone = _normalizePhoneNumber(phoneNumber);
        final contactId = phoneToContactMap[normalizedPhone];

        if (contactId != null) {
          // Vérifier si cet appel n'est pas déjà enregistré
          final callDateTime = DateTime.fromMillisecondsSinceEpoch(callDate);
          final existing = await _databaseService.getContactHistory(contactId);

          // Vérifier si un enregistrement existe déjà pour cette date/heure
          final alreadyExists = existing.any((record) {
            final diff = record.contactDate.difference(callDateTime).abs();
            return diff.inMinutes < 1; // Tolérance de 1 minute
          });

          if (!alreadyExists) {
            // Enregistrer le contact avec la vraie date de l'appel
            await _databaseService.recordContact(
              trackedContactId: contactId,
              contactMethod: ContactMethod.call,
              context: ContactContext.normal,
              contactDate: callDateTime,
            );

            syncedCount++;
          }
        }
      }

      return syncedCount;
    } catch (e) {
      throw Exception('Erreur lors de la synchronisation: $e');
    }
  }

  /// Normalise un numéro de téléphone pour la comparaison
  String _normalizePhoneNumber(String phone) {
    // Enlever tous les caractères non numériques sauf le +
    String normalized = phone.replaceAll(RegExp(r'[^\d+]'), '');

    // Si commence par 0 et a 10 chiffres, convertir en format international français
    if (normalized.startsWith('0') && normalized.length == 10) {
      normalized = '+33${normalized.substring(1)}';
    }

    // Enlever le + pour la comparaison
    normalized = normalized.replaceAll('+', '');

    return normalized;
  }

  /// Vérifie si un numéro correspond à un contact suivi
  Future<int?> findTrackedContactByPhone(String phoneNumber) async {
    try {
      final trackedContacts = await _databaseService.getContacts();
      final normalizedSearch = _normalizePhoneNumber(phoneNumber);

      for (var contact in trackedContacts) {
        final normalizedContact = _normalizePhoneNumber(contact.contactPhone);
        if (normalizedContact == normalizedSearch) {
          return contact.id;
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}
