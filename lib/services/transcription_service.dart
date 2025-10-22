import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service de transcription audio via Gemini API
class TranscriptionService {
  static const String _apiKeyPrefsKey = 'gemini_api_key';

  /// Sauvegarde la clé API dans les préférences
  static Future<void> saveApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyPrefsKey, apiKey);
  }

  /// Récupère la clé API depuis les préférences
  static Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiKeyPrefsKey);
  }

  /// Vérifie si une clé API est configurée
  static Future<bool> isConfigured() async {
    final apiKey = await getApiKey();
    return apiKey != null && apiKey.isNotEmpty;
  }

  /// Supprime la clé API
  static Future<void> clearApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_apiKeyPrefsKey);
  }

  /// Transcrit un fichier audio avec Gemini
  /// Retourne le texte transcrit ou null en cas d'erreur
  static Future<String?> transcribeAudio(String audioPath) async {
    try {
      // Récupérer la clé API
      final apiKey = await getApiKey();
      if (apiKey == null || apiKey.isEmpty) {
        print('[TRANSCRIPTION] Clé API non configurée');
        return null;
      }

      print('[TRANSCRIPTION] Lecture du fichier audio: $audioPath');
      final audioFile = File(audioPath);
      if (!await audioFile.exists()) {
        print('[TRANSCRIPTION] Fichier audio introuvable: $audioPath');
        return null;
      }

      // Lire les bytes du fichier audio
      final audioBytes = await audioFile.readAsBytes();
      print('[TRANSCRIPTION] Fichier audio lu: ${audioBytes.length} bytes');

      // Créer le modèle Gemini
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
      );

      print('[TRANSCRIPTION] Envoi à Gemini pour transcription...');

      // Créer le prompt avec le fichier audio
      final prompt = TextPart(
        'Transcris cet audio en français. '
        'Retourne uniquement le texte transcrit, sans commentaire ni introduction. '
        'Si tu ne peux pas transcrire l\'audio, réponds "Transcription impossible".'
      );

      // Déterminer le type MIME selon l'extension
      String mimeType = 'audio/mp4'; // Par défaut pour .m4a
      if (audioPath.endsWith('.opus')) {
        mimeType = 'audio/ogg';
      } else if (audioPath.endsWith('.wav')) {
        mimeType = 'audio/wav';
      } else if (audioPath.endsWith('.mp3')) {
        mimeType = 'audio/mpeg';
      }

      final audioPart = DataPart(mimeType, audioBytes);

      // Générer la transcription
      final response = await model.generateContent([
        Content.multi([prompt, audioPart])
      ]);

      final transcription = response.text?.trim();
      print('[TRANSCRIPTION] Transcription reçue: ${transcription?.length ?? 0} caractères');

      if (transcription == null ||
          transcription.isEmpty ||
          transcription.toLowerCase().contains('transcription impossible')) {
        print('[TRANSCRIPTION] Transcription impossible ou vide');
        return null;
      }

      return transcription;
    } catch (e, stackTrace) {
      print('[TRANSCRIPTION] Erreur lors de la transcription: $e');
      print('[TRANSCRIPTION] Stack trace: $stackTrace');
      return null;
    }
  }

  /// Teste la clé API avec un appel simple
  static Future<bool> testApiKey(String apiKey) async {
    try {
      print('[TRANSCRIPTION] Test de la clé API (longueur: ${apiKey.length})');
      print('[TRANSCRIPTION] Début de clé: ${apiKey.substring(0, apiKey.length > 10 ? 10 : apiKey.length)}...');

      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
      );

      print('[TRANSCRIPTION] Modèle créé, envoi de la requête test...');
      final response = await model.generateContent([
        Content.text('Réponds juste "OK" sans rien d\'autre.')
      ]);

      print('[TRANSCRIPTION] Réponse reçue: ${response.text}');
      return response.text != null && response.text!.isNotEmpty;
    } catch (e) {
      print('[TRANSCRIPTION] Test API key échoué: $e');
      return false;
    }
  }
}
