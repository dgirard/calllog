import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/weekly_summary_provider.dart';
import '../models/weekly_summary.dart';
import '../models/enums.dart';
import '../models/tts_provider.dart';
import '../utils/birthday_utils.dart';
import '../widgets/empty_state.dart';

/// Écran de l'assistant hebdomadaire
class WeeklySummaryScreen extends StatefulWidget {
  const WeeklySummaryScreen({super.key});

  @override
  State<WeeklySummaryScreen> createState() => _WeeklySummaryScreenState();
}

class _WeeklySummaryScreenState extends State<WeeklySummaryScreen> {
  @override
  void initState() {
    super.initState();
    // Initialiser et charger les données au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<WeeklySummaryProvider>();
      provider.initialize().then((_) {
        provider.loadSummaryData();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistant Hebdomadaire'),
        actions: [
          // Sélecteur de type de résumé
          Consumer<WeeklySummaryProvider>(
            builder: (context, provider, _) {
              return PopupMenuButton<SummaryType>(
                icon: const Icon(Icons.filter_list),
                onSelected: (type) {
                  provider.setSummaryType(type);
                  provider.loadSummaryData();
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: SummaryType.daily,
                    child: Row(
                      children: [
                        const Icon(Icons.today, size: 20),
                        const SizedBox(width: 8),
                        Text(SummaryType.daily.displayName),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: SummaryType.weekly,
                    child: Row(
                      children: [
                        const Icon(Icons.date_range, size: 20),
                        const SizedBox(width: 8),
                        Text(SummaryType.weekly.displayName),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<WeeklySummaryProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Collecte des données...'),
                ],
              ),
            );
          }

          if (provider.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      provider.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => provider.regenerateSummary(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (provider.isEmpty) {
            return EmptyState(
              icon: Icons.event_available,
              title: 'Semaine tranquille !',
              message: 'Aucune tâche urgente cette ${provider.currentType == SummaryType.daily ? 'journée' : 'semaine'}.\nProfite de ton temps libre !',
              actionLabel: 'Actualiser',
              onActionPressed: () => provider.loadSummaryData(),
            );
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // Contrôles audio
                _buildAudioControls(provider),

                // Résumé textuel (si généré)
                if (provider.summaryText != null)
                  _buildSummaryText(provider),

                // Données structurées
                _buildSummaryData(provider),
              ],
            ),
          );
        },
      ),
      floatingActionButton: Consumer<WeeklySummaryProvider>(
        builder: (context, provider, _) {
          if (!provider.hasData) return const SizedBox.shrink();

          return FloatingActionButton.extended(
            onPressed: provider.isGenerating || provider.isPlaying
                ? null
                : () async {
                    if (provider.summaryText == null) {
                      await provider.generateSummaryText();
                    }
                    if (provider.summaryText != null) {
                      await provider.playSummary();
                    }
                  },
            icon: Icon(
              provider.isGenerating
                  ? Icons.hourglass_empty
                  : provider.isPlaying
                      ? Icons.volume_up
                      : Icons.play_arrow,
            ),
            label: Text(
              provider.isGenerating
                  ? 'Génération...'
                  : provider.isPlaying
                      ? 'Lecture...'
                      : 'Écouter le résumé',
            ),
            backgroundColor: provider.isPlaying ? Colors.orange : null,
          );
        },
      ),
    );
  }

  /// Construit les contrôles audio
  Widget _buildAudioControls(WeeklySummaryProvider provider) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      color: provider.isPlaying ? Colors.orange[50] : Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Icône et titre
            Icon(
              provider.isPlaying ? Icons.volume_up : Icons.assistant,
              size: 48,
              color: provider.isPlaying ? Colors.orange : Colors.blue,
            ),
            const SizedBox(height: 8),
            Text(
              provider.currentType == SummaryType.daily
                  ? 'Résumé du jour'
                  : 'Résumé de la semaine',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              provider.getStatsSummary(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 16),

            // Sélecteur de voix
            _buildVoiceSelector(provider),
            const SizedBox(height: 16),

            // Boutons de contrôle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Bouton Play/Génération
                _buildControlButton(
                  icon: provider.isGenerating
                      ? Icons.hourglass_empty
                      : provider.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                  label: provider.isGenerating
                      ? 'Génération'
                      : provider.isPlaying
                          ? 'Pause'
                          : 'Écouter',
                  onPressed: provider.isGenerating
                      ? null
                      : () async {
                          if (provider.isPlaying) {
                            await provider.pauseSummary();
                          } else {
                            if (provider.summaryText == null) {
                              await provider.generateSummaryText();
                            }
                            if (provider.summaryText != null) {
                              await provider.playSummary();
                            }
                          }
                        },
                  primary: true,
                ),

                // Bouton Stop
                _buildControlButton(
                  icon: Icons.stop,
                  label: 'Arrêter',
                  onPressed: provider.canStop
                      ? () => provider.stopSummary()
                      : null,
                ),

                // Bouton Régénérer
                _buildControlButton(
                  icon: Icons.refresh,
                  label: 'Régénérer',
                  onPressed: provider.isGenerating || provider.isPlaying
                      ? null
                      : () => provider.regenerateSummary(),
                ),
              ],
            ),

            // Indicateur de génération
            if (provider.isGenerating)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: LinearProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  /// Construit le sélecteur de voix
  Widget _buildVoiceSelector(WeeklySummaryProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            provider.ttsProvider == TTSProvider.geminiLive
                ? Icons.auto_awesome
                : Icons.volume_up,
            size: 20,
            color: provider.ttsProvider == TTSProvider.geminiLive
                ? Colors.purple
                : Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Text(
            'Voix : ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          DropdownButton<TTSProvider>(
            value: provider.ttsProvider,
            underline: Container(),
            isDense: true,
            items: TTSProvider.values.map((provider) {
              return DropdownMenuItem(
                value: provider,
                child: Row(
                  children: [
                    Text(
                      provider.icon,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      provider.displayName,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (newProvider) {
              if (newProvider != null) {
                provider.setTTSProvider(newProvider);
              }
            },
          ),
        ],
      ),
    );
  }

  /// Construit un bouton de contrôle
  Widget _buildControlButton({
    required IconData icon,
    required String label,
    VoidCallback? onPressed,
    bool primary = false,
  }) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon),
          iconSize: 32,
          onPressed: onPressed,
          color: primary ? Theme.of(context).primaryColor : null,
          style: primary && onPressed != null
              ? IconButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                )
              : null,
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: onPressed != null ? null : Colors.grey,
          ),
        ),
      ],
    );
  }

  /// Affiche le texte du résumé généré
  Widget _buildSummaryText(WeeklySummaryProvider provider) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.text_snippet, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Résumé vocal',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                provider.summaryText!,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Affiche les données structurées du résumé
  Widget _buildSummaryData(WeeklySummaryProvider provider) {
    final data = provider.weeklySummary!;

    return Column(
      children: [
        // Section Appels
        if (data.callsToMake.isNotEmpty)
          _buildSection(
            icon: Icons.phone,
            iconColor: Colors.green,
            title: 'Appels à faire',
            count: data.callsToMake.length,
            items: data.callsToMake.map((contact) {
              final daysSince = contact.lastContactDate != null
                  ? DateTime.now().difference(contact.lastContactDate!).inDays
                  : 999;
              final subtitle = daysSince > 999
                  ? 'Jamais contacté'
                  : 'Dernier contact il y a $daysSince jours';

              return _SummaryItem(
                title: contact.contactName,
                subtitle: subtitle,
                leading: CircleAvatar(
                  backgroundColor: daysSince > 10 ? Colors.red[100] : Colors.orange[100],
                  child: Text(
                    contact.contactName.isNotEmpty
                        ? contact.contactName[0].toUpperCase()
                        : '?',
                  ),
                ),
                trailing: daysSince > 10
                    ? const Icon(Icons.priority_high, color: Colors.red)
                    : null,
              );
            }).toList(),
          ),

        // Section Anniversaires
        if (data.upcomingBirthdays.isNotEmpty)
          _buildSection(
            icon: Icons.cake,
            iconColor: Colors.pink,
            title: 'Anniversaires',
            count: data.upcomingBirthdays.length,
            items: data.upcomingBirthdays.map((contact) {
              final days = daysUntilBirthday(contact.birthday!) ?? 0;
              final dateStr = DateFormat('d MMMM', 'fr_FR').format(
                DateTime(
                  DateTime.now().year,
                  contact.birthday!.month,
                  contact.birthday!.day,
                ),
              );

              String subtitle;
              Color? avatarColor;
              if (days == 0) {
                subtitle = 'Aujourd\'hui ! 🎉';
                avatarColor = Colors.pink[100];
              } else if (days == 1) {
                subtitle = 'Demain - $dateStr';
                avatarColor = Colors.orange[100];
              } else {
                subtitle = 'Dans $days jours - $dateStr';
                avatarColor = Colors.blue[100];
              }

              return _SummaryItem(
                title: contact.contactName,
                subtitle: subtitle,
                leading: CircleAvatar(
                  backgroundColor: avatarColor,
                  child: Text('🎂'),
                ),
                trailing: days == 0
                    ? const Icon(Icons.celebration, color: Colors.pink)
                    : null,
              );
            }).toList(),
          ),

        // Section Événements
        if (data.weekEvents.isNotEmpty)
          _buildSection(
            icon: Icons.event,
            iconColor: Colors.blue,
            title: 'Événements',
            count: data.weekEvents.length,
            items: data.weekEvents.map((event) {
              final dateStr = DateFormat('EEEE d MMMM', 'fr_FR').format(event.startDate);
              final isToday = DateFormat('yyyy-MM-dd').format(event.startDate) ==
                              DateFormat('yyyy-MM-dd').format(DateTime.now());

              return _SummaryItem(
                title: event.title,
                subtitle: '$dateStr • ${event.category.displayName}',
                leading: CircleAvatar(
                  backgroundColor: _getCategoryColor(event.category).withOpacity(0.2),
                  child: Text(
                    event.category.icon,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                trailing: isToday
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'AUJOURD\'HUI',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : null,
              );
            }).toList(),
          ),
      ],
    );
  }

  /// Construit une section de données
  Widget _buildSection({
    required IconData icon,
    required Color iconColor,
    required String title,
    required int count,
    required List<_SummaryItem> items,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          ListTile(
            leading: Icon(icon, color: iconColor),
            title: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: iconColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          ...items.map((item) => ListTile(
                leading: item.leading,
                title: Text(item.title),
                subtitle: Text(item.subtitle),
                trailing: item.trailing,
              )),
        ],
      ),
    );
  }

  /// Retourne la couleur associée à une catégorie
  Color _getCategoryColor(EventCategory category) {
    switch (category) {
      case EventCategory.vacation:
        return Colors.blue;
      case EventCategory.weekend:
        return Colors.green;
      case EventCategory.shopping:
        return Colors.orange;
      case EventCategory.birthday:
        return Colors.pink;
      case EventCategory.almanac:
        return Colors.purple;
      case EventCategory.fullMoon:
        return Colors.indigo;
      case EventCategory.holiday:
        return Colors.red;
      case EventCategory.medical:
        return Colors.teal;
      case EventCategory.meeting:
        return Colors.amber;
      case EventCategory.restaurant:
        return Colors.brown;
      case EventCategory.conference:
        return Colors.deepPurple;
      case EventCategory.other:
        return Colors.grey;
    }
  }
}

/// Modèle pour un élément de résumé
class _SummaryItem {
  final String title;
  final String subtitle;
  final Widget? leading;
  final Widget? trailing;

  _SummaryItem({
    required this.title,
    required this.subtitle,
    this.leading,
    this.trailing,
  });
}