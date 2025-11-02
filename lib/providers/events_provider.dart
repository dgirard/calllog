import 'package:flutter/foundation.dart';
import '../models/event.dart';
import '../models/tracked_contact.dart';
import '../models/enums.dart';
import '../services/database_service.dart';

/// Provider pour gérer l'état des événements
class EventsProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();

  List<Event> _events = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Event> get events => _events;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ==================== MÉTHODES CRUD ====================

  /// Charge tous les événements depuis la base de données
  Future<void> loadEvents() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _events = await _databaseService.getEvents();
      _error = null;
    } catch (e) {
      _error = e.toString();
      print('Erreur lors du chargement des événements: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Ajoute un nouvel événement avec les contacts associés
  Future<void> addEvent(Event event, List<int> contactIds) async {
    try {
      // Insérer l'événement
      final eventId = await _databaseService.insertEvent(event);

      // Ajouter les contacts associés
      for (final contactId in contactIds) {
        await _databaseService.addContactToEvent(eventId, contactId);
      }

      // Recharger les événements
      await loadEvents();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      throw e;
    }
  }

  /// Met à jour un événement existant avec les contacts associés optionnels
  Future<void> updateEvent(Event event, [List<int>? contactIds]) async {
    try {
      await _databaseService.updateEvent(event);

      // Si des contacts sont fournis, mettre à jour les associations
      if (contactIds != null) {
        // Supprimer toutes les associations existantes pour cet événement
        await _databaseService.deleteEventContacts(event.id!);

        // Ajouter les nouvelles associations
        for (final contactId in contactIds) {
          await _databaseService.addContactToEvent(event.id!, contactId);
        }
      }

      await loadEvents();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      throw e;
    }
  }

  /// Supprime un événement
  Future<void> deleteEvent(int id) async {
    try {
      await _databaseService.deleteEvent(id);
      await loadEvents();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      throw e;
    }
  }

  /// Archive un événement
  Future<void> archiveEvent(int id) async {
    try {
      final event = getEventById(id);
      if (event != null) {
        final updatedEvent = event.copyWith(status: EventStatus.archived);
        await updateEvent(updatedEvent);
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      throw e;
    }
  }

  /// Désarchive un événement
  Future<void> unarchiveEvent(int id) async {
    try {
      final event = getEventById(id);
      if (event != null) {
        final updatedEvent = event.copyWith(status: EventStatus.active);
        await updateEvent(updatedEvent);
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      throw e;
    }
  }

  // ==================== MÉTHODES DE FILTRAGE ====================

  /// Retourne les événements à venir
  List<Event> getUpcomingEvents() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return _events.where((event) {
      if (event.status != EventStatus.active) return false;

      final eventStart = DateTime(
        event.startDate.year,
        event.startDate.month,
        event.startDate.day,
      );

      // Événement à venir ou en cours
      return eventStart.isAfter(today) || eventStart.isAtSameMomentAs(today) || event.isOngoing;
    }).toList()..sort((a, b) => a.startDate.compareTo(b.startDate));
  }

  /// Retourne les événements passés
  List<Event> getPastEvents() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return _events.where((event) {
      if (event.status != EventStatus.active) return false;

      final eventEnd = event.endDate != null
          ? DateTime(event.endDate!.year, event.endDate!.month, event.endDate!.day)
          : DateTime(event.startDate.year, event.startDate.month, event.startDate.day);

      return eventEnd.isBefore(today);
    }).toList()..sort((a, b) => b.startDate.compareTo(a.startDate));
  }

  /// Retourne les événements archivés
  List<Event> getArchivedEvents() {
    return _events.where((event) => event.status == EventStatus.archived)
        .toList()..sort((a, b) => b.startDate.compareTo(a.startDate));
  }

  /// Retourne les événements actifs (non archivés)
  List<Event> getActiveEvents() {
    return _events.where((event) => event.status == EventStatus.active).toList();
  }

  /// Retourne les événements d'une catégorie
  List<Event> getEventsByCategory(EventCategory category) {
    return _events.where((event) => event.category == category).toList();
  }

  /// Retourne les événements d'un mois donné
  List<Event> getEventsForMonth(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);

    return _events.where((event) {
      final startInMonth = event.startDate.isAfter(firstDay.subtract(const Duration(days: 1))) &&
                          event.startDate.isBefore(lastDay.add(const Duration(days: 1)));

      final endInMonth = event.endDate != null &&
                        event.endDate!.isAfter(firstDay.subtract(const Duration(days: 1))) &&
                        event.endDate!.isBefore(lastDay.add(const Duration(days: 1)));

      return startInMonth || endInMonth;
    }).toList()..sort((a, b) => a.startDate.compareTo(b.startDate));
  }

  // ==================== GESTION DES CONTACTS ====================

  /// Ajoute un contact à un événement
  Future<void> addContactToEvent(int eventId, int contactId) async {
    try {
      await _databaseService.addContactToEvent(eventId, contactId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      throw e;
    }
  }

  /// Retire un contact d'un événement
  Future<void> removeContactFromEvent(int eventId, int contactId) async {
    try {
      await _databaseService.removeContactFromEvent(eventId, contactId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      throw e;
    }
  }

  /// Récupère les contacts d'un événement
  Future<List<TrackedContact>> getEventContacts(int eventId) async {
    try {
      return await _databaseService.getEventContacts(eventId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      throw e;
    }
  }

  /// Récupère les IDs des contacts associés à un événement
  Future<List<int>> getEventContactIds(int eventId) async {
    try {
      final contacts = await _databaseService.getEventContacts(eventId);
      return contacts.map((contact) => contact.id!).toList();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  /// Récupère les événements d'un contact
  Future<List<Event>> getContactEvents(int contactId) async {
    try {
      return await _databaseService.getContactEvents(contactId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      throw e;
    }
  }

  // ==================== UTILITAIRES ====================

  /// Retourne un événement par son ID
  Event? getEventById(int id) {
    try {
      return _events.firstWhere((event) => event.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Efface l'erreur
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Retourne le prochain événement à venir
  Event? getNextUpcomingEvent() {
    final upcoming = getUpcomingEvents();
    return upcoming.isNotEmpty ? upcoming.first : null;
  }

  /// Retourne les événements du jour
  List<Event> getTodayEvents() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return _events.where((event) {
      if (event.status != EventStatus.active) return false;

      final startDate = DateTime(
        event.startDate.year,
        event.startDate.month,
        event.startDate.day,
      );

      final endDate = event.endDate != null
          ? DateTime(event.endDate!.year, event.endDate!.month, event.endDate!.day)
          : startDate;

      return (startDate.isAtSameMomentAs(today) ||
              (startDate.isBefore(today) && endDate.isAfter(today)) ||
              endDate.isAtSameMomentAs(today));
    }).toList()..sort((a, b) => a.startDate.compareTo(b.startDate));
  }
}