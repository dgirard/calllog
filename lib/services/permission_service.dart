import 'package:permission_handler/permission_handler.dart';

/// Service pour gérer les permissions Android
class PermissionService {
  // ==================== Contacts ====================

  /// Demande la permission d'accès aux contacts
  Future<bool> requestContactsPermission() async {
    try {
      final status = await Permission.contacts.request();
      return status.isGranted;
    } catch (e) {
      return false;
    }
  }

  /// Vérifie si la permission contacts est accordée (sans demander)
  Future<bool> checkContactsPermission() async {
    try {
      final status = await Permission.contacts.status;
      return status.isGranted;
    } catch (e) {
      return false;
    }
  }

  /// Retourne le statut de la permission contacts
  Future<PermissionStatus> getContactsPermissionStatus() async {
    try {
      return await Permission.contacts.status;
    } catch (e) {
      return PermissionStatus.denied;
    }
  }

  // ==================== Appels téléphoniques ====================

  /// Demande la permission d'appel téléphonique
  Future<bool> requestCallPermission() async {
    try {
      final status = await Permission.phone.request();
      return status.isGranted;
    } catch (e) {
      return false;
    }
  }

  /// Vérifie si la permission d'appel est accordée (sans demander)
  Future<bool> checkCallPermission() async {
    try {
      final status = await Permission.phone.status;
      return status.isGranted;
    } catch (e) {
      return false;
    }
  }

  /// Retourne le statut de la permission d'appel
  Future<PermissionStatus> getCallPermissionStatus() async {
    try {
      return await Permission.phone.status;
    } catch (e) {
      return PermissionStatus.denied;
    }
  }

  // ==================== SMS ====================

  /// Demande la permission d'envoi de SMS
  Future<bool> requestSmsPermission() async {
    try {
      final status = await Permission.sms.request();
      return status.isGranted;
    } catch (e) {
      return false;
    }
  }

  /// Vérifie si la permission SMS est accordée (sans demander)
  Future<bool> checkSmsPermission() async {
    try {
      final status = await Permission.sms.status;
      return status.isGranted;
    } catch (e) {
      return false;
    }
  }

  /// Retourne le statut de la permission SMS
  Future<PermissionStatus> getSmsPermissionStatus() async {
    try {
      return await Permission.sms.status;
    } catch (e) {
      return PermissionStatus.denied;
    }
  }

  // ==================== Journal d'appels ====================

  /// Demande la permission de lecture du journal d'appels
  Future<bool> requestCallLogPermission() async {
    try {
      final status = await Permission.phone.request();
      return status.isGranted;
    } catch (e) {
      return false;
    }
  }

  /// Vérifie si la permission de lecture du journal d'appels est accordée
  Future<bool> checkCallLogPermission() async {
    try {
      final status = await Permission.phone.status;
      return status.isGranted;
    } catch (e) {
      return false;
    }
  }

  /// Retourne le statut de la permission de lecture du journal d'appels
  Future<PermissionStatus> getCallLogPermissionStatus() async {
    try {
      return await Permission.phone.status;
    } catch (e) {
      return PermissionStatus.denied;
    }
  }

  // ==================== Utilitaires ====================

  /// Ouvre les paramètres de l'application
  Future<bool> openAppSettings() async {
    try {
      return await openAppSettings();
    } catch (e) {
      return false;
    }
  }

  /// Vérifie si une permission est définitivement refusée
  Future<bool> isPermissionPermanentlyDenied(Permission permission) async {
    try {
      final status = await permission.status;
      return status.isPermanentlyDenied;
    } catch (e) {
      return false;
    }
  }

  /// Demande toutes les permissions nécessaires d'un coup
  Future<Map<Permission, PermissionStatus>> requestAllPermissions() async {
    try {
      return await [
        Permission.contacts,
        Permission.phone,
        Permission.sms,
      ].request();
    } catch (e) {
      return {};
    }
  }

  /// Vérifie si toutes les permissions essentielles sont accordées
  Future<bool> checkAllEssentialPermissions() async {
    try {
      final contactsGranted = await checkContactsPermission();
      final callGranted = await checkCallPermission();

      // SMS n'est pas essentiel pour le fonctionnement basique
      return contactsGranted && callGranted;
    } catch (e) {
      return false;
    }
  }

  /// Retourne un message d'erreur en fonction du statut de permission
  String getPermissionErrorMessage(PermissionStatus status, String permissionName) {
    switch (status) {
      case PermissionStatus.denied:
        return 'Permission $permissionName refusée';
      case PermissionStatus.permanentlyDenied:
        return 'Permission $permissionName définitivement refusée. Veuillez l\'activer dans les paramètres.';
      case PermissionStatus.restricted:
        return 'Permission $permissionName restreinte par le système';
      case PermissionStatus.limited:
        return 'Permission $permissionName limitée';
      case PermissionStatus.provisional:
        return 'Permission $permissionName provisoire';
      case PermissionStatus.granted:
        return 'Permission $permissionName accordée';
      default:
        return 'Statut de permission $permissionName inconnu';
    }
  }
}
