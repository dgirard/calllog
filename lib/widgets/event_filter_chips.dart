import 'package:flutter/material.dart';

/// Types de filtres pour les événements
enum EventFilter {
  upcoming,  // À venir
  past,      // Passés
  archived,  // Archivés
  all,       // Tous
}

/// Widget pour filtrer les événements avec des chips
class EventFilterChips extends StatelessWidget {
  final EventFilter currentFilter;
  final ValueChanged<EventFilter> onFilterChanged;

  const EventFilterChips({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: EventFilter.values.map((filter) {
            final isSelected = filter == currentFilter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(_getFilterLabel(filter)),
                selected: isSelected,
                onSelected: (_) => onFilterChanged(filter),
                avatar: Icon(
                  _getFilterIcon(filter),
                  size: 18,
                ),
                backgroundColor: isSelected
                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                    : null,
                selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                checkmarkColor: Theme.of(context).primaryColor,
                labelStyle: TextStyle(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : null,
                  fontWeight: isSelected ? FontWeight.bold : null,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Retourne le label du filtre
  String _getFilterLabel(EventFilter filter) {
    switch (filter) {
      case EventFilter.upcoming:
        return 'À venir';
      case EventFilter.past:
        return 'Passés';
      case EventFilter.archived:
        return 'Archivés';
      case EventFilter.all:
        return 'Tous';
    }
  }

  /// Retourne l'icône du filtre
  IconData _getFilterIcon(EventFilter filter) {
    switch (filter) {
      case EventFilter.upcoming:
        return Icons.upcoming;
      case EventFilter.past:
        return Icons.history;
      case EventFilter.archived:
        return Icons.archive;
      case EventFilter.all:
        return Icons.all_inclusive;
    }
  }
}

/// Widget pour filtrer par catégorie d'événement
class EventCategoryFilterChips extends StatelessWidget {
  final List<String> selectedCategories;
  final ValueChanged<List<String>> onCategoriesChanged;

  const EventCategoryFilterChips({
    super.key,
    required this.selectedCategories,
    required this.onCategoriesChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Catégories disponibles avec leurs icônes
    final categories = [
      {'id': 'vacation', 'label': 'Vacances', 'icon': '🏖️'},
      {'id': 'weekend', 'label': 'Week-end', 'icon': '🏡'},
      {'id': 'shopping', 'label': 'Courses', 'icon': '🛒'},
      {'id': 'birthday', 'label': 'Anniversaire', 'icon': '🎂'},
      {'id': 'almanac', 'label': 'Almanach', 'icon': '📅'},
      {'id': 'fullMoon', 'label': 'Pleine lune', 'icon': '🌕'},
      {'id': 'holiday', 'label': 'Jour férié', 'icon': '🎊'},
      {'id': 'medical', 'label': 'Médical', 'icon': '⚕️'},
      {'id': 'meeting', 'label': 'Réunion', 'icon': '🤝'},
      {'id': 'other', 'label': 'Autre', 'icon': '📌'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: categories.map((category) {
            final isSelected = selectedCategories.contains(category['id']);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(category['icon']!),
                    const SizedBox(width: 4),
                    Text(category['label']!),
                  ],
                ),
                selected: isSelected,
                onSelected: (_) {
                  final updatedCategories = List<String>.from(selectedCategories);
                  if (isSelected) {
                    updatedCategories.remove(category['id']);
                  } else {
                    updatedCategories.add(category['id']!);
                  }
                  onCategoriesChanged(updatedCategories);
                },
                backgroundColor: isSelected
                    ? Theme.of(context).primaryColor.withOpacity(0.1)
                    : null,
                selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                checkmarkColor: Theme.of(context).primaryColor,
                labelStyle: TextStyle(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : null,
                  fontWeight: isSelected ? FontWeight.bold : null,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}