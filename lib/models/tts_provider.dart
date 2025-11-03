/// Énumération des fournisseurs de synthèse vocale
enum TTSProvider {
  local,       // flutter_tts (voix système)
  geminiLive,  // Gemini Live API (voix premium)
}

/// Extension pour le provider TTS
extension TTSProviderExtension on TTSProvider {
  String get displayName {
    switch (this) {
      case TTSProvider.local:
        return 'Voix locale';
      case TTSProvider.geminiLive:
        return 'Gemini Live (Premium)';
    }
  }

  String get description {
    switch (this) {
      case TTSProvider.local:
        return 'Utilise la synthèse vocale de votre appareil';
      case TTSProvider.geminiLive:
        return 'Voix naturelle et expressive via Gemini AI';
    }
  }

  String get icon {
    switch (this) {
      case TTSProvider.local:
        return '📱';
      case TTSProvider.geminiLive:
        return '✨';
    }
  }
}