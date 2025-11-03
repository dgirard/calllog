import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';
import '../models/weekly_summary.dart';
import '../models/tracked_contact.dart';
import '../models/event.dart';
import '../models/enums.dart';
import '../services/database_service.dart';
import '../services/transcription_service.dart';
import '../utils/priority_calculator.dart';
import '../utils/birthday_utils.dart';

/// Service pour générer le résumé hebdomadaire
class WeeklySummaryService {
  final DatabaseService _databaseService = DatabaseService();

  /// Collecte les données pour le résumé hebdomadaire
  Future<WeeklySummary> collectWeeklyData() async {
    final now = DateTime.now();
    final weekEnd = now.add(const Duration(days: 7));

    // Récupérer tous les contacts
    final contacts = await _databaseService.getContacts();

    // 1. Filtrer les contacts à appeler (priorité haute)
    final callsToMake = contacts.where((contact) {
      final priority = calculatePriority(contact);
      return priority == Priority.high;
    }).toList()
      ..sort((a, b) {
        // Trier par nombre de jours depuis le dernier contact
        final daysA = a.lastContactDate != null
            ? DateTime.now().difference(a.lastContactDate!).inDays
            : 999;
        final daysB = b.lastContactDate != null
            ? DateTime.now().difference(b.lastContactDate!).inDays
            : 999;
        return daysB.compareTo(daysA); // Plus de retard en premier
      });

    // 2. Filtrer les anniversaires de la semaine
    final upcomingBirthdays = contacts.where((contact) {
      if (contact.birthday == null) return false;
      final daysUntil = daysUntilBirthday(contact.birthday!);
      return daysUntil != null && daysUntil >= 0 && daysUntil <= 7;
    }).toList()
      ..sort((a, b) {
        // Trier par proximité de l'anniversaire
        final daysA = daysUntilBirthday(a.birthday!) ?? 999;
        final daysB = daysUntilBirthday(b.birthday!) ?? 999;
        return daysA.compareTo(daysB);
      });

    // 3. Récupérer les événements de la semaine
    final allEvents = await _databaseService.getEvents();
    final weekEvents = allEvents.where((event) {
      // Événement actif qui commence ou se déroule cette semaine
      if (event.status != EventStatus.active) return false;

      final eventEnd = event.endDate ?? event.startDate;

      // L'événement commence cette semaine
      final startsThisWeek = event.startDate.isAfter(now.subtract(const Duration(days: 1))) &&
                             event.startDate.isBefore(weekEnd.add(const Duration(days: 1)));

      // L'événement est en cours cette semaine
      final duringThisWeek = event.startDate.isBefore(now) &&
                             eventEnd.isAfter(now);

      return startsThisWeek || duringThisWeek;
    }).toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    return WeeklySummary(
      callsToMake: callsToMake.take(5).toList(), // Limiter à 5 appels max
      upcomingBirthdays: upcomingBirthdays,
      weekEvents: weekEvents,
      generatedAt: now,
    );
  }

