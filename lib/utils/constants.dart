import 'package:flutter/material.dart';
import '../models/enums.dart';

/// Constantes de l'application CallLog

// ==================== Durées ====================

/// Durées en jours pour chaque fréquence d'appel
const Map<CallFrequency, int> frequencyDurations = {
  CallFrequency.weekly: 7,
  CallFrequency.biweekly: 14,
  CallFrequency.monthly: 30,
  CallFrequency.quarterly: 90,
  CallFrequency.yearly: 365,
};

/// Seuil pour anniversaire proche (en jours)
const int birthdayThresholdDays = 7;

/// Seuil pour priorité moyenne (95% du délai attendu)
const double mediumPriorityThreshold = 0.95;

// ==================== Couleurs ====================

/// Couleurs pour les différents niveaux de priorité
const Map<Priority, Color> priorityColors = {
  Priority.high: Colors.red,         // Rouge : en retard
  Priority.medium: Colors.orange,    // Orange : bientôt
  Priority.low: Colors.green,        // Vert : à jour
  Priority.birthday: Colors.purple,  // Violet : anniversaire
};

/// Couleurs pour les catégories de contacts
const Map<ContactCategory, Color> categoryColors = {
  ContactCategory.family: Colors.blue,
  ContactCategory.friends: Colors.teal,
  ContactCategory.professional: Colors.indigo,
};

// ==================== Messages ====================

/// Message SMS d'anniversaire par défaut
const String defaultBirthdaySmsTemplate =
    "Joyeux anniversaire {name} ! 🎂 Je te souhaite une merveilleuse journée !";

/// Messages d'erreur
class ErrorMessages {
  static const String noContactsPermission =
      "Permission d'accès aux contacts refusée";
  static const String noCallPermission =
      "Permission d'appel téléphonique refusée";
  static const String noSmsPermission =
      "Permission d'envoi de SMS refusée";
  static const String databaseError =
      "Erreur lors de l'accès à la base de données";
  static const String contactNotFound =
      "Contact introuvable";
  static const String noPhoneNumber =
      "Aucun numéro de téléphone disponible";
}

/// Messages d'information
class InfoMessages {
  static const String noContactsYet =
      "Aucun contact suivi pour le moment";
  static const String addFirstContact =
      "Ajoutez votre premier contact pour commencer !";
  static const String contactAdded =
      "Contact ajouté avec succès";
  static const String contactUpdated =
      "Contact mis à jour";
  static const String contactDeleted =
      "Contact supprimé";
  static const String contactRecorded =
      "Contact enregistré";
}

// ==================== Formatage ====================

/// Format de date par défaut
const String dateFormat = 'dd/MM/yyyy';

/// Format de date avec heure
const String dateTimeFormat = 'dd/MM/yyyy HH:mm';

// ==================== UI ====================

/// Padding par défaut
const double defaultPadding = 16.0;

/// Border radius par défaut
const double defaultBorderRadius = 12.0;

/// Taille des icônes
const double iconSizeSmall = 20.0;
const double iconSizeMedium = 24.0;
const double iconSizeLarge = 32.0;
