import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service de transcription audio via Gemini API
class TranscriptionService {
  static const String _apiKeyStorageKey = 'gemini_api_key';
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  /// Sauvegarde la clé API de manière sécurisée
  static Future<void> saveApiKey(String apiKey) async {
    await _secureStorage.write(key: _apiKeyStorageKey, value: apiKey);
  }

  /// Récupère la clé API depuis le stockage sécurisé
  static Future<String?> getApiKey() async {
    return await _secureStorage.read(key: _apiKeyStorageKey);
  }

  /// Vérifie si une clé API est configurée
  static Future<bool> isConfigured() async {
    final apiKey = await getApiKey();
    return apiKey != null && apiKey.isNotEmpty;
  }

  /// Supprime la clé API
  static Future<void> clearApiKey() async {
    await _secureStorage.delete(key: _apiKeyStorageKey);
  }

  /// Transcrit un fichier audio avec Gemini
  /// Retourne le texte transcrit ou null en cas d'erreur
  static Future<String?> transcribeAudio(String audioPath) async {
    try {
      // Récupérer la clé API
      final apiKey = await getApiKey();
      if (apiKey == null || apiKey.isEmpty) {
        if (kDebugMode) {
          print('[TRANSCRIPTION] Clé API non configurée');
        }
        return null;
      }

      if (kDebugMode) {
        print('[TRANSCRIPTION] Lecture du fichier audio: $audioPath');
      }
      final audioFile = File(audioPath);
      if (!await audioFile.exists()) {
        if (kDebugMode) {
          print('[TRANSCRIPTION] Fichier audio introuvable: $audioPath');
        }
        return null;
      }

      // Lire les bytes du fichier audio
      final audioBytes = await audioFile.readAsBytes();
      if (kDebugMode) {
        print('[TRANSCRIPTION] Fichier audio lu: ${audioBytes.length} bytes');
      }

      // Créer le modèle Gemini
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
      );

      if (kDebugMode) {
        print('[TRANSCRIPTION] Envoi à Gemini pour transcription...');
      }

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
      if (kDebugMode) {
        print('[TRANSCRIPTION] Transcription reçue: ${transcription?.length ?? 0} caractères');
      }

      if (transcription == null ||
          transcription.isEmpty ||
          transcription.toLowerCase().contains('transcription impossible')) {
        if (kDebugMode) {
          print('[TRANSCRIPTION] Transcription impossible ou vide');
        }
        return null;
      }

      return transcription;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('[TRANSCRIPTION] Erreur lors de la transcription: $e');
        print('[TRANSCRIPTION] Stack trace: $stackTrace');
      }
      return null;
    }
  }

  /// Teste la clé API avec un appel simple
  static Future<bool> testApiKey(String apiKey) async {
    try {
      if (kDebugMode) {
        print('[TRANSCRIPTION] Test de la clé API (longueur: ${apiKey.length})');
        // Ne jamais logger la clé elle-même, même partiellement
      }

      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
      );

      if (kDebugMode) {
        print('[TRANSCRIPTION] Modèle créé, envoi de la requête test...');
      }
      final response = await model.generateContent([
        Content.text('Réponds juste "OK" sans rien d\'autre.')
      ]);

      if (kDebugMode) {
        print('[TRANSCRIPTION] Réponse reçue: ${response.text}');
      }
      return response.text != null && response.text!.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('[TRANSCRIPTION] Test API key échoué: $e');
      }
      return false;
    }
  }
}
