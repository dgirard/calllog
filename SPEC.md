# Spécification - Application de Suivi d'Appels (Flutter Android)

## 1. Vue d'ensemble

Application Android Flutter permettant de gérer et suivre les appels et SMS réguliers à des contacts (famille, amis, professionnels) selon des fréquences définies, avec gestion des anniversaires.

## 2. Objectif

Aider l'utilisateur à identifier facilement les personnes qu'il doit appeler ou contacter par SMS en fonction de la dernière fois qu'il les a contactées et de la fréquence souhaitée. L'application facilite également l'envoi de vœux d'anniversaire par appel ou SMS.

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
  - **Date d'anniversaire** (optionnel) :
    - Saisie manuelle ou récupération depuis le contact Android
    - Calcul automatique du prochain anniversaire
    - Affichage dans la liste si anniversaire proche (J-7)

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
- Date du dernier appel/SMS
- **Badge "Anniversaire"** si l'anniversaire est dans les 7 prochains jours (icône gâteau 🎂)
- Indicateur visuel de priorité :
  - Rouge : en retard
  - Orange : à appeler bientôt
  - Vert : à jour
  - **Violet/Rose** : anniversaire aujourd'hui (priorité maximale)

**Actions sur un contact** :
- **Tap sur le contact** : ouvre un menu contextuel avec choix :
  - Appeler
  - Envoyer SMS
  - Marquer comme contacté
- **Bouton "Téléphone"** : lance l'appel téléphonique natif
- **Bouton "SMS"** : ouvre l'application SMS native
  - Si anniversaire : propose un modèle de message pré-rempli ("Joyeux anniversaire [Prénom] ! 🎂")
- Bouton "Marquer comme contacté" : enregistre la date/heure actuelle
- Édition : modifier fréquence/catégorie/anniversaire
- Suppression du suivi

### 3.3 Système de filtrage

Filtres disponibles :
- **Par catégorie** : Famille / Amis / Professionnel / Tous
- **Par fréquence** : Hebdomadaire / Bihebdomadaire / Mensuel / Trimestriel / Annuel / Tous
- **Par priorité** : En retard / À appeler bientôt / À jour / Tous
- **Anniversaires** : Afficher uniquement les contacts avec anniversaire proche (toggle)

Interface :
- Barre de filtres en haut de l'écran d'accueil
- Chips ou dropdown pour chaque type de filtre
- Possibilité de combiner plusieurs filtres
- Toggle dédié "Anniversaires" pour voir rapidement les anniversaires à venir

### 3.4 Enregistrement des contacts (appels et SMS)

Deux méthodes :
1. **Manuel** : Bouton "Marquer comme contacté"
2. **Automatique** (optionnel, phase 2) : Détection automatique des appels/SMS sortants via permissions Android

Données enregistrées :
- Date et heure du contact
- Contact concerné
- **Type de contact** : Appel ou SMS
- **Contexte** : Normal ou Anniversaire

### 3.5 Gestion des anniversaires

**Fonctionnalités** :
- Saisie de la date d'anniversaire lors de l'ajout/édition d'un contact
- Import automatique depuis le contact Android si disponible
- Calcul du nombre de jours avant le prochain anniversaire
- Affichage prioritaire dans la liste si anniversaire dans les 7 jours
- **Priorité maximale le jour de l'anniversaire** (tri en premier)

**Actions spécifiques anniversaire** :
- Bouton "SMS d'anniversaire" : ouvre SMS avec message pré-rempli
  - Message par défaut : "Joyeux anniversaire [Prénom] ! 🎂 Je te souhaite une merveilleuse journée !"
  - Message personnalisable dans les paramètres
- Bouton "Appeler pour anniversaire" : lance l'appel avec marquage "contexte anniversaire"
- Badge visuel distinctif (icône gâteau, couleur spéciale)

### 3.6 Historique

- Liste des contacts effectués pour chaque personne
- Date et heure de chaque contact
- **Type** : Appel ou SMS
- **Contexte** : Normal ou Anniversaire
- Accessible depuis la fiche du contact

## 4. Architecture technique

### 4.1 Stack technique

- **Framework** : Flutter (version stable récente)
- **Plateforme** : Android (API minimum 21 - Android 5.0)
- **Langage** : Dart

### 4.2 Packages Flutter recommandés

- `contacts_service` ou `flutter_contacts` : accès au répertoire Android
- `permission_handler` : gestion des permissions
- `url_launcher` : lancer les appels téléphoniques et SMS
- `sqflite` : base de données locale SQLite
- `provider` ou `riverpod` : gestion d'état
- `intl` : formatage des dates
- `flutter_sms` ou `sms_advanced` : envoi de SMS (optionnel)

