import 'package:flutter_tts/flutter_tts.dart';

/// Service de synthèse vocale (Text-to-Speech)
class TextToSpeechService {
  static final TextToSpeechService _instance = TextToSpeechService._internal();
  factory TextToSpeechService() => _instance;
  TextToSpeechService._internal();

  final FlutterTts _tts = FlutterTts();

  bool _isInitialized = false;
  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;

  /// Initialise le service TTS avec la configuration française
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Configuration pour le français
      await _tts.setLanguage('fr-FR');
      await _tts.setSpeechRate(0.5); // Vitesse normale
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      // Configuration pour iOS
      await _tts.setSharedInstance(true);
      await _tts.setIosAudioCategory(IosTextToSpeechAudioCategory.playback,
          [
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
            IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
            IosTextToSpeechAudioCategoryOptions.mixWithOthers,
          ],
          IosTextToSpeechAudioMode.voicePrompt
      );

      // Listeners pour les états
      _tts.setStartHandler(() {
        _isPlaying = true;
      });

      _tts.setCompletionHandler(() {
        _isPlaying = false;
      });

      _tts.setErrorHandler((msg) {
        _isPlaying = false;
        print('Erreur TTS: $msg');
      });

      _tts.setCancelHandler(() {
        _isPlaying = false;
      });

      _isInitialized = true;
    } catch (e) {
      print('Erreur lors de l\'initialisation TTS: $e');
      throw Exception('Impossible d\'initialiser la synthèse vocale');
    }
  }

  /// Lit le texte à haute voix
  Future<void> speak(String text) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (text.isEmpty) return;

    // Arrêter toute lecture en cours
    await stop();

    // Diviser le texte en segments si trop long (limite iOS/Android)
    const maxLength = 4000;
    if (text.length > maxLength) {
      // Diviser le texte par phrases
      final sentences = text.split(RegExp(r'[.!?]+'));
      String currentSegment = '';

      for (final sentence in sentences) {
        if (currentSegment.length + sentence.length < maxLength) {
          currentSegment += sentence + '. ';
        } else {
          if (currentSegment.isNotEmpty) {
            await _tts.speak(currentSegment.trim());
            await _tts.awaitSpeakCompletion(true);
          }
          currentSegment = sentence + '. ';
        }
      }

      // Lire le dernier segment
      if (currentSegment.isNotEmpty) {
        await _tts.speak(currentSegment.trim());
      }
    } else {
      await _tts.speak(text);
    }
  }

  /// Met en pause la lecture
  Future<void> pause() async {
    if (_isPlaying) {
      await _tts.pause();
      _isPlaying = false;
    }
  }

  /// Arrête la lecture
  Future<void> stop() async {
    await _tts.stop();
    _isPlaying = false;
  }

  /// Configure la vitesse de lecture (0.0 - 1.0)
  Future<void> setSpeechRate(double rate) async {
    await _tts.setSpeechRate(rate.clamp(0.0, 1.0));
  }

  /// Configure le volume (0.0 - 1.0)
  Future<void> setVolume(double volume) async {
    await _tts.setVolume(volume.clamp(0.0, 1.0));
  }

  /// Configure la tonalité (0.5 - 2.0)
  Future<void> setPitch(double pitch) async {
    await _tts.setPitch(pitch.clamp(0.5, 2.0));
  }

  /// Retourne les langues disponibles
  Future<List<dynamic>> getLanguages() async {
    return await _tts.getLanguages;
  }

  /// Retourne les voix disponibles
  Future<List<dynamic>> getVoices() async {
    return await _tts.getVoices;
  }

  /// Configure une voix spécifique
  Future<void> setVoice(Map<String, String> voice) async {
    await _tts.setVoice(voice);
  }

  /// Vérifie si une langue est disponible
  Future<bool> isLanguageAvailable(String language) async {
    return await _tts.isLanguageAvailable(language);
  }

  /// Retourne les voix françaises disponibles
  Future<List<Map<String, String>>> getFrenchVoices() async {
    final voices = await _tts.getVoices;
    return voices
        .where((voice) =>
            voice['locale']?.toString().startsWith('fr') ?? false)
        .map((voice) => Map<String, String>.from(voice))
        .toList();
  }

  /// Sélectionne la meilleure voix française disponible
  Future<void> setOptimalFrenchVoice() async {
    final frenchVoices = await getFrenchVoices();

    if (frenchVoices.isNotEmpty) {
      // Préférer les voix de qualité supérieure
      final preferredVoices = frenchVoices.where((voice) {
        final name = voice['name']?.toLowerCase() ?? '';
        // Préférer les voix féminines françaises de haute qualité
        return name.contains('amelie') ||
               name.contains('thomas') ||
               name.contains('premium') ||
               name.contains('enhanced');
      }).toList();

      if (preferredVoices.isNotEmpty) {
        await setVoice(preferredVoices.first);
      } else {
        // Utiliser la première voix française disponible
        await setVoice(frenchVoices.first);
      }
    }
  }

  /// Nettoie les ressources
  void dispose() {
    stop();
  }
}