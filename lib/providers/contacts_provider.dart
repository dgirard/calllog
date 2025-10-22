import 'package:flutter/foundation.dart';
import '../models/tracked_contact.dart';
import '../models/contact_note.dart';
import '../models/enums.dart';
import '../services/database_service.dart';
import '../utils/priority_calculator.dart';
import '../utils/birthday_utils.dart';

/// Provider pour gérer l'état des contacts suivis
class ContactsProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();

  List<TrackedContact> _contacts = [];
  bool _isLoading = false;
  String? _error;

  List<TrackedContact> get contacts => _contacts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Charge tous les contacts depuis la base de données
  Future<void> loadContacts() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _contacts = await _databaseService.getContacts();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Ajoute un nouveau contact
  Future<void> addContact(TrackedContact contact) async {
    try {
      final id = await _databaseService.insertContact(contact);

      // Ajouter le contact avec son ID à la liste
      final newContact = contact.copyWith(id: id);
      _contacts.add(newContact);

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Met à jour un contact existant
  Future<void> updateContact(TrackedContact contact) async {
    try {
      await _databaseService.updateContact(contact);

      // Mettre à jour le contact dans la liste
      final index = _contacts.indexWhere((c) => c.id == contact.id);
      if (index != -1) {
        _contacts[index] = contact;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Supprime un contact
  Future<void> deleteContact(int id) async {
    try {
      await _databaseService.deleteContact(id);

      // Retirer le contact de la liste
      _contacts.removeWhere((c) => c.id == id);

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Enregistre un contact (appel ou SMS)
  Future<void> recordContact(
    int contactId,
    ContactMethod method,
    ContactContext context,
  ) async {
    try {
      // Trouver le contact dans la liste
      final index = _contacts.indexWhere((c) => c.id == contactId);
      if (index == -1) return;

      final contact = _contacts[index];

      // Mettre à jour la date du dernier contact
      final updatedContact = contact.copyWith(
        lastContactDate: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _databaseService.updateContact(updatedContact);

      // Mettre à jour la liste locale
      _contacts[index] = updatedContact;

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Retourne les contacts triés par priorité
  List<TrackedContact> getSortedContacts() {
    return sortContactsByPriority(_contacts);
  }

  /// Récupère un contact par son ID
  TrackedContact? getContactById(int id) {
    try {
      return _contacts.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Compte le nombre de contacts par catégorie
  Map<ContactCategory, int> getContactCountByCategory() {
    final counts = <ContactCategory, int>{};
    for (var category in ContactCategory.values) {
      counts[category] = _contacts.where((c) => c.category == category).length;
    }
    return counts;
  }

  /// Compte le nombre de contacts par priorité
  Map<Priority, int> getContactCountByPriority() {
    final counts = <Priority, int>{};
    for (var contact in _contacts) {
      final priority = calculatePriority(contact);
      counts[priority] = (counts[priority] ?? 0) + 1;
    }
    return counts;
  }

  /// Retourne les contacts avec anniversaire proche
  List<TrackedContact> getUpcomingBirthdays() {
    return _contacts.where((c) {
      if (c.birthday == null) return false;
      final daysUntil = daysUntilBirthday(c.birthday);
      return daysUntil != null && daysUntil >= 0 && daysUntil <= 7;
    }).toList()
      ..sort((a, b) {
        final aDays = daysUntilBirthday(a.birthday) ?? 999;
        final bDays = daysUntilBirthday(b.birthday) ?? 999;
        return aDays.compareTo(bDays);
      });
  }

  /// Réinitialise l'erreur
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Ajoute une note à un contact
  Future<void> addNote(int contactId, ContactNote note) async {
    try {
      await _databaseService.insertNote(note);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
