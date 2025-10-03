import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/filters_provider.dart';
import '../models/enums.dart';

/// Écran de filtres avancés
class FiltersScreen extends StatelessWidget {
  const FiltersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filtres'),
        actions: [
          Consumer<FiltersProvider>(
            builder: (context, filtersProvider, child) {
              if (!filtersProvider.hasActiveFilters) {
                return const SizedBox.shrink();
              }
              return TextButton(
                onPressed: () {
                  filtersProvider.resetFilters();
                },
                child: const Text('Réinitialiser'),
              );
            },
          ),
        ],
      ),
      body: Consumer<FiltersProvider>(
        builder: (context, filtersProvider, child) {
          return ListView(
            children: [
              // Anniversaires
              SwitchListTile(
                title: const Row(
                  children: [
                    Text('🎂'),
                    SizedBox(width: 8),
                    Text('Anniversaires uniquement'),
                  ],
                ),
                subtitle: const Text('Afficher seulement les anniversaires proches'),
                value: filtersProvider.showOnlyBirthdays,
                onChanged: (_) => filtersProvider.toggleBirthdaysFilter(),
                activeColor: Colors.pink,
              ),

              const Divider(),

              // Catégories
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Catégories',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ContactCategory.values.map((category) {
                        final isSelected = filtersProvider.selectedCategories
                            .contains(category);
                        return FilterChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_getCategoryIcon(category), size: 16),
                              const SizedBox(width: 4),
                              Text(category.displayName),
                            ],
                          ),
                          selected: isSelected,
                          onSelected: (_) {
                            filtersProvider.toggleCategory(category);
                          },
                          selectedColor: _getCategoryColor(category),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const Divider(),

              // Fréquences
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fréquences',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: CallFrequency.values.map((frequency) {
                        final isSelected = filtersProvider.selectedFrequencies
                            .contains(frequency);
                        return FilterChip(
                          label: Text(frequency.displayName),
                          selected: isSelected,
                          onSelected: (_) {
                            filtersProvider.toggleFrequency(frequency);
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const Divider(),

              // Priorités
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Priorités',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: Priority.values.map((priority) {
                        final isSelected = filtersProvider.selectedPriorities
                            .contains(priority);
                        return FilterChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: _getPriorityColor(priority),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(priority.displayName),
                            ],
                          ),
                          selected: isSelected,
                          onSelected: (_) {
                            filtersProvider.togglePriority(priority);
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const Divider(),

              // Résumé des filtres actifs
              if (filtersProvider.hasActiveFilters)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.filter_list,
                                size: 20,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${filtersProvider.activeFiltersCount} filtre(s) actif(s)',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getFiltersSummary(filtersProvider),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  IconData _getCategoryIcon(ContactCategory category) {
    switch (category) {
      case ContactCategory.family:
        return Icons.family_restroom;
      case ContactCategory.friends:
        return Icons.people;
      case ContactCategory.professional:
        return Icons.work;
    }
  }

  Color _getCategoryColor(ContactCategory category) {
    switch (category) {
      case ContactCategory.family:
        return Colors.purple.shade100;
      case ContactCategory.friends:
        return Colors.green.shade100;
      case ContactCategory.professional:
        return Colors.blue.shade100;
    }
  }

  Color _getPriorityColor(Priority priority) {
    switch (priority) {
      case Priority.high:
        return Colors.red;
      case Priority.medium:
        return Colors.orange;
      case Priority.low:
        return Colors.green;
      case Priority.birthday:
        return Colors.pink;
    }
  }

  String _getFiltersSummary(FiltersProvider provider) {
    final List<String> parts = [];

    if (provider.showOnlyBirthdays) {
      parts.add('Anniversaires uniquement');
    }

    if (provider.selectedCategories.isNotEmpty) {
      final categories = provider.selectedCategories
          .map((c) => c.displayName)
          .join(', ');
      parts.add('Catégories: $categories');
    }

    if (provider.selectedFrequencies.isNotEmpty) {
      final frequencies = provider.selectedFrequencies
          .map((f) => f.displayName)
          .join(', ');
      parts.add('Fréquences: $frequencies');
    }

    if (provider.selectedPriorities.isNotEmpty) {
      final priorities = provider.selectedPriorities
          .map((p) => p.displayName)
          .join(', ');
      parts.add('Priorités: $priorities');
    }

    return parts.join(' • ');
  }
}