### 4.3 Permissions Android requises

```xml
<uses-permission android:name="android.permission.READ_CONTACTS" />
<uses-permission android:name="android.permission.CALL_PHONE" />
<uses-permission android:name="android.permission.SEND_SMS" />
<uses-permission android:name="android.permission.READ_SMS" /> <!-- Si détection auto -->
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
- last_contact_date (DATETIME, nullable)
- **birthday (DATE, nullable)** - date d'anniversaire (jour/mois uniquement)
- created_at (DATETIME)
- updated_at (DATETIME)

**Table : contact_history**
- id (PRIMARY KEY)
- tracked_contact_id (FOREIGN KEY)
- contact_date (DATETIME)
- contact_method (ENUM: call, sms)
- contact_type (ENUM: manual, automatic)
- **context (ENUM: normal, birthday)** - contexte du contact

### 4.5 Logique de calcul de priorité

```
# Priorité anniversaire (toujours en premier)
si anniversaire_aujourd_hui : PRIORITÉ ANNIVERSAIRE (violet/rose)

# Priorité contact régulier
délai_écoulé = date_actuelle - date_dernier_contact
délai_attendu = selon fréquence configurée

si délai_écoulé > délai_attendu : PRIORITÉ HAUTE (rouge)
si délai_écoulé > (délai_attendu * 0.8) : PRIORITÉ MOYENNE (orange)
sinon : PRIORITÉ BASSE (vert)
```

Tri de la liste :
1. **Anniversaire aujourd'hui** (priorité absolue)
2. **Anniversaire dans les 7 jours** (avec badge)
3. Priorité contact (haute → basse)
4. Délai écoulé (du plus ancien au plus récent)

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
  - **Champ date d'anniversaire (optionnel)** avec date picker
  - Import automatique anniversaire depuis contact Android si disponible
  - Bouton "Ajouter au suivi"

### 5.3 Écran de détail/édition d'un contact
- Informations du contact
- **Affichage anniversaire** si renseigné (avec âge si année disponible)
- **Section actions rapides** :
  - Bouton "Appeler"
  - Bouton "SMS"
  - Si anniversaire proche : bouton "SMS d'anniversaire" avec message pré-rempli
- Historique des contacts (appels et SMS)
- Modification de la fréquence/catégorie/anniversaire
- Suppression du suivi

### 5.4 Écran de filtres (optionnel, peut être modal/bottom sheet)
- Sélection des filtres actifs
- Bouton "Appliquer"

## 6. User Experience (UX)

### 6.1 Notifications (Phase 2, optionnel)
- Notification quotidienne/hebdomadaire rappelant les personnes à appeler
- **Notification d'anniversaire** : rappel le jour J et J-1
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
- **Gestion des anniversaires (saisie et affichage)**
- Écran d'accueil avec liste triée par priorité (incluant anniversaires)
- Marquage manuel des contacts (appels et SMS)
- **Envoi de SMS avec message pré-rempli pour anniversaires**
- Lancement d'appels téléphoniques
- Filtrage basique (incluant filtre anniversaires)

### Phase 2 (Améliorations)
- Historique détaillé des contacts (appels et SMS)
- Détection automatique des appels/SMS (via call log)
- **Notifications d'anniversaire (J-1 et jour J)**
- Notifications de rappel contacts réguliers
- **Messages d'anniversaire personnalisables**
- Statistiques (nombre d'appels/SMS par mois, anniversaires souhaités, etc.)
- Export/import des données
- Sauvegarde cloud (optionnel)
- **Widget Android pour anniversaires du jour**

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

## 10. Nouveautés version 1.1 - Gestion des anniversaires et SMS

### Fonctionnalités ajoutées :
- ✅ Gestion des dates d'anniversaire pour chaque contact
- ✅ Tri prioritaire des anniversaires (jour J en premier, puis J-7)
- ✅ Badge visuel pour anniversaires proches
- ✅ Envoi de SMS avec message d'anniversaire pré-rempli
- ✅ Bouton SMS général pour tous les contacts
- ✅ Historique incluant type de contact (appel/SMS) et contexte (normal/anniversaire)
- ✅ Filtre dédié aux anniversaires
- ✅ Permission SEND_SMS ajoutée

### À venir (Phase 2) :
- Notifications d'anniversaire automatiques
- Messages d'anniversaire personnalisables
- Widget Android anniversaires
- Détection automatique SMS sortants

---

**Version** : 1.1
**Date** : 2025-10-03
