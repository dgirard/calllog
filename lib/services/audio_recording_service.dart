import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:crypto/crypto.dart';

/// Erreurs possibles lors de l'enregistrement audio
enum AudioErrorType {
  permissionDenied,
  permissionPermanentlyDenied,
  insufficientStorage,
  recordingFailed,
  fileNotFound,
  unknown,
}

/// Classe d'erreur personnalisée pour l'audio
class AudioError {
  final AudioErrorType type;
  final String message;

  AudioError(this.type, this.message);

  @override
  String toString() => 'AudioError: $message (${type.name})';
}

/// Résultat d'une opération audio (Success ou Error)
class AudioResult<T> {
  final T? data;
  final AudioError? error;

  AudioResult.success(this.data) : error = null;
  AudioResult.failure(this.error) : data = null;

  bool get isSuccess => error == null;
  bool get isFailure => error != null;
}

/// Métadonnées d'un enregistrement audio
class AudioMetadata {
  final String path;
  final Duration duration;
  final int fileSizeBytes;
  final String checksum;
  final DateTime createdAt;

  AudioMetadata({
    required this.path,
    required this.duration,
    required this.fileSizeBytes,
    required this.checksum,
    required this.createdAt,
  });
}

/// Service de gestion de l'enregistrement audio
class AudioRecordingService {
  final AudioRecorder _recorder = AudioRecorder();
  DateTime? _recordingStartTime;
  String? _currentRecordingPath;

  /// Seuil minimum d'espace disque requis (100 MB)
  static const int minStorageBytes = 100 * 1024 * 1024;

  /// Vérifie et demande la permission microphone
  Future<AudioResult<bool>> requestMicrophonePermission() async {
    try {
      final status = await Permission.microphone.status;

      if (status.isGranted) {
        return AudioResult.success(true);
      }

      if (status.isPermanentlyDenied) {
        return AudioResult.failure(
          AudioError(
            AudioErrorType.permissionPermanentlyDenied,
            'Permission microphone refusée définitivement. '
            'Veuillez l\'activer dans les paramètres de l\'application.',
          ),
        );
      }

      // Demander la permission
      final result = await Permission.microphone.request();

      if (result.isGranted) {
        return AudioResult.success(true);
      } else if (result.isPermanentlyDenied) {
        return AudioResult.failure(
          AudioError(
            AudioErrorType.permissionPermanentlyDenied,
            'Permission microphone refusée définitivement. '
            'Veuillez l\'activer dans les paramètres de l\'application.',
          ),
        );
      } else {
        return AudioResult.failure(
          AudioError(
            AudioErrorType.permissionDenied,
            'Permission microphone refusée. '
            'L\'enregistrement audio nécessite l\'accès au microphone.',
          ),
        );
      }
    } catch (e) {
      return AudioResult.failure(
        AudioError(
          AudioErrorType.unknown,
          'Erreur lors de la vérification des permissions: $e',
        ),
      );
    }
  }

  /// Vérifie l'espace disque disponible
  Future<AudioResult<bool>> _checkStorageSpace() async {
    try {
      final dir = await getApplicationDocumentsDirectory();

      try {
        final testFile = File(p.join(dir.path, '.storage_test'));
        await testFile.writeAsString('test');
        await testFile.delete();
        return AudioResult.success(true);
      } catch (e) {
        return AudioResult.failure(
          AudioError(
            AudioErrorType.insufficientStorage,
            'Espace de stockage insuffisant. '
            'Libérez au moins 100 MB pour continuer.',
          ),
        );
      }
    } catch (e) {
      return AudioResult.failure(
        AudioError(
          AudioErrorType.unknown,
          'Erreur lors de la vérification de l\'espace disque: $e',
        ),
      );
    }
  }

  /// Génère le chemin de fichier pour un nouvel enregistrement
  Future<String> _generateAudioPath(int contactId) async {
    final appDir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final audioDir = Directory(p.join(appDir.path, 'audio', 'contact_$contactId'));

    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }

