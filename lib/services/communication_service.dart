import 'package:url_launcher/url_launcher.dart';
import '../models/enums.dart';
import '../models/contact_record.dart';
import 'database_service.dart';
import 'permission_service.dart';
import '../utils/constants.dart';

/// Service pour gérer les appels téléphoniques et SMS
class CommunicationService {
  final DatabaseService _databaseService = DatabaseService();
  final PermissionService _permissionService = PermissionService();

  // ==================== Appels téléphoniques ====================

  /// Lance un appel téléphonique
  Future<bool> makeCall(String phoneNumber) async {
    try {
      // Vérifier la permission
      final hasPermission = await _permissionService.checkCallPermission();
      if (!hasPermission) {
        final granted = await _permissionService.requestCallPermission();
        if (!granted) {
          throw Exception(ErrorMessages.noCallPermission);
        }
      }

      // Nettoyer le numéro de téléphone
      final cleanedNumber = _cleanPhoneNumber(phoneNumber);
      if (cleanedNumber.isEmpty) {
        throw Exception(ErrorMessages.noPhoneNumber);
      }

      // Créer l'URI pour l'appel
      final Uri telUri = Uri(scheme: 'tel', path: cleanedNumber);

      // Lancer l'appel
      if (await canLaunchUrl(telUri)) {
        return await launchUrl(telUri);
      } else {
        throw Exception('Impossible de lancer l\'appel');
      }
    } catch (e) {
      throw Exception('Erreur lors du lancement de l\'appel: $e');
    }
  }

  // ==================== SMS ====================

  /// Envoie un SMS (ouvre l'application SMS native)
  Future<bool> sendSms(String phoneNumber, {String? message}) async {
    try {
      // Note: La permission SMS n'est pas requise pour ouvrir l'app SMS
      // Elle est nécessaire uniquement pour envoyer directement sans interaction

      // Nettoyer le numéro de téléphone
      final cleanedNumber = _cleanPhoneNumber(phoneNumber);
      if (cleanedNumber.isEmpty) {
        throw Exception(ErrorMessages.noPhoneNumber);
      }

      // Créer l'URI pour le SMS
      Uri smsUri;
      if (message != null && message.isNotEmpty) {
        smsUri = Uri(
          scheme: 'sms',
          path: cleanedNumber,
          queryParameters: {'body': message},
        );
      } else {
        smsUri = Uri(scheme: 'sms', path: cleanedNumber);
      }

      // Lancer l'application SMS
      if (await canLaunchUrl(smsUri)) {
        return await launchUrl(smsUri);
      } else {
        throw Exception('Impossible d\'ouvrir l\'application SMS');
      }
    } catch (e) {
      throw Exception('Erreur lors de l\'ouverture du SMS: $e');
    }
  }

  /// Envoie un SMS d'anniversaire avec message pré-rempli
  Future<bool> sendBirthdaySms(String phoneNumber, String firstName) async {
    try {
      // Formater le message d'anniversaire
      final message = defaultBirthdaySmsTemplate.replaceAll('{name}', firstName);

      return await sendSms(phoneNumber, message: message);
    } catch (e) {
      throw Exception('Erreur lors de l\'envoi du SMS d\'anniversaire: $e');
    }
  }

  // ==================== Enregistrement des contacts ====================

  /// Enregistre un contact dans l'historique
  Future<int> recordContact(
    int contactId,
    ContactMethod method,
    ContactContext context,
  ) async {
    try {
      final record = ContactRecord(
        trackedContactId: contactId,
        contactDate: DateTime.now(),
        contactMethod: method,
        contactType: 'manual',
        context: context,
      );

      final recordId = await _databaseService.insertContactRecord(record);

      // Mettre à jour la date du dernier contact dans tracked_contacts
      final contact = await _databaseService.getContactById(contactId);
      if (contact != null) {
        final updatedContact = contact.copyWith(
          lastContactDate: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _databaseService.updateContact(updatedContact);
      }

      return recordId;
    } catch (e) {
      throw Exception('Erreur lors de l\'enregistrement du contact: $e');
    }
  }

  /// Enregistre un appel téléphonique
  Future<int> recordCall(int contactId, {ContactContext context = ContactContext.normal}) async {
    return await recordContact(contactId, ContactMethod.call, context);
  }

  /// Enregistre un SMS
  Future<int> recordSms(int contactId, {ContactContext context = ContactContext.normal}) async {
    return await recordContact(contactId, ContactMethod.sms, context);
  }

  /// Lance un appel et enregistre le contact
  Future<bool> makeCallAndRecord(
    int contactId,
    String phoneNumber, {
    ContactContext context = ContactContext.normal,
  }) async {
    try {
      final success = await makeCall(phoneNumber);
      if (success) {
        await recordCall(contactId, context: context);
      }
      return success;
    } catch (e) {
      rethrow;
    }
  }

  /// Envoie un SMS et enregistre le contact
  Future<bool> sendSmsAndRecord(
    int contactId,
    String phoneNumber, {
    String? message,
    ContactContext context = ContactContext.normal,
  }) async {
    try {
      final success = await sendSms(phoneNumber, message: message);
      if (success) {
        await recordSms(contactId, context: context);
      }
      return success;
    } catch (e) {
      rethrow;
    }
  }

  /// Envoie un SMS d'anniversaire et enregistre le contact
  Future<bool> sendBirthdaySmsAndRecord(
    int contactId,
    String phoneNumber,
    String firstName,
  ) async {
    try {
      final success = await sendBirthdaySms(phoneNumber, firstName);
      if (success) {
        await recordSms(contactId, context: ContactContext.birthday);
      }
      return success;
    } catch (e) {
      rethrow;
    }
  }

  // ==================== Utilitaires ====================

  /// Nettoie un numéro de téléphone (enlève espaces, tirets, etc.)
  String _cleanPhoneNumber(String phoneNumber) {
    // Enlever tous les caractères non numériques sauf le + initial
    String cleaned = phoneNumber.trim();

    // Garder le + s'il est au début
    final hasPlus = cleaned.startsWith('+');

    // Enlever tous les caractères non numériques
    cleaned = cleaned.replaceAll(RegExp(r'[^0-9]'), '');

    // Remettre le + si nécessaire
    if (hasPlus) {
      cleaned = '+$cleaned';
    }

    return cleaned;
  }

  /// Vérifie si un numéro de téléphone est valide
  bool isValidPhoneNumber(String phoneNumber) {
    final cleaned = _cleanPhoneNumber(phoneNumber);

    // Un numéro valide doit avoir au moins 6 chiffres
    final digitsOnly = cleaned.replaceAll('+', '');
    return digitsOnly.length >= 6;
  }
}
