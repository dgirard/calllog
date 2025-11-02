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

## 11. Nouveautés version 1.2 - Synchronisation automatique du journal d'appels

### Fonctionnalités ajoutées :
- ✅ **Synchronisation automatique au démarrage** : Les appels sont automatiquement synchronisés depuis le journal d'appels Android à chaque lancement de l'app (30 derniers jours)
- ✅ **Filtrage intelligent des appels** :
  - Uniquement les appels sortants (type 2)
  - Durée minimale de 10 secondes (ignore les appels ratés/tests)
  - Utilisation des vraies dates d'appels (correction du bug de timestamps)
- ✅ **Anti-doublons amélioré** : Tolérance de 1 minute pour éviter les entrées multiples
- ✅ **Mise à jour correcte de lastContactDate** : Garde toujours la date la plus récente
- ✅ **Bouton "Reset dernier contact"** : Permet de remettre un contact en état "Jamais contacté"
- ✅ **Bouton "Marquer comme contacté"** : Enregistrement manuel avec méthode "autre" (pour rencontres physiques)
- ✅ **Filtre très strict** : Seuil de priorité porté à 95% (au lieu de 80%)
- ✅ **Normalisation des numéros** : Gestion des formats 06... et +336... pour matching correct
- ✅ **Permission READ_CALL_LOG** : Accès au journal d'appels Android

### Outils de maintenance :
- ✅ **Nettoyer les doublons** : Bouton dans Paramètres pour supprimer les entrées en double
- ✅ **Effacer tout l'historique** : Reset complet pour resynchronisation propre
- ✅ **Debug Georges** : Outil de diagnostic pour vérifier l'historique d'un contact
- ✅ **Synchronisation manuelle** : Bouton dans Paramètres (en plus de l'auto-sync au démarrage)
- ✅ **Configuration période de sync** : Choix entre 7, 14 ou 30 jours

### Corrections de bugs :
- 🐛 **Dates incorrectes** : Les appels synchronisés utilisaient `DateTime.now()` au lieu de la vraie date de l'appel
- 🐛 **Faux appels** : Les appels de 0-5 secondes (ratés) étaient comptabilisés
- 🐛 **lastContactDate incorrect** : La date affichée ne correspondait pas au dernier appel réel
- 🐛 **Doublons** : Multiples entrées pour le même appel lors de syncs successives

### Améliorations techniques :
- `database_service.recordContact()` accepte maintenant un paramètre `contactDate` optionnel
- `call_log_service.dart` utilise les timestamps Android (millisecondes) pour dates exactes
- Logique de mise à jour de `lastContactDate` : ne met à jour que si date plus récente
- Synchronisation en arrière-plan au lancement sans bloquer l'UI

---

## 12. Nouveautés version 1.3 - Transcription audio et mode anonyme

### Fonctionnalités ajoutées :

#### Transcription audio avec Gemini 2.5 Flash
- ✅ **Enregistrement de notes vocales** : Enregistrement audio directement depuis la fiche d'un contact
- ✅ **Transcription automatique** : Utilisation de l'API Google Generative AI (Gemini 2.5 Flash) pour transcrire les notes audio en texte
- ✅ **Stockage sécurisé** : La clé API Gemini est stockée de manière sécurisée avec `flutter_secure_storage`
- ✅ **Lecture des enregistrements** : Écoute des notes audio enregistrées
- ✅ **Interface intuitive** : Boutons d'enregistrement, lecture et transcription dans l'écran de détail du contact
- ✅ **Gestion des erreurs** : Messages clairs si la transcription échoue ou si la clé API n'est pas configurée
- ✅ **Configuration dans Paramètres** : Écran dédié pour saisir et tester la clé API Gemini

**Cas d'usage** :
- Enregistrer rapidement des notes vocales après un appel important
- Transcrire automatiquement le contenu pour consultation ultérieure
- Garder une trace écrite des conversations (réunions, rendez-vous médicaux, etc.)

**Packages utilisés** :
- `google_generative_ai: ^0.4.0` - API Gemini pour transcription
- `flutter_secure_storage: ^9.0.0` - Stockage sécurisé de la clé API
- `record: ^5.1.2` - Enregistrement audio (formats M4A, OPUS, WAV, MP3)
- `audioplayers: ^5.2.1` - Lecture audio
- `crypto: ^3.0.3` - Utilitaires cryptographiques

**Obtenir une clé API Gemini** :
1. Se connecter à [Google AI Studio](https://aistudio.google.com/apikey)
2. Créer une nouvelle clé API
3. Copier la clé dans les Paramètres de l'application

#### Mode anonyme
- ✅ **Anonymisation des données** : Masquage des informations personnelles pour démonstrations/captures d'écran
- ✅ **Noms anonymisés** : Remplacement des noms réels par des pseudonymes génériques ("Contact A", "Contact B", etc.)
- ✅ **Numéros masqués** : Affichage de numéros factices au lieu des vrais numéros
- ✅ **Toggle rapide** : Activation/désactivation instantanée depuis les Paramètres
- ✅ **Persistance** : Le mode reste actif entre les sessions
- ✅ **Icône de notification** : Badge visible dans l'AppBar quand le mode est actif

**Cas d'usage** :
- Création de tutoriels vidéo sans exposer les données personnelles
- Captures d'écran pour documentation ou portfolio
- Démonstrations de l'application à des tiers
- Tests en public (conférences, présentations)

**Provider dédié** : `AnonymityProvider` pour gérer l'état global du mode anonyme

#### Partage de texte
- ✅ **Réception de texte partagé** : L'application peut recevoir du texte depuis d'autres applications Android
- ✅ **Sélection du contact** : Écran de sélection pour choisir à quel contact associer le texte partagé
- ✅ **Ajout automatique comme note** : Le texte partagé est enregistré comme note du contact
- ✅ **MethodChannel Android** : Communication native entre Android et Flutter

**Cas d'usage** :
- Partager une adresse email depuis une app vers un contact CallLog
- Transférer des notes depuis une app de prise de notes
- Enregistrer des informations importantes liées à un contact

**Implémentation** :
- `ShareReceiverScreen` : Écran de réception et sélection du contact
- Configuration dans `MainActivity.kt` pour intercepter les intents de partage Android

### Améliorations techniques :
- Utilisation de `flutter_secure_storage` pour protéger les données sensibles (clés API)
- Architecture extensible pour supporter d'autres services de transcription à l'avenir
- Gestion des permissions audio (si nécessaire selon la plateforme)
- Support de multiples formats audio (M4A, OPUS, WAV, MP3)

### À venir (Phase 3) :
- Reconnaissance vocale en temps réel pendant l'enregistrement
- Résumé automatique des notes avec IA
- Traduction automatique des transcriptions
- Recherche dans les transcriptions
- Export des transcriptions en PDF
- Partage de notes entre contacts

---

**Version** : 1.3
**Date** : 2025-10-23