    return p.join(audioDir.path, '$timestamp.m4a');
  }

  /// Démarre l'enregistrement audio
  Future<AudioResult<String>> startRecording({
    required int contactId,
  }) async {
    try {
      // Vérifier permission
      final permissionResult = await requestMicrophonePermission();
      if (permissionResult.isFailure) {
        return AudioResult.failure(permissionResult.error!);
      }

      // Vérifier espace disque
      final storageResult = await _checkStorageSpace();
      if (storageResult.isFailure) {
        return AudioResult.failure(storageResult.error!);
      }

      // Vérifier qu'aucun enregistrement n'est en cours
      if (await _recorder.isRecording()) {
        return AudioResult.failure(
          AudioError(
            AudioErrorType.recordingFailed,
            'Un enregistrement est déjà en cours.',
          ),
        );
      }

      // Générer le chemin du fichier
      final path = await _generateAudioPath(contactId);
      _currentRecordingPath = path;
      _recordingStartTime = DateTime.now();

      // Configuration de l'enregistrement
      // AAC pour iOS, Opus pour Android
      final config = RecordConfig(
        encoder: Platform.isIOS ? AudioEncoder.aacLc : AudioEncoder.opus,
        bitRate: 128000,
        sampleRate: 44100,
      );

      // Démarrer l'enregistrement audio
      await _recorder.start(config, path: path);

      return AudioResult.success(path);
    } catch (e) {
      _currentRecordingPath = null;
      _recordingStartTime = null;
      return AudioResult.failure(
        AudioError(
          AudioErrorType.recordingFailed,
          'Échec du démarrage de l\'enregistrement: $e',
        ),
      );
    }
  }

  /// Arrête l'enregistrement et retourne les métadonnées
  Future<AudioResult<AudioMetadata>> stopRecording() async {
    try {
      if (!await _recorder.isRecording()) {
        return AudioResult.failure(
          AudioError(
            AudioErrorType.recordingFailed,
            'Aucun enregistrement en cours.',
          ),
        );
      }

      final path = await _recorder.stop();

      if (path == null || _currentRecordingPath == null) {
        return AudioResult.failure(
          AudioError(
            AudioErrorType.recordingFailed,
            'Échec de la sauvegarde de l\'enregistrement.',
          ),
        );
      }

      // Calculer les métadonnées
      final file = File(path);
      if (!await file.exists()) {
        return AudioResult.failure(
          AudioError(
            AudioErrorType.fileNotFound,
            'Le fichier audio n\'a pas été créé.',
          ),
        );
      }

      final fileSize = await file.length();
      final duration = _recordingStartTime != null
          ? DateTime.now().difference(_recordingStartTime!)
          : Duration.zero;

      // Calculer le checksum MD5
      final bytes = await file.readAsBytes();
      final checksum = md5.convert(bytes).toString();

      final metadata = AudioMetadata(
        path: path,
        duration: duration,
        fileSizeBytes: fileSize,
        checksum: checksum,
        createdAt: _recordingStartTime ?? DateTime.now(),
      );

      // Reset
      _currentRecordingPath = null;
      _recordingStartTime = null;

      return AudioResult.success(metadata);
    } catch (e) {
      _currentRecordingPath = null;
      _recordingStartTime = null;
      return AudioResult.failure(
        AudioError(
          AudioErrorType.recordingFailed,
          'Erreur lors de l\'arrêt de l\'enregistrement: $e',
        ),
      );
    }
  }

  /// Pause l'enregistrement
  Future<AudioResult<void>> pauseRecording() async {
    try {
      if (!await _recorder.isRecording()) {
        return AudioResult.failure(
          AudioError(
            AudioErrorType.recordingFailed,
            'Aucun enregistrement en cours.',
          ),
        );
      }

      await _recorder.pause();
      return AudioResult.success(null);
    } catch (e) {
      return AudioResult.failure(
        AudioError(
          AudioErrorType.recordingFailed,
          'Erreur lors de la pause de l\'enregistrement: $e',
        ),
      );
    }
  }

  /// Reprend l'enregistrement
  Future<AudioResult<void>> resumeRecording() async {
    try {
      if (!await _recorder.isPaused()) {
        return AudioResult.failure(
          AudioError(
            AudioErrorType.recordingFailed,
            'L\'enregistrement n\'est pas en pause.',
          ),
        );
      }

      await _recorder.resume();
      return AudioResult.success(null);
    } catch (e) {
      return AudioResult.failure(
        AudioError(
          AudioErrorType.recordingFailed,
          'Erreur lors de la reprise de l\'enregistrement: $e',
        ),
      );
    }
  }

  /// Vérifie si un enregistrement est en cours
  Future<bool> isRecording() async {
    return await _recorder.isRecording();
  }

  /// Vérifie si l'enregistrement est en pause
  Future<bool> isPaused() async {
    return await _recorder.isPaused();
  }

  /// Obtient la durée actuelle de l'enregistrement
  Duration? getCurrentDuration() {
    if (_recordingStartTime == null) return null;
    return DateTime.now().difference(_recordingStartTime!);
  }

  /// Annule l'enregistrement en cours et supprime le fichier
  Future<AudioResult<void>> cancelRecording() async {
    try {
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }

      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }

      _currentRecordingPath = null;
      _recordingStartTime = null;

      return AudioResult.success(null);
    } catch (e) {
      return AudioResult.failure(
        AudioError(
          AudioErrorType.unknown,
          'Erreur lors de l\'annulation de l\'enregistrement: $e',
        ),
      );
    }
  }

  /// Libère les ressources
  Future<void> dispose() async {
    await _recorder.dispose();
  }
}
