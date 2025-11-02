import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';
import '../models/event.dart';
import '../models/enums.dart';
import 'transcription_service.dart';

/// Données extraites du texte par l'IA
class ParsedEventData {
  final String title;
  final String? description;
  final DateTime startDate;
  final DateTime? endDate;
  final EventCategory category;
  final double confidence;
  final String? rawTranscript;

  ParsedEventData({
    required this.title,
    this.description,
    required this.startDate,
    this.endDate,
    required this.category,
    required this.confidence,
    this.rawTranscript,
  });

  /// Convertit en objet Event
  Event toEvent() {
    return Event(
      title: title,
      description: description,
      startDate: startDate,
      endDate: endDate,
      category: category,
      status: EventStatus.active,
    );
  }
}

/// Service pour extraire les informations d'événement depuis un texte
class EventParsingService {
  static const String _modelName = 'gemini-2.5-flash';

  /// Analyse un texte et extrait les informations d'événement
  static Future<ParsedEventData?> parseEventFromText(String transcript) async {
    try {
      // Vérifier que l'API Gemini est configurée
      final apiKey = await TranscriptionService.getApiKey();
      if (apiKey == null) {
        debugPrint('EventParsingService: Clé API Gemini non configurée');
        return null;
      }

      // Initialiser le modèle Gemini
      final model = GenerativeModel(
        model: _modelName,
        apiKey: apiKey,
      );

      // Construire le prompt avec la date du jour
      final today = DateTime.now();
      final todayStr = DateFormat('yyyy-MM-dd').format(today);
      final dayOfWeek = _getDayOfWeekInFrench(today.weekday);

      final prompt = _buildPrompt(transcript, todayStr, dayOfWeek);

      // Appeler Gemini pour analyser le texte
      debugPrint('EventParsingService: Analyse du texte...');
      final response = await model.generateContent([Content.text(prompt)]);

      if (response.text == null) {
        debugPrint('EventParsingService: Réponse vide de Gemini');
        return null;
      }

      debugPrint('EventParsingService: Réponse brute: ${response.text}');

      // Parser la réponse JSON
      final parsedData = _parseResponse(response.text!, transcript);

      if (parsedData != null) {
        debugPrint('EventParsingService: Événement extrait avec succès');
        debugPrint('  Titre: ${parsedData.title}');
        debugPrint('  Date début: ${parsedData.startDate}');
        debugPrint('  Date fin: ${parsedData.endDate}');
        debugPrint('  Catégorie: ${parsedData.category}');
        debugPrint('  Confiance: ${parsedData.confidence}');
      }

      return parsedData;

    } catch (e) {
      debugPrint('EventParsingService: Erreur lors du parsing: $e');
      return null;
    }
  }

  /// Construit le prompt pour Gemini
  static String _buildPrompt(String transcript, String todayStr, String dayOfWeek) {
    return '''
Tu es un assistant d'analyse de texte français spécialisé dans l'extraction d'informations d'événements.

CONTEXTE TEMPOREL:
- Aujourd'hui nous sommes le $dayOfWeek $todayStr
- Utilise cette date comme référence pour les dates relatives

CATÉGORIES DISPONIBLES:
- "vacation": vacances, congés, voyage, séjour
- "weekend": week-end, samedi et dimanche, fin de semaine
- "shopping": courses, achats, magasin, marché
- "birthday": anniversaire, fête d'anniversaire
- "almanac": saint, fête (religieuse), éphéméride
- "fullMoon": pleine lune, lune
- "holiday": jour férié, fête nationale
- "medical": médecin, dentiste, rdv médical, santé, consultation, hôpital
- "meeting": réunion, rendez-vous professionnel, entretien
- "restaurant": restaurant, resto, dîner, déjeuner, repas, brasserie, café, bistrot
- "conference": conférence, séminaire, colloque, symposium, congrès, formation, webinaire, présentation
- "other": tout ce qui ne correspond pas aux catégories ci-dessus

RÈGLES D'EXTRACTION:
1. Si aucune date n'est mentionnée, utilise la date d'aujourd'hui
2. Pour "demain", ajoute 1 jour à aujourd'hui
3. Pour "après-demain", ajoute 2 jours
4. Pour "lundi prochain" (ou autre jour), trouve le prochain jour de la semaine
5. Pour "dans X jours/semaines/mois", calcule depuis aujourd'hui
6. Pour "le 15 mars" sans année, utilise l'année courante si la date est future, sinon l'année prochaine
7. Pour "week-end", utilise samedi et dimanche de cette semaine ou de la semaine prochaine selon le contexte
8. Si une plage de dates est mentionnée (du X au Y), définis startDate et endDate
9. Le titre doit être court et descriptif (max 5 mots)
10. La description contient les détails supplémentaires

TEXTE À ANALYSER:
"$transcript"

INSTRUCTIONS:
Analyse le texte ci-dessus et réponds UNIQUEMENT avec un objet JSON valide (sans texte avant ou après) contenant:
{
  "title": "titre court de l'événement",
  "description": "détails supplémentaires ou null si aucun",
  "startDate": "date de début au format ISO8601 (YYYY-MM-DD)",
  "endDate": "date de fin au format ISO8601 ou null si événement sur un jour",
  "category": "une des catégories listées ci-dessus",
  "confidence": nombre entre 0.0 et 1.0 indiquant la confiance de l'extraction
}

IMPORTANT: Réponds UNIQUEMENT avec le JSON, sans aucun texte additionnel.
''';
  }

