# CallLog - Gestionnaire de Contacts

Application Android Flutter pour gérer et suivre les contacts réguliers avec vos proches.

## 📱 Fonctionnalités

### Gestion des Contacts
- **Ajout de contacts** depuis le répertoire Android
- **Fréquences personnalisables** : hebdomadaire, bihebdomadaire, mensuel, trimestriel, annuel
- **Catégories** : famille, amis, professionnel
- **Priorités automatiques** basées sur la date du dernier contact

### Anniversaires
- **Détection automatique** des anniversaires depuis les contacts Android
- **Notifications visuelles** pour les anniversaires dans les 7 jours
- **Badge prioritaire** pour les anniversaires du jour
- **SMS d'anniversaire** avec template pré-rempli

### Communication
- **Appels directs** depuis l'application
- **Envoi de SMS** avec template personnalisable
- **Historique complet** des interactions (appels et SMS)
- **Enregistrement automatique** de chaque contact

### Filtres et Tri
- Filtrage par **catégorie**, **fréquence**, **priorité**
- Filtre spécial **anniversaires**
- Tri automatique par priorité et urgence
- Recherche de contacts

## 🏗️ Architecture

```
lib/
├── models/           # Modèles de données
│   ├── enums.dart
│   ├── tracked_contact.dart
│   └── contact_record.dart
├── providers/        # State management (Provider)
│   ├── contacts_provider.dart
│   └── filters_provider.dart
├── screens/          # Écrans de l'application
│   ├── home_screen.dart
│   ├── add_contact_screen.dart
│   ├── contact_detail_screen.dart
│   └── filters_screen.dart
├── services/         # Services métier
│   ├── database_service.dart
│   ├── contacts_service.dart
│   ├── communication_service.dart
│   └── permission_service.dart
├── widgets/          # Widgets réutilisables
│   ├── contact_card.dart
│   ├── filter_chips.dart
│   ├── priority_indicator.dart
│   ├── birthday_badge.dart
│   └── empty_state.dart
├── utils/            # Utilitaires
│   ├── constants.dart
│   ├── priority_calculator.dart
│   ├── birthday_utils.dart
│   ├── date_utils.dart
│   └── app_theme.dart
└── main.dart
```

## 🚀 Installation

### Prérequis
- Flutter 3.35.5 ou supérieur
- Dart 3.9.2 ou supérieur
- Android SDK 36
- Java 21

### Dépendances
```yaml
dependencies:
  flutter_localizations: sdk
  sqflite: ^2.3.0           # Base de données locale
  provider: ^6.1.1          # State management
  permission_handler: ^11.2.0
  flutter_contacts: ^1.1.7  # Accès aux contacts
  url_launcher: ^6.2.4      # Appels et SMS
  intl: ^0.20.2            # Formatage des dates
```

### Build

**Debug:**
```bash
flutter pub get
flutter build apk --debug
```

**Production:**
```bash
flutter build apk --release
```

L'APK de production se trouve dans `build/app/outputs/flutter-apk/app-release.apk`

## 📦 Base de Données

SQLite avec 2 tables principales :

### tracked_contacts
- Contacts suivis avec fréquence et catégorie
- Date du dernier contact
- Date d'anniversaire (optionnelle)

### contact_history
- Historique de chaque interaction
- Type (appel/SMS)
- Contexte (normal/anniversaire)

## 🎨 Design

- **Material Design 3**
- Thème centralisé avec couleurs cohérentes
- Animations fluides sur les interactions
- Interface en français
- Support des modes clair (sombre prévu pour évolution)

## 🔐 Permissions

L'application nécessite les permissions suivantes :
- `READ_CONTACTS` : Accès aux contacts Android
- `CALL_PHONE` : Passer des appels
- `SEND_SMS` : Envoyer des SMS

## 📝 Utilisation

1. **Ajouter un contact** via le bouton "+"
2. Sélectionner un contact depuis votre répertoire
3. Choisir la fréquence et la catégorie
4. L'anniversaire est importé automatiquement si disponible
5. Appelez ou envoyez des SMS directement depuis la liste
6. Consultez l'historique dans les détails du contact

## 🎯 Système de Priorité

1. **🎂 Anniversaire** (priorité maximale) - Anniversaire aujourd'hui
2. **🔴 Haute** - Contact en retard selon la fréquence
3. **🟠 Moyenne** - À contacter bientôt
4. **🟢 Basse** - Contact à jour

## 📊 Développement

### Structure des Chantiers

Le développement a été organisé en 18 chantiers (phases) :
1. **Chantiers 1-10** : Infrastructure (models, services, providers, utils, widgets)
2. **Chantier 11** : Écran d'accueil
3. **Chantier 12** : Écran d'ajout de contact
4. **Chantier 13** : Écran de détails d'un contact
5. **Chantier 14** : Écran de filtres
6. **Chantier 15** : Configuration du main.dart
7. **Chantier 16** : Tests et corrections de bugs
8. **Chantier 17** : Améliorations UI/UX
9. **Chantier 18** : Build de production

Voir [CHANTIERS.md](CHANTIERS.md) pour le détail de chaque phase.

## 📄 Spécifications

Voir [SPEC.md](SPEC.md) pour les spécifications complètes de l'application.

## 📄 License

Ce projet a été créé dans le cadre d'un projet personnel.

---

**Version** : 1.0.0
**Date** : 2025-10-03
