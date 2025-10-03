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

  ContactCategory? get selectedCategory => _selectedCategory;
  CallFrequency? get selectedFrequency => _selectedFrequency;
  Priority? get selectedPriority => _selectedPriority;
  bool get showOnlyBirthdays => _showOnlyBirthdays;

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

  /// Applique les filtres à une liste de contacts
  List<TrackedContact> applyFilters(List<TrackedContact> contacts) {
    var filtered = contacts.toList();

    // Filtre par catégorie
    if (_selectedCategory != null) {
      filtered = filtered
          .where((contact) => contact.category == _selectedCategory)
          .toList();
    }

    // Filtre par fréquence
    if (_selectedFrequency != null) {
      filtered = filtered
          .where((contact) => contact.frequency == _selectedFrequency)
          .toList();
    }

    // Filtre par priorité
    if (_selectedPriority != null) {
      filtered = filtered
          .where((contact) {
            final priority = calculatePriority(contact);
            return priority == _selectedPriority;
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
    notifyListeners();
  }

  /// Vérifie si au moins un filtre est actif
  bool get hasActiveFilters {
    return _selectedCategory != null ||
        _selectedFrequency != null ||
        _selectedPriority != null ||
        _showOnlyBirthdays;
  }

  /// Compte le nombre de filtres actifs
  int get activeFiltersCount {
    int count = 0;
    if (_selectedCategory != null) count++;
    if (_selectedFrequency != null) count++;
    if (_selectedPriority != null) count++;
    if (_showOnlyBirthdays) count++;
    return count;
  }
}
