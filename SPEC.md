# Spécification - Application de Suivi d'Appels (Flutter Android)

## 1. Vue d'ensemble

Application Android Flutter permettant de gérer et suivre les appels réguliers à des contacts (famille, amis, professionnels) selon des fréquences définies.

## 2. Objectif

Aider l'utilisateur à identifier facilement les personnes qu'il doit appeler en fonction de la dernière fois qu'il les a contactées et de la fréquence souhaitée.

## 3. Fonctionnalités principales

### 3.1 Gestion des contacts

- **Accès au répertoire Android** : Intégration avec les contacts natifs Android
- **Ajout de contact au suivi** :
  - Sélection depuis le répertoire Android
  - Association d'une fréquence d'appel :
    - Hebdomadaire (toutes les semaines)
    - Bihebdomadaire (toutes les 2 semaines)
    - Mensuel (tous les mois)
    - Trimestriel (tous les 3 mois)
    - Annuel (tous les ans)
  - Association d'une catégorie :
    - Famille
    - Amis
    - Professionnel

### 3.2 Écran d'accueil - Liste des contacts à appeler

**Affichage principal** :
- Liste des contacts suivis
- Tri automatique par priorité :
  1. **Priorité haute** : Contacts en retard (délai dépassé)
  2. **Priorité moyenne** : Contacts à appeler bientôt
  3. **Priorité basse** : Contacts à jour

**Informations affichées par contact** :
- Nom du contact
- Photo (si disponible depuis le répertoire)
- Catégorie (Famille/Amis/Professionnel)
- Fréquence configurée
- Date du dernier appel
- Indicateur visuel de priorité :
  - Rouge : en retard
  - Orange : à appeler bientôt
  - Vert : à jour

**Actions sur un contact** :
- Tap sur le contact : lance l'appel téléphonique natif
- Bouton "Marquer comme appelé" : enregistre la date/heure actuelle
- Édition : modifier fréquence/catégorie
- Suppression du suivi

### 3.3 Système de filtrage

Filtres disponibles :
- **Par catégorie** : Famille / Amis / Professionnel / Tous
- **Par fréquence** : Hebdomadaire / Bihebdomadaire / Mensuel / Trimestriel / Annuel / Tous
- **Par priorité** : En retard / À appeler bientôt / À jour / Tous

Interface :
- Barre de filtres en haut de l'écran d'accueil
- Chips ou dropdown pour chaque type de filtre
- Possibilité de combiner plusieurs filtres

### 3.4 Enregistrement des appels

Deux méthodes :
1. **Manuel** : Bouton "Marquer comme appelé"
2. **Automatique** (optionnel, phase 2) : Détection automatique des appels sortants via permissions Android

Données enregistrées :
- Date et heure de l'appel
- Contact concerné

### 3.5 Historique

- Liste des appels effectués pour chaque contact
- Date et heure de chaque appel
- Accessible depuis la fiche du contact

## 4. Architecture technique

### 4.1 Stack technique

- **Framework** : Flutter (version stable récente)
- **Plateforme** : Android (API minimum 21 - Android 5.0)
- **Langage** : Dart

### 4.2 Packages Flutter recommandés

- `contacts_service` ou `flutter_contacts` : accès au répertoire Android
- `permission_handler` : gestion des permissions
- `url_launcher` : lancer les appels téléphoniques
- `sqflite` : base de données locale SQLite
- `provider` ou `riverpod` : gestion d'état
- `intl` : formatage des dates

### 4.3 Permissions Android requises

```xml
<uses-permission android:name="android.permission.READ_CONTACTS" />
<uses-permission android:name="android.permission.CALL_PHONE" />
<uses-permission android:name="android.permission.READ_CALL_LOG" /> <!-- Si détection auto -->
```

### 4.4 Base de données locale

**Table : tracked_contacts**
- id (PRIMARY KEY)
- contact_id (référence au contact Android)
- contact_name (STRING)
- contact_phone (STRING)
- frequency (ENUM: weekly, biweekly, monthly, quarterly, yearly)
- category (ENUM: family, friends, professional)
- last_call_date (DATETIME, nullable)
- created_at (DATETIME)
- updated_at (DATETIME)

**Table : call_history**
- id (PRIMARY KEY)
- tracked_contact_id (FOREIGN KEY)
- call_date (DATETIME)
- call_type (ENUM: manual, automatic)

### 4.5 Logique de calcul de priorité

```
délai_écoulé = date_actuelle - date_dernier_appel
délai_attendu = selon fréquence configurée

si délai_écoulé > délai_attendu : PRIORITÉ HAUTE (rouge)
si délai_écoulé > (délai_attendu * 0.8) : PRIORITÉ MOYENNE (orange)
sinon : PRIORITÉ BASSE (vert)
```

Tri de la liste :
1. Priorité (haute → basse)
2. Délai écoulé (du plus ancien au plus récent)

## 5. Écrans de l'application

### 5.1 Écran principal (Home)
- AppBar avec titre et icône de filtre
- Liste des contacts triée par priorité
- FAB (Floating Action Button) pour ajouter un contact

### 5.2 Écran d'ajout de contact
- Recherche/sélection depuis le répertoire Android
- Formulaire :
  - Sélection de la fréquence (dropdown)
  - Sélection de la catégorie (radio buttons ou dropdown)
  - Bouton "Ajouter au suivi"

### 5.3 Écran de détail/édition d'un contact
- Informations du contact
- Historique des appels
- Modification de la fréquence/catégorie
- Suppression du suivi

### 5.4 Écran de filtres (optionnel, peut être modal/bottom sheet)
- Sélection des filtres actifs
- Bouton "Appliquer"

## 6. User Experience (UX)

### 6.1 Notifications (Phase 2, optionnel)
- Notification quotidienne/hebdomadaire rappelant les personnes à appeler
- Configurable par l'utilisateur

### 6.2 Widgets
- Indicateurs visuels clairs (couleurs, icônes)
- Interface Material Design
- Animations fluides lors des transitions

### 6.3 Gestion des cas particuliers
- Contact supprimé du répertoire Android : afficher un message d'erreur
- Aucun contact suivi : écran vide avec CTA "Ajouter votre premier contact"
- Permissions refusées : expliquer pourquoi elles sont nécessaires

## 7. Phases de développement suggérées

### Phase 1 (MVP)
- Accès aux contacts Android
- Ajout/suppression de contacts au suivi
- Configuration fréquence et catégorie
- Écran d'accueil avec liste triée par priorité
- Marquage manuel des appels
- Filtrage basique

### Phase 2 (Améliorations)
- Historique détaillé des appels
- Détection automatique des appels (via call log)
- Notifications
- Statistiques (nombre d'appels par mois, etc.)
- Export/import des données
- Sauvegarde cloud (optionnel)

## 8. Contraintes et considérations

- **Confidentialité** : Les données restent en local sur l'appareil
- **Performance** : Optimiser pour gérer plusieurs centaines de contacts
- **Accessibilité** : Support des lecteurs d'écran
- **Langues** : Français (extensible à d'autres langues)

## 9. Livrables attendus

- Code source Flutter
- Documentation technique
- Guide d'installation
- APK de test
- Instructions de déploiement sur Google Play Store (optionnel)

---

**Version** : 1.0
**Date** : 2025-10-03
