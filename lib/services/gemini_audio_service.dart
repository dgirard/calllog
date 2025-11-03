import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/transcription_service.dart';

/// Service pour générer de l'audio avec Gemini Live API
class GeminiAudioService {
  static final GeminiAudioService _instance = GeminiAudioService._internal();
  factory GeminiAudioService() => _instance;
  GeminiAudioService._internal();

  static const String _baseUrl = 'wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContent';

  // Modèles disponibles pour l'audio
  static const String modelFlashLive = 'gemini-live-2.5-flash-preview';
  static const String modelFlashNativeAudio = 'gemini-2.5-flash-preview-native-audio-dialog';

  WebSocketChannel? _channel;
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamController<Uint8List>? _audioStreamController;
  StreamController<Map<String, dynamic>>? _responseStreamController;

  bool _isConnected = false;
  bool _isPlaying = false;
  String _currentModel = modelFlashLive;

  bool get isConnected => _isConnected;
  bool get isPlaying => _isPlaying;
  String get currentModel => _currentModel;

  /// Liste des modèles disponibles
  static const Map<String, String> availableModels = {
    'Flash Live (Standard)': modelFlashLive,
    'Flash Native Audio (Premium)': modelFlashNativeAudio,
  };

  /// Sélectionne le modèle à utiliser
  Future<void> setModel(String model) async {
    _currentModel = model;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_audio_model', model);
  }

