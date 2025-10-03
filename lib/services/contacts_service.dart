import 'package:flutter_contacts/flutter_contacts.dart';
import 'permission_service.dart';

/// Service pour gérer l'accès aux contacts Android
class ContactsService {
  final PermissionService _permissionService = PermissionService();

  /// Récupère tous les contacts Android
  Future<List<Contact>> getAndroidContacts() async {
    try {
      // Vérifier la permission
      final hasPermission = await _permissionService.checkContactsPermission();
      if (!hasPermission) {
        final granted = await _permissionService.requestContactsPermission();
        if (!granted) {
          throw Exception('Permission d\'accès aux contacts refusée');
        }
      }

      // Récupérer les contacts avec les propriétés nécessaires
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: true,
      );

      return contacts;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des contacts: $e');
    }
  }

  /// Recherche des contacts par nom
  Future<List<Contact>> searchContacts(String query) async {
    try {
      if (query.isEmpty) {
        return await getAndroidContacts();
      }

      final allContacts = await getAndroidContacts();

      // Filtrer les contacts selon la requête
      return allContacts.where((contact) {
        final name = contact.displayName.toLowerCase();
        final searchQuery = query.toLowerCase();
        return name.contains(searchQuery);
      }).toList();
    } catch (e) {
      throw Exception('Erreur lors de la recherche de contacts: $e');
    }
  }

  /// Récupère la date d'anniversaire d'un contact Android
  DateTime? getContactBirthday(Contact contact) {
    try {
      // FlutterContacts stocke la date d'anniversaire dans events
      if (contact.events.isNotEmpty) {
        for (var event in contact.events) {
          if (event.label == EventLabel.birthday && event.year != null) {
            return DateTime(
              event.year!,
              event.month,
              event.day,
            );
          }
          // Si pas d'année, créer une date fictive (année 1900)
          if (event.label == EventLabel.birthday) {
            return DateTime(1900, event.month, event.day);
          }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Récupère le premier numéro de téléphone d'un contact
  String? getContactPhone(Contact contact) {
    try {
      if (contact.phones.isNotEmpty) {
        return contact.phones.first.number;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Récupère tous les numéros de téléphone d'un contact
  List<String> getContactPhones(Contact contact) {
    try {
      return contact.phones.map((phone) => phone.number).toList();
    } catch (e) {
      return [];
    }
  }

  /// Récupère la photo d'un contact sous forme de bytes
  Future<List<int>?> getContactPhoto(Contact contact) async {
    try {
      if (contact.photo != null) {
        return contact.photo;
      }

      // Si la photo n'est pas chargée, recharger le contact avec la photo
      if (contact.id.isNotEmpty) {
        final fullContact = await FlutterContacts.getContact(
          contact.id,
          withPhoto: true,
        );
        return fullContact?.photo;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Récupère un contact par son ID
  Future<Contact?> getContactById(String contactId) async {
    try {
      final hasPermission = await _permissionService.checkContactsPermission();
      if (!hasPermission) {
        throw Exception('Permission d\'accès aux contacts requise');
      }

      return await FlutterContacts.getContact(
        contactId,
        withProperties: true,
        withPhoto: true,
      );
    } catch (e) {
      return null;
    }
  }

  /// Vérifie si un contact existe toujours dans le répertoire Android
  Future<bool> contactExists(String contactId) async {
    try {
      final contact = await getContactById(contactId);
      return contact != null;
    } catch (e) {
      return false;
    }
  }

  /// Récupère le prénom d'un contact (première partie du nom)
  String getContactFirstName(Contact contact) {
    try {
      if (contact.name.first.isNotEmpty) {
        return contact.name.first;
      }
      // Sinon, prendre le premier mot du displayName
      final parts = contact.displayName.split(' ');
      return parts.isNotEmpty ? parts.first : contact.displayName;
    } catch (e) {
      return contact.displayName;
    }
  }

  /// Formate le nom complet d'un contact
  String getContactFullName(Contact contact) {
    try {
      if (contact.name.first.isNotEmpty || contact.name.last.isNotEmpty) {
        return '${contact.name.first} ${contact.name.last}'.trim();
      }
      return contact.displayName;
    } catch (e) {
      return contact.displayName;
    }
  }
}
