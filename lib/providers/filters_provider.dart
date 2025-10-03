import 'package:flutter/foundation.dart';
import '../models/tracked_contact.dart';
import '../models/enums.dart';
import '../utils/birthday_utils.dart';
import '../utils/priority_calculator.dart';

/// Provider pour gérer l'état des filtres
class FiltersProvider extends ChangeNotifier {
  ContactCategory? _selectedCategory;
  CallFrequency? _selectedFrequency;
  Priority? _selectedPriority;
  bool _showOnlyBirthdays = false;

  // Filtres multiples
  final Set<ContactCategory> _selectedCategories = {};
  final Set<CallFrequency> _selectedFrequencies = {};
  final Set<Priority> _selectedPriorities = {};

  ContactCategory? get selectedCategory => _selectedCategory;
  CallFrequency? get selectedFrequency => _selectedFrequency;
  Priority? get selectedPriority => _selectedPriority;
  bool get showOnlyBirthdays => _showOnlyBirthdays;

  Set<ContactCategory> get selectedCategories => _selectedCategories;
  Set<CallFrequency> get selectedFrequencies => _selectedFrequencies;
  Set<Priority> get selectedPriorities => _selectedPriorities;

  /// Change le filtre de catégorie
  void setCategory(ContactCategory? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  /// Change le filtre de fréquence
  void setFrequency(CallFrequency? frequency) {
    _selectedFrequency = frequency;
    notifyListeners();
  }

  /// Change le filtre de priorité
  void setPriority(Priority? priority) {
    _selectedPriority = priority;
    notifyListeners();
  }

  /// Active/désactive le filtre anniversaires
  void toggleBirthdaysFilter() {
    _showOnlyBirthdays = !_showOnlyBirthdays;
    notifyListeners();
  }

  /// Définit le filtre anniversaires
  void setShowOnlyBirthdays(bool value) {
    _showOnlyBirthdays = value;
    notifyListeners();
  }

  /// Active/désactive une catégorie dans les filtres multiples
  void toggleCategory(ContactCategory category) {
    if (_selectedCategories.contains(category)) {
      _selectedCategories.remove(category);
    } else {
      _selectedCategories.add(category);
    }
    notifyListeners();
  }

  /// Active/désactive une fréquence dans les filtres multiples
  void toggleFrequency(CallFrequency frequency) {
    if (_selectedFrequencies.contains(frequency)) {
      _selectedFrequencies.remove(frequency);
    } else {
      _selectedFrequencies.add(frequency);
    }
    notifyListeners();
  }

  /// Active/désactive une priorité dans les filtres multiples
  void togglePriority(Priority priority) {
    if (_selectedPriorities.contains(priority)) {
      _selectedPriorities.remove(priority);
    } else {
      _selectedPriorities.add(priority);
    }
    notifyListeners();
  }

  /// Applique les filtres à une liste de contacts
  List<TrackedContact> applyFilters(List<TrackedContact> contacts) {
    var filtered = contacts.toList();

    // Filtre par catégorie (simple)
    if (_selectedCategory != null) {
      filtered = filtered
          .where((contact) => contact.category == _selectedCategory)
          .toList();
    }

    // Filtre par catégories multiples
    if (_selectedCategories.isNotEmpty) {
      filtered = filtered
          .where((contact) => _selectedCategories.contains(contact.category))
          .toList();
    }

    // Filtre par fréquence (simple)
    if (_selectedFrequency != null) {
      filtered = filtered
          .where((contact) => contact.frequency == _selectedFrequency)
          .toList();
    }

    // Filtre par fréquences multiples
    if (_selectedFrequencies.isNotEmpty) {
      filtered = filtered
          .where((contact) => _selectedFrequencies.contains(contact.frequency))
          .toList();
    }

    // Filtre par priorité (simple)
    if (_selectedPriority != null) {
      filtered = filtered
          .where((contact) {
            final priority = calculatePriority(contact);
            return priority == _selectedPriority;
          })
          .toList();
    }

    // Filtre par priorités multiples
    if (_selectedPriorities.isNotEmpty) {
      filtered = filtered
          .where((contact) {
            final priority = calculatePriority(contact);
            return _selectedPriorities.contains(priority);
          })
          .toList();
    }

    // Filtre anniversaires uniquement
    if (_showOnlyBirthdays) {
      filtered = filtered
          .where((contact) {
            if (contact.birthday == null) return false;
            return isBirthdaySoon(contact.birthday) ||
                   isBirthdayToday(contact.birthday);
          })
          .toList();
    }

    return filtered;
  }

  /// Réinitialise tous les filtres
  void resetFilters() {
    _selectedCategory = null;
    _selectedFrequency = null;
    _selectedPriority = null;
    _showOnlyBirthdays = false;
    _selectedCategories.clear();
    _selectedFrequencies.clear();
    _selectedPriorities.clear();
    notifyListeners();
  }

  /// Vérifie si au moins un filtre est actif
  bool get hasActiveFilters {
    return _selectedCategory != null ||
        _selectedFrequency != null ||
        _selectedPriority != null ||
        _showOnlyBirthdays ||
        _selectedCategories.isNotEmpty ||
        _selectedFrequencies.isNotEmpty ||
        _selectedPriorities.isNotEmpty;
  }

  /// Compte le nombre de filtres actifs
  int get activeFiltersCount {
    int count = 0;
    if (_selectedCategory != null) count++;
    if (_selectedFrequency != null) count++;
    if (_selectedPriority != null) count++;
    if (_showOnlyBirthdays) count++;
    count += _selectedCategories.length;
    count += _selectedFrequencies.length;
    count += _selectedPriorities.length;
    return count;
  }
}