  /// Parse la réponse JSON de Gemini
  static ParsedEventData? _parseResponse(String response, String originalTranscript) {
    try {
      // Nettoyer la réponse (enlever les éventuels caractères avant/après le JSON)
      String cleanedResponse = response.trim();

      // Si la réponse commence par ```json, enlever les marqueurs
      if (cleanedResponse.startsWith('```json')) {
        cleanedResponse = cleanedResponse.substring(7);
      }
      if (cleanedResponse.startsWith('```')) {
        cleanedResponse = cleanedResponse.substring(3);
      }
      if (cleanedResponse.endsWith('```')) {
        cleanedResponse = cleanedResponse.substring(0, cleanedResponse.length - 3);
      }
      cleanedResponse = cleanedResponse.trim();

      // Trouver le début et la fin du JSON
      final startIndex = cleanedResponse.indexOf('{');
      final endIndex = cleanedResponse.lastIndexOf('}');

      if (startIndex == -1 || endIndex == -1) {
        debugPrint('EventParsingService: Pas de JSON trouvé dans la réponse');
        return null;
      }

      cleanedResponse = cleanedResponse.substring(startIndex, endIndex + 1);

      // Parser le JSON
      final json = jsonDecode(cleanedResponse);

      // Valider et extraire les données
      final title = json['title'] as String?;
      if (title == null || title.isEmpty) {
        debugPrint('EventParsingService: Titre manquant');
        return null;
      }

      // Parser les dates
      final startDateStr = json['startDate'] as String?;
      if (startDateStr == null) {
        debugPrint('EventParsingService: Date de début manquante');
        return null;
      }

      DateTime startDate;
      try {
        startDate = DateTime.parse(startDateStr);
      } catch (e) {
        debugPrint('EventParsingService: Erreur parsing date début: $startDateStr');
        return null;
      }

      DateTime? endDate;
      final endDateStr = json['endDate'] as String?;
      if (endDateStr != null && endDateStr != 'null') {
        try {
          endDate = DateTime.parse(endDateStr);
        } catch (e) {
          debugPrint('EventParsingService: Erreur parsing date fin: $endDateStr');
        }
      }

      // Parser la catégorie
      final categoryStr = json['category'] as String? ?? 'other';
      EventCategory category;
      try {
        category = EventCategory.values.firstWhere(
          (c) => c.toString().split('.').last == categoryStr,
          orElse: () => EventCategory.other,
        );
      } catch (e) {
        category = EventCategory.other;
      }

      // Extraire la confiance
      final confidence = (json['confidence'] as num?)?.toDouble() ?? 0.5;

      // Extraire la description
      final description = json['description'] as String?;

      return ParsedEventData(
        title: title,
        description: description?.isNotEmpty == true ? description : null,
        startDate: startDate,
        endDate: endDate,
        category: category,
        confidence: confidence,
        rawTranscript: originalTranscript,
      );

    } catch (e) {
      debugPrint('EventParsingService: Erreur parsing JSON: $e');
      debugPrint('EventParsingService: Réponse reçue: $response');
      return null;
    }
  }

  /// Retourne le jour de la semaine en français
  static String _getDayOfWeekInFrench(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'lundi';
      case DateTime.tuesday:
        return 'mardi';
      case DateTime.wednesday:
        return 'mercredi';
      case DateTime.thursday:
        return 'jeudi';
      case DateTime.friday:
        return 'vendredi';
      case DateTime.saturday:
        return 'samedi';
      case DateTime.sunday:
        return 'dimanche';
      default:
        return '';
    }
  }

  /// Méthode de test pour vérifier le parsing avec différentes phrases
  static Future<void> testParsing() async {
    final testPhrases = [
      "Vacances du 15 au 22 juillet à la montagne",
      "RDV dentiste demain à 14h",
      "Anniversaire de Marie le 3 avril",
      "Courses demain matin",
      "Réunion d'équipe dans 3 jours",
      "Week-end à Paris",
      "Jour férié le 14 juillet",
      "Rendez-vous médical le 20 après-midi",
    ];

    for (final phrase in testPhrases) {
      debugPrint('\n=== Test: "$phrase" ===');
      final result = await parseEventFromText(phrase);
      if (result != null) {
        debugPrint('✓ Titre: ${result.title}');
        debugPrint('✓ Description: ${result.description}');
        debugPrint('✓ Date début: ${result.startDate}');
        debugPrint('✓ Date fin: ${result.endDate}');
        debugPrint('✓ Catégorie: ${result.category}');
        debugPrint('✓ Confiance: ${(result.confidence * 100).toStringAsFixed(0)}%');
      } else {
        debugPrint('✗ Échec du parsing');
      }
    }
  }
}