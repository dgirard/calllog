import 'package:flutter/material.dart';
import '../models/weekly_summary.dart';
import '../services/weekly_summary_service.dart';
import '../services/text_to_speech_service.dart';

/// Provider pour gérer l'état du résumé hebdomadaire
class WeeklySummaryProvider extends ChangeNotifier {
  final WeeklySummaryService _summaryService = WeeklySummaryService();
  final TextToSpeechService _ttsService = TextToSpeechService();

  WeeklySummary? _weeklySummary;
  String? _summaryText;
  bool _isLoading = false;
  bool _isGenerating = false;
  bool _isPlaying = false;
  String? _error;
  SummaryType _currentType = SummaryType.weekly;

  // Getters
  WeeklySummary? get weeklySummary => _weeklySummary;
  String? get summaryText => _summaryText;
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;
  bool get isPlaying => _isPlaying;
  String? get error => _error;
  SummaryType get currentType => _currentType;
  bool get hasData => _weeklySummary != null && _weeklySummary!.hasContent;

  /// Initialise le provider
  Future<void> initialize() async {
    try {
      await _ttsService.initialize();
      await _ttsService.setOptimalFrenchVoice();
    } catch (e) {
      print('Erreur initialisation TTS: $e');
    }
  }

  /// Change le type de résumé
  void setSummaryType(SummaryType type) {
    if (_currentType != type) {
      _currentType = type;
      _weeklySummary = null;
      _summaryText = null;
      _error = null;
      notifyListeners();
    }
  }

  /// Charge les données du résumé
  Future<void> loadSummaryData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Charger les données selon le type
      if (_currentType == SummaryType.daily) {
        _weeklySummary = await _summaryService.collectDailyData();
      } else {
        _weeklySummary = await _summaryService.collectWeeklyData();
      }
    } catch (e) {
      _error = 'Erreur lors du chargement des données: $e';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Génère le texte du résumé avec l'IA
  Future<void> generateSummaryText() async {
    if (_weeklySummary == null) {
      await loadSummaryData();
    }

    if (_weeklySummary == null) return;

    _isGenerating = true;
    _error = null;
    notifyListeners();

    try {
      _summaryText = await _summaryService.generateSummaryText(_weeklySummary!);

      // Mettre à jour le modèle avec le texte généré
      _weeklySummary = _weeklySummary!.withSummaryText(_summaryText!);
    } catch (e) {
      _error = 'Erreur lors de la génération du résumé: $e';
      print(_error);

      // Utiliser un résumé de base en cas d'erreur
      _summaryText = _buildBasicSummary();
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  /// Lance la lecture vocale du résumé
  Future<void> playSummary() async {
    if (_summaryText == null || _summaryText!.isEmpty) {
      await generateSummaryText();
    }

    if (_summaryText == null || _summaryText!.isEmpty) return;

    _isPlaying = true;
    notifyListeners();

    try {
      await _ttsService.speak(_summaryText!);
      // Le TTS notifiera quand la lecture sera terminée via les handlers
    } catch (e) {
      _error = 'Erreur lors de la lecture: $e';
      _isPlaying = false;
      notifyListeners();
    }
  }

  /// Met en pause la lecture
  Future<void> pauseSummary() async {
    await _ttsService.pause();
    _isPlaying = false;
    notifyListeners();
  }

  /// Arrête la lecture
  Future<void> stopSummary() async {
    await _ttsService.stop();
    _isPlaying = false;
    notifyListeners();
  }

  /// Régénère complètement le résumé
  Future<void> regenerateSummary() async {
    _weeklySummary = null;
    _summaryText = null;
    _error = null;
    notifyListeners();

    await loadSummaryData();
    if (_weeklySummary != null && _weeklySummary!.hasContent) {
      await generateSummaryText();
    }
  }

  /// Configure la vitesse de lecture
  Future<void> setSpeechRate(double rate) async {
    await _ttsService.setSpeechRate(rate);
  }

  /// Configure le volume
  Future<void> setVolume(double volume) async {
    await _ttsService.setVolume(volume);
  }

  /// Configure la tonalité
  Future<void> setPitch(double pitch) async {
    await _ttsService.setPitch(pitch);
  }

  /// Génère un résumé basique sans IA
  String _buildBasicSummary() {
    if (_weeklySummary == null) return 'Aucune donnée disponible.';

    final buffer = StringBuffer();
    final data = _weeklySummary!;

    buffer.writeln('Voici ton résumé ${_currentType == SummaryType.daily ? "du jour" : "de la semaine"}.');

    if (data.callsToMake.isNotEmpty) {
      buffer.writeln('Tu as ${data.callsToMake.length} appels à passer.');
    }

    if (data.upcomingBirthdays.isNotEmpty) {
      buffer.writeln('${data.upcomingBirthdays.length} anniversaires à souhaiter.');
    }

    if (data.weekEvents.isNotEmpty) {
      buffer.writeln('${data.weekEvents.length} événements prévus.');
    }

    if (!data.hasContent) {
      buffer.writeln('Rien de particulier à signaler. Profite de ton temps libre !');
    }

    return buffer.toString();
  }

  /// Nettoie les ressources
  @override
  void dispose() {
    _ttsService.dispose();
    super.dispose();
  }

  /// Retourne un résumé textuel des statistiques
  String getStatsSummary() {
    if (_weeklySummary == null) return '';

    final data = _weeklySummary!;
    final parts = <String>[];

    if (data.callsToMake.isNotEmpty) {
      parts.add('${data.callsToMake.length} appel${data.callsToMake.length > 1 ? 's' : ''}');
    }

    if (data.upcomingBirthdays.isNotEmpty) {
      parts.add('${data.upcomingBirthdays.length} anniversaire${data.upcomingBirthdays.length > 1 ? 's' : ''}');
    }

    if (data.weekEvents.isNotEmpty) {
      parts.add('${data.weekEvents.length} événement${data.weekEvents.length > 1 ? 's' : ''}');
    }

    if (parts.isEmpty) {
      return 'Aucune tâche cette ${_currentType == SummaryType.daily ? 'journée' : 'semaine'}';
    }

    return parts.join(', ');
  }

  /// Vérifie si le résumé est vide
  bool get isEmpty => _weeklySummary == null || !_weeklySummary!.hasContent;

  /// Retourne true si on peut lire le résumé
  bool get canPlay => _summaryText != null && _summaryText!.isNotEmpty && !_isPlaying;

  /// Retourne true si on peut mettre en pause
  bool get canPause => _isPlaying;

  /// Retourne true si on peut arrêter
  bool get canStop => _isPlaying;
}