  /// Récupère le modèle sélectionné
  Future<String> getSelectedModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('gemini_audio_model') ?? modelFlashLive;
  }

  /// Connecte au service Gemini Live
  Future<void> connect() async {
    if (_isConnected) return;

    try {
      final apiKey = await TranscriptionService.getApiKey();
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('Clé API Gemini non configurée');
      }

      // Récupérer le modèle sélectionné
      _currentModel = await getSelectedModel();

      // Créer l'URL avec les paramètres
      final uri = Uri.parse('$_baseUrl?key=$apiKey');

      _channel = WebSocketChannel.connect(uri);
      _audioStreamController = StreamController<Uint8List>.broadcast();
      _responseStreamController = StreamController<Map<String, dynamic>>.broadcast();

      // Envoyer la configuration initiale
      final setupMessage = {
        'setup': {
          'model': 'models/$_currentModel',
          'generationConfig': {
            'responseModalities': ['AUDIO'],
            'speechConfig': {
              'voiceConfig': {
                'prebuiltVoiceConfig': {
                  'voiceName': 'Charon', // Voix française naturelle
                }
              }
            }
          }
        }
      };

      _channel!.sink.add(jsonEncode(setupMessage));
      _isConnected = true;

      // Écouter les réponses une seule fois et broadcaster
      _channel!.stream.listen(
        (data) {
          try {
            // Convertir les données en String si c'est du binaire
            final String jsonString = data is String ? data : utf8.decode(data as List<int>);
            final response = jsonDecode(jsonString);
            _responseStreamController?.add(response);
            _handleResponse(jsonString);
          } catch (e) {
            print('Erreur parsing WebSocket: $e');
          }
        },
        onError: (error) {
          print('Erreur WebSocket: $error');
          _isConnected = false;
        },
        onDone: () {
          _isConnected = false;
        },
      );
    } catch (e) {
      print('Erreur connexion Gemini Live: $e');
      _isConnected = false;
      rethrow;
    }
  }

  /// Génère de l'audio à partir du texte
  Future<void> generateAudio(String text) async {
    if (!_isConnected) {
      await connect();
    }

    try {
      // Réinitialiser le stream audio
      _audioStreamController?.close();
      _audioStreamController = StreamController<Uint8List>.broadcast();

      // Envoyer le message texte
      final message = {
        'client_content': {
          'turns': [
            {
              'role': 'user',
              'parts': [
                {'text': text}
              ]
            }
          ],
          'turn_complete': true
        }
      };

      _channel!.sink.add(jsonEncode(message));
      _isPlaying = true;
    } catch (e) {
      print('Erreur génération audio: $e');
      _isPlaying = false;
      rethrow;
    }
  }

  /// Gère les réponses du WebSocket
  void _handleResponse(dynamic data) {
    try {
      final String jsonString = data is String ? data : utf8.decode(data as List<int>);
      final response = jsonDecode(jsonString);

      // Vérifier s'il y a des données audio
      if (response['serverContent'] != null) {
        final serverContent = response['serverContent'];

        if (serverContent['modelTurn'] != null) {
          final modelTurn = serverContent['modelTurn'];

          if (modelTurn['parts'] != null) {
            for (final part in modelTurn['parts']) {
              if (part['inlineData'] != null &&
                  part['inlineData']['mimeType'] == 'audio/pcm') {
                // Décoder les données audio base64
                final audioData = base64Decode(part['inlineData']['data']);
                _audioStreamController?.add(Uint8List.fromList(audioData));
              }
            }
          }
        }

        // Vérifier si le tour est terminé
        if (serverContent['turnComplete'] == true) {
          _onAudioComplete();
        }
      }
    } catch (e) {
      print('Erreur parsing réponse: $e');
    }
  }

  /// Lit le texte avec Gemini Live Audio
  Future<void> speak(String text) async {
    try {
      await generateAudio(text);

      // Collecter toutes les données audio
      final audioChunks = <int>[];

      await for (final chunk in _audioStreamController!.stream) {
        audioChunks.addAll(chunk);
      }

      // Convertir PCM 24kHz en format jouable
      final audioData = _convertPCMToWav(Uint8List.fromList(audioChunks));

      // Jouer l'audio
      await _audioPlayer.play(BytesSource(audioData));
    } catch (e) {
      print('Erreur lecture audio: $e');
      rethrow;
    } finally {
      _isPlaying = false;
    }
  }

  /// Convertit les données PCM en WAV
  Uint8List _convertPCMToWav(Uint8List pcmData) {
    const int sampleRate = 24000;
    const int numChannels = 1;
    const int bitsPerSample = 16;

    final int byteRate = sampleRate * numChannels * bitsPerSample ~/ 8;
    final int blockAlign = numChannels * bitsPerSample ~/ 8;
    final int dataSize = pcmData.length;

    final wavHeader = BytesBuilder();

    // RIFF header
    wavHeader.add(utf8.encode('RIFF'));
    wavHeader.add(_int32ToBytes(36 + dataSize));
    wavHeader.add(utf8.encode('WAVE'));

    // fmt subchunk
    wavHeader.add(utf8.encode('fmt '));
    wavHeader.add(_int32ToBytes(16)); // Subchunk1Size
    wavHeader.add(_int16ToBytes(1)); // AudioFormat (PCM)
    wavHeader.add(_int16ToBytes(numChannels));
    wavHeader.add(_int32ToBytes(sampleRate));
    wavHeader.add(_int32ToBytes(byteRate));
    wavHeader.add(_int16ToBytes(blockAlign));
    wavHeader.add(_int16ToBytes(bitsPerSample));

    // data subchunk
    wavHeader.add(utf8.encode('data'));
    wavHeader.add(_int32ToBytes(dataSize));

    // Ajouter les données PCM
    wavHeader.add(pcmData);

    return wavHeader.toBytes();
  }

  /// Convertit un int32 en bytes (little-endian)
  List<int> _int32ToBytes(int value) {
    return [
      value & 0xFF,
      (value >> 8) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 24) & 0xFF,
    ];
  }

  /// Convertit un int16 en bytes (little-endian)
  List<int> _int16ToBytes(int value) {
    return [
      value & 0xFF,
      (value >> 8) & 0xFF,
    ];
  }

  /// Appelé quand l'audio est complètement reçu
  void _onAudioComplete() {
    _audioStreamController?.close();
    _isPlaying = false;
  }

  /// Arrête la lecture
  Future<void> stop() async {
    await _audioPlayer.stop();
    _audioStreamController?.close();
    _isPlaying = false;
  }

  /// Déconnecte du service
  void disconnect() {
    _channel?.sink.close();
    _audioStreamController?.close();
    _responseStreamController?.close();
    _isConnected = false;
    _isPlaying = false;
  }

  /// Nettoie les ressources
  void dispose() {
    disconnect();
    _audioPlayer.dispose();
  }

  /// Version simplifiée synchrone pour compatibilité
  Future<void> speakSimple(String text) async {
    if (!_isConnected) {
      await connect();
    }

    final completer = Completer<void>();
    final audioChunks = <int>[];
    Timer? inactivityTimer;

    void playAudio() {
      if (!completer.isCompleted && audioChunks.isNotEmpty) {
        print('Lecture de l\'audio: ${audioChunks.length} bytes');
        final wavData = _convertPCMToWav(Uint8List.fromList(audioChunks));
        _audioPlayer.play(BytesSource(wavData)).then((_) {
          if (!completer.isCompleted) {
            completer.complete();
          }
        });
      } else if (!completer.isCompleted && audioChunks.isEmpty) {
        print('Aucune donnée audio à lire');
        completer.complete();
      }
    }

    try {
      // Envoyer le texte
      final message = {
        'client_content': {
          'turns': [
            {
              'role': 'user',
              'parts': [
                {'text': text}  // Envoyer directement le texte sans instruction supplémentaire
              ]
            }
          ],
          'turn_complete': true
        }
      };

      print('Envoi du message à Gemini Live: ${text.substring(0, 50)}...');
      _channel!.sink.add(jsonEncode(message));

      // Écouter la réponse via le broadcast stream
      final subscription = _responseStreamController!.stream.listen((response) {
        try {
          final responseStr = response.toString();
          final previewLen = responseStr.length > 200 ? 200 : responseStr.length;
          print('Réponse Gemini: ${responseStr.substring(0, previewLen)}...');

          if (response['serverContent'] != null) {
            final serverContent = response['serverContent'];

            if (serverContent['modelTurn'] != null) {
              if (serverContent['modelTurn']['parts'] != null) {
                print('Parties trouvées: ${serverContent['modelTurn']['parts'].length}');
                for (final part in serverContent['modelTurn']['parts']) {
                  if (part['inlineData']?['mimeType']?.toString().startsWith('audio/pcm') == true) {
                    final audioData = base64Decode(part['inlineData']['data']);
                    audioChunks.addAll(audioData);
                    print('Chunk audio reçu: ${audioData.length} bytes (total: ${audioChunks.length})');

                    // Redémarrer le timer d'inactivité à chaque chunk reçu
                    inactivityTimer?.cancel();
                    inactivityTimer = Timer(const Duration(seconds: 2), () {
                      print('Pas de nouveau chunk depuis 2 secondes, lecture de l\'audio');
                      playAudio();
                    });
                  }
                }
              }
            }

            // Vérifier turnComplete
            if (serverContent['turnComplete'] == true) {
              print('turnComplete reçu!');
              inactivityTimer?.cancel();
              playAudio();
            }
          }
        } catch (e) {
          print('Erreur dans listener: $e');
          if (!completer.isCompleted) {
            completer.completeError(e);
          }
        }
      });

      // Timeout de 30 secondes
      await completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          subscription.cancel();
          inactivityTimer?.cancel();
          throw TimeoutException('Timeout lors de la génération audio');
        },
      );

      subscription.cancel();
      inactivityTimer?.cancel();
    } catch (e) {
      print('Erreur Gemini audio: $e');
      rethrow;
    }
  }
}