  /// Génère le texte du résumé avec Gemini AI
  Future<String> generateSummaryText(WeeklySummary data) async {
    try {
      final apiKey = await TranscriptionService.getApiKey();
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('Clé API Gemini non configurée');
      }

      final model = GenerativeModel(
        model: 'gemini-2.0-flash-exp',
        apiKey: apiKey,
      );

      final prompt = _buildSummaryPrompt(data);
      final response = await model.generateContent([Content.text(prompt)]);

      if (response.text == null || response.text!.isEmpty) {
        return _generateFallbackSummary(data);
      }

      return response.text!;
    } catch (e) {
      print('Erreur génération résumé AI: $e');
      // Retourner un résumé basique en cas d'erreur
      return _generateFallbackSummary(data);
    }
  }

  /// Construit le prompt pour Gemini
  String _buildSummaryPrompt(WeeklySummary data) {
    final dateFormat = DateFormat('EEEE d MMMM yyyy', 'fr_FR');
    final now = DateTime.now();

    // Calculer les détails des appels
    final callDetails = data.callsToMake.map((contact) {
      final daysSince = contact.lastContactDate != null
          ? now.difference(contact.lastContactDate!).inDays
          : 999;
      return '- ${contact.contactName}: ${daysSince > 999 ? "jamais contacté" : "$daysSince jours de retard"}';
    }).join('\n');

    // Calculer les détails des anniversaires
    final birthdayDetails = data.upcomingBirthdays.map((contact) {
      final days = daysUntilBirthday(contact.birthday!) ?? 0;
      final birthdayStr = days == 0 ? "aujourd'hui" :
                         days == 1 ? "demain" :
                         "dans $days jours";
      return '- ${contact.contactName}: $birthdayStr';
    }).join('\n');

    // Formater les événements
    final eventDetails = data.weekEvents.map((event) {
      final dateStr = DateFormat('EEEE d MMMM', 'fr_FR').format(event.startDate);
      final categoryStr = event.category.displayName;
      return '- ${event.title} ($categoryStr): $dateStr';
    }).join('\n');

    return '''
Tu es un assistant personnel bienveillant et organisé.
Génère un résumé vocal naturel et encourageant pour la semaine à venir.

CONTEXTE:
- Date actuelle: ${dateFormat.format(now)}
- Jour de la semaine: ${DateFormat('EEEE', 'fr_FR').format(now)}
- Total d'éléments cette semaine: ${data.totalItems}

DONNÉES À RÉSUMER:

1. APPELS À FAIRE (${data.callsToMake.length}):
${callDetails.isEmpty ? 'Aucun appel urgent' : callDetails}

2. ANNIVERSAIRES (${data.upcomingBirthdays.length}):
${birthdayDetails.isEmpty ? 'Aucun anniversaire cette semaine' : birthdayDetails}

3. ÉVÉNEMENTS (${data.weekEvents.length}):
${eventDetails.isEmpty ? 'Aucun événement prévu' : eventDetails}

INSTRUCTIONS IMPORTANTES:
1. Commence par une salutation chaleureuse et naturelle
2. Structure le résumé en sections claires mais fluides
3. Pour les appels: insiste sur l'importance de maintenir le contact, surtout pour ceux avec beaucoup de retard
4. Pour les anniversaires: sois enthousiaste et rappelle l'importance du geste
5. Pour les événements: regroupe par type si pertinent, mentionne les dates importantes
6. Termine par une phrase motivante et positive
7. Utilise un ton conversationnel, comme si tu parlais à un ami proche
8. Maximum 250 mots pour une lecture de 1-2 minutes
9. Évite les listes sèches, fais des phrases naturelles
10. Si la semaine est peu chargée, valorise le temps libre

STYLE D'ÉCRITURE:
- Français naturel et fluide
- Phrases courtes et rythmées pour la lecture vocale
- Transitions douces entre les sections
- Personnalisé et empathique
- Utilise "tu" pour t'adresser à la personne

Génère UNIQUEMENT le texte du résumé vocal, sans titre ni métadonnées.
''';
  }

  /// Génère un résumé de base si l'AI échoue
  String _generateFallbackSummary(WeeklySummary data) {
    final buffer = StringBuffer();

    buffer.writeln('Bonjour ! Voici ton résumé de la semaine.');
    buffer.writeln();

    if (data.callsToMake.isNotEmpty) {
      buffer.writeln('Tu as ${data.callsToMake.length} ${data.callsToMake.length == 1 ? "appel" : "appels"} à passer cette semaine.');
      for (final contact in data.callsToMake.take(3)) {
        final daysSince = contact.lastContactDate != null
            ? DateTime.now().difference(contact.lastContactDate!).inDays
            : 999;
        if (daysSince > 999) {
          buffer.writeln('${contact.contactName}, que tu n\'as jamais contacté.');
        } else {
          buffer.writeln('${contact.contactName}, pas contacté depuis $daysSince jours.');
        }
      }
      if (data.callsToMake.length > 3) {
        buffer.writeln('Et ${data.callsToMake.length - 3} autres contacts.');
      }
      buffer.writeln();
    }

    if (data.upcomingBirthdays.isNotEmpty) {
      buffer.writeln('N\'oublie pas les anniversaires !');
      for (final contact in data.upcomingBirthdays) {
        final days = daysUntilBirthday(contact.birthday!) ?? 0;
        if (days == 0) {
          buffer.writeln('${contact.contactName} fête son anniversaire aujourd\'hui !');
        } else if (days == 1) {
          buffer.writeln('${contact.contactName} fête son anniversaire demain.');
        } else {
          buffer.writeln('${contact.contactName} dans $days jours.');
        }
      }
      buffer.writeln();
    }

    if (data.weekEvents.isNotEmpty) {
      buffer.writeln('Pour tes rendez-vous :');
      for (final event in data.weekEvents.take(5)) {
        final dateStr = DateFormat('EEEE d', 'fr_FR').format(event.startDate);
        buffer.writeln('$dateStr : ${event.title}');
      }
      if (data.weekEvents.length > 5) {
        buffer.writeln('Et ${data.weekEvents.length - 5} autres événements.');
      }
      buffer.writeln();
    }

    if (data.totalItems == 0) {
      buffer.writeln('Ta semaine est plutôt calme. Profites-en pour te reposer !');
    } else {
      buffer.writeln('Bonne semaine et bon courage pour tout gérer !');
    }

    return buffer.toString();
  }

  /// Calcule le nombre de jours de retard pour un contact
  int _getDaysOverdue(TrackedContact contact) {
    if (contact.lastContactDate == null) return 999;
    return DateTime.now().difference(contact.lastContactDate!).inDays;
  }

  /// Génère un résumé pour aujourd'hui seulement
  Future<WeeklySummary> collectDailyData() async {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));

    // Récupérer tous les contacts
    final contacts = await _databaseService.getContacts();

    // Contacts urgents à appeler aujourd'hui
    final callsToMake = contacts.where((contact) {
      final priority = calculatePriority(contact);
      return priority == Priority.high;
    }).take(3).toList(); // Maximum 3 pour le quotidien

    // Anniversaires aujourd'hui seulement
    final upcomingBirthdays = contacts.where((contact) {
      if (contact.birthday == null) return false;
      final daysUntil = daysUntilBirthday(contact.birthday!);
      return daysUntil == 0; // Aujourd'hui seulement
    }).toList();

    // Événements d'aujourd'hui
    final allEvents = await _databaseService.getEvents();
    final todayEvents = allEvents.where((event) {
      if (event.status != EventStatus.active) return false;

      final eventStart = DateTime(
        event.startDate.year,
        event.startDate.month,
        event.startDate.day,
      );
      final eventEnd = event.endDate != null
          ? DateTime(
              event.endDate!.year,
              event.endDate!.month,
              event.endDate!.day,
            )
          : eventStart;

      final today = DateTime(now.year, now.month, now.day);

      return (eventStart.isAtSameMomentAs(today) ||
              eventStart.isBefore(today)) &&
             (eventEnd.isAtSameMomentAs(today) ||
              eventEnd.isAfter(today));
    }).toList();

    return WeeklySummary(
      callsToMake: callsToMake,
      upcomingBirthdays: upcomingBirthdays,
      weekEvents: todayEvents,
      generatedAt: now,
    );
  }
}