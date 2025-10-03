# CallLog - Application de Suivi d'Appels

Application Android Flutter permettant de gérer et suivre les appels et SMS réguliers à des contacts (famille, amis, professionnels) selon des fréquences définies, avec gestion des anniversaires.

## Fonctionnalités

- 📞 Suivi des appels réguliers avec fréquences configurables (hebdomadaire, mensuelle, etc.)
- 📱 Envoi de SMS avec messages pré-remplis
- 🎂 Gestion des anniversaires avec rappels et messages personnalisés
- 🔔 Système de priorités intelligent
- 🎯 Filtres avancés (catégorie, fréquence, anniversaires)
- 📊 Historique complet des contacts (appels et SMS)

## Technologies utilisées

- **Framework** : Flutter 3.35.5
- **Langage** : Dart 3.9.2
- **Base de données** : SQLite
- **Gestion d'état** : Provider
- **Permissions** : permission_handler
- **Contacts** : flutter_contacts
- **Communication** : url_launcher

## Installation

1. Cloner le projet
2. Installer les dépendances : `flutter pub get`
3. Lancer l'application : `flutter run`

## Prérequis

- Flutter SDK >= 3.0.0
- Android SDK >= 21 (Android 5.0)

## Architecture

```
lib/
├── models/          # Modèles de données
├── services/        # Services (BDD, permissions, contacts)
├── providers/       # Gestion d'état
├── screens/         # Écrans de l'application
├── widgets/         # Widgets réutilisables
└── utils/           # Utilitaires et helpers
```

## Permissions Android

L'application nécessite les permissions suivantes :
- `READ_CONTACTS` : Accès au répertoire de contacts
- `CALL_PHONE` : Lancement d'appels téléphoniques
- `SEND_SMS` : Envoi de SMS

---

**Version** : 1.0.0
**Date** : 2025-10-03
