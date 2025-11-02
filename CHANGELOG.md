# Changelog

Toutes les modifications notables du projet CallLog seront documentées dans ce fichier.

Le format est basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/),
et ce projet adhère à [Semantic Versioning](https://semver.org/lang/fr/).

## [1.3.0] - 2025-10-23

### Ajouté
- **Transcription audio avec Gemini 2.5 Flash** : Enregistrement et transcription automatique de notes vocales pour chaque contact
  - Intégration de l'API Google Generative AI
  - Stockage sécurisé de la clé API avec `flutter_secure_storage`
  - Enregistrement audio avec le package `record`
  - Lecture des enregistrements avec `audioplayers`
- **Mode anonyme** : Permet de masquer les informations sensibles pour les démonstrations et captures d'écran/vidéos
  - Anonymisation des noms de contacts
  - Masquage des numéros de téléphone
  - Toggle rapide dans les paramètres
- **Partage de texte** : Réception de texte partagé depuis d'autres applications
  - Intégration avec le système de partage Android
  - Sélection du contact destinataire
  - Ajout automatique comme note

### Dépendances ajoutées
- `google_generative_ai: ^0.4.0` - API Gemini pour transcription
- `flutter_secure_storage: ^9.0.0` - Stockage sécurisé de la clé API
- `record: ^5.1.2` - Enregistrement audio
- `audioplayers: ^5.2.1` - Lecture audio
- `crypto: ^3.0.3` - Utilitaires cryptographiques

## [1.2.0] - 2025-10-04

### Ajouté
- **Synchronisation automatique du journal d'appels Android** au démarrage de l'application
- **Filtrage intelligent des appels** :
  - Uniquement les appels sortants (type 2)
  - Durée minimale de 10 secondes (ignore les appels ratés)
  - Utilisation des vraies dates d'appels depuis le journal Android
- **Anti-doublons amélioré** : Tolérance de 1 minute pour éviter les entrées multiples
- **Bouton "Reset dernier contact"** : Permet de remettre un contact en état "Jamais contacté"
- **Bouton "Marquer comme contacté"** : Enregistrement manuel avec méthode "autre" pour rencontres physiques
- **Normalisation des numéros** : Gestion des formats 06... et +336... pour matching correct
- **Écran des paramètres** avec outils de maintenance :
  - Bouton "Synchroniser maintenant"
  - Configuration de la période de synchronisation (7/14/30 jours)
  - Bouton "Nettoyer les doublons"
  - Bouton "Effacer tout l'historique"
  - Outils de debug
- **Permission READ_CALL_LOG** : Accès au journal d'appels Android

### Modifié
- **Filtre de priorité plus strict** : Seuil de priorité porté à 95% (au lieu de 80%)
- `database_service.recordContact()` accepte maintenant un paramètre `contactDate` optionnel
- Mise à jour de `lastContactDate` : ne met à jour que si la date est plus récente

### Corrigé
- Dates incorrectes : Les appels synchronisés utilisaient `DateTime.now()` au lieu de la vraie date de l'appel
- Faux appels : Les appels de 0-5 secondes (ratés) étaient comptabilisés
- `lastContactDate` incorrect : La date affichée ne correspondait pas au dernier appel réel
- Doublons : Multiples entrées pour le même appel lors de synchronisations successives

## [1.1.0] - 2025-10-03

### Ajouté
- **Gestion des dates d'anniversaire** pour chaque contact
- **Tri prioritaire des anniversaires** (jour J en premier, puis J-7)
- **Badge visuel** pour les anniversaires proches
- **Envoi de SMS** avec message d'anniversaire pré-rempli
- **Bouton SMS général** pour tous les contacts
- **Historique détaillé** incluant type de contact (appel/SMS) et contexte (normal/anniversaire)
- **Filtre dédié aux anniversaires**
- **Permission SEND_SMS** ajoutée
- **Système de backup/export** :
  - Export des données en JSON
  - Import de données JSON
  - Statistiques d'utilisation

### Modifié
- Amélioration de l'UX des filtres avec bouton "Tous" pour désactiver les filtres
- Chips de filtres toujours visibles en haut de l'écran

## [1.0.0] - 2025-10-03

### Ajouté
- 🎉 **Version initiale de CallLog**
- **Gestion des contacts** :
  - Accès au répertoire Android
  - Ajout de contacts au suivi
  - Fréquences personnalisables (hebdo, bihebdo, mensuel, trimestriel, annuel)
  - Catégories (famille, amis, professionnel)
- **Système de priorités** :
  - Priorité haute (rouge) : contacts en retard
  - Priorité moyenne (orange) : à contacter bientôt
  - Priorité basse (vert) : contacts à jour
- **Écran d'accueil** avec liste triée par priorité
- **Actions sur les contacts** :
  - Appeler directement
  - Marquer comme contacté manuellement
- **Filtres** :
  - Par catégorie
  - Par fréquence
  - Par priorité
- **Historique des contacts** pour chaque personne
- **Base de données SQLite locale** :
  - Table `tracked_contacts`
  - Table `contact_history`
- **Permissions Android** :
  - READ_CONTACTS
  - CALL_PHONE

### Architecture
- Framework : Flutter
- State management : Provider
- Base de données : SQLite (sqflite)
- Packages principaux :
  - `flutter_contacts` : Accès aux contacts Android
  - `url_launcher` : Lancement d'appels
  - `permission_handler` : Gestion des permissions
  - `provider` : Gestion d'état
  - `sqflite` : Base de données locale
  - `intl` : Formatage des dates

---

## Types de changements

- **Ajouté** : pour les nouvelles fonctionnalités
- **Modifié** : pour les changements aux fonctionnalités existantes
- **Déprécié** : pour les fonctionnalités bientôt supprimées
- **Supprimé** : pour les fonctionnalités supprimées
- **Corrigé** : pour les corrections de bugs
- **Sécurité** : en cas de vulnérabilités
