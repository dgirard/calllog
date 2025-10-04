import 'package:flutter/foundation.dart';

/// Provider pour gérer le mode anonyme
/// Permet de masquer les données sensibles pour les démos/captures d'écran
class AnonymityProvider extends ChangeNotifier {
  bool _isAnonymousModeEnabled = false;

  bool get isAnonymousModeEnabled => _isAnonymousModeEnabled;

  void toggleAnonymousMode() {
    _isAnonymousModeEnabled = !_isAnonymousModeEnabled;
    notifyListeners();
  }

  void setAnonymousMode(bool enabled) {
    _isAnonymousModeEnabled = enabled;
    notifyListeners();
  }
}
