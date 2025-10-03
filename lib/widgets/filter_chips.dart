import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/filters_provider.dart';

/// Widget affichant les chips de filtrage rapide
class FilterChips extends StatelessWidget {
  const FilterChips({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FiltersProvider>(
      builder: (context, filtersProvider, child) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // Chip Anniversaires
              FilterChip(
                label: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🎂'),
                    SizedBox(width: 4),
                    Text('Anniversaires'),
                  ],
                ),
                selected: filtersProvider.showOnlyBirthdays,
                onSelected: (_) => filtersProvider.toggleBirthdaysFilter(),
                selectedColor: Colors.pink.shade100,
              ),

              const SizedBox(width: 8),

              // Bouton Réinitialiser (si au moins un filtre actif)
              if (filtersProvider.hasActiveFilters)
                ActionChip(
                  label: const Text('Réinitialiser'),
                  avatar: const Icon(Icons.clear, size: 16),
                  onPressed: () => filtersProvider.resetFilters(),
                ),

              const SizedBox(width: 8),

              // Bouton Plus de filtres
              ActionChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.filter_list, size: 16),
                    const SizedBox(width: 4),
                    const Text('Filtres'),
                    if (filtersProvider.activeFiltersCount > 0)
                      Container(
                        margin: const EdgeInsets.only(left: 4),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${filtersProvider.activeFiltersCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: () {
                  // Ouvre le modal de filtres (à implémenter)
                  Navigator.pushNamed(context, '/filters');
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
