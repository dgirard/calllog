# Liste des Chantiers - Application CallLog Flutter

## Instructions pour l'IA développeur

- **Exécuter les chantiers dans l'ordre**
- **S'arrêter après chaque chantier**
- **Faire un git commit après chaque chantier complété**
- **Vérifier que le projet compile sans erreur avant de committer**
- **Suivre l'arborescence définie ci-dessous**

---

## Arborescence du projet

```
calllog/
├── lib/
│   ├── main.dart
│   ├── models/
│   │   ├── tracked_contact.dart
│   │   ├── contact_record.dart
│   │   └── enums.dart
│   ├── services/
│   │   ├── database_service.dart
│   │   ├── contacts_service.dart
│   │   ├── communication_service.dart
│   │   └── permission_service.dart
│   ├── providers/
│   │   ├── contacts_provider.dart
│   │   └── filters_provider.dart
│   ├── screens/
│   │   ├── home_screen.dart
│   │   ├── add_contact_screen.dart
│   │   ├── contact_detail_screen.dart
│   │   └── filter_screen.dart
│   ├── widgets/
│   │   ├── contact_card.dart
│   │   ├── priority_indicator.dart
│   │   ├── filter_chips.dart
│   │   ├── empty_state.dart
│   │   └── birthday_badge.dart
│   └── utils/
│       ├── constants.dart
│       ├── date_utils.dart
│       ├── birthday_utils.dart
│       └── priority_calculator.dart
├── android/
│   └── app/
│       └── src/
│           └── main/
│               └── AndroidManifest.xml
├── test/
├── pubspec.yaml
└── README.md
```

---

## CHANTIER 1 : Initialisation du projet Flutter

### Objectif
Créer le projet Flutter avec la structure de base et les dépendances.

### Tâches
1. Initialiser le projet Flutter : `flutter create calllog`
2. Configurer `pubspec.yaml` avec les dépendances :
   - `sqflite: ^2.3.0`
   - `path: ^1.8.3`
   - `provider: ^6.1.1`
   - `permission_handler: ^11.2.0`
   - `flutter_contacts: ^1.1.7`
   - `url_launcher: ^6.2.4`
   - `intl: ^0.19.0`
3. Créer l'arborescence des dossiers (models, services, providers, screens, widgets, utils)
4. Configurer les permissions dans `android/app/src/main/AndroidManifest.xml` :
   ```xml
   <uses-permission android:name="android.permission.READ_CONTACTS" />
   <uses-permission android:name="android.permission.CALL_PHONE" />
   <uses-permission android:name="android.permission.SEND_SMS" />
   ```
5. Créer un `README.md` basique avec description du projet
6. Tester que le projet compile : `flutter pub get && flutter build apk --debug`

### Commit
```
git init
git add .
git commit -m "chantier 1: initialisation projet Flutter avec dépendances et structure"
```

---

## CHANTIER 2 : Modèles de données et enums

### Objectif
Créer les modèles de données pour les contacts et l'historique.

### Tâches
1. Créer `lib/models/enums.dart` :
   - Enum `CallFrequency` (weekly, biweekly, monthly, quarterly, yearly)
   - Enum `ContactCategory` (family, friends, professional)
   - Enum `Priority` (high, medium, low, birthday)
   - **Enum `ContactMethod` (call, sms)**
   - **Enum `ContactContext` (normal, birthday)**

2. Créer `lib/models/tracked_contact.dart` :
   - Classe `TrackedContact` avec tous les champs incluant :
     - **birthday (DateTime? nullable)** - date d'anniversaire
   - Méthodes `toMap()` et `fromMap()` pour SQLite
   - Méthode `copyWith()`

3. Créer `lib/models/contact_record.dart` (anciennement call_record.dart) :
   - Classe `ContactRecord` avec les champs :
     - id, trackedContactId, contactDate
     - **contactMethod (ContactMethod)** - appel ou SMS
     - contactType (manual/automatic)
     - **context (ContactContext)** - normal ou anniversaire
   - Méthodes `toMap()` et `fromMap()`

4. Ajouter des commentaires de documentation pour chaque classe

### Commit
```
git add .
git commit -m "chantier 2: création des modèles de données et enums"
```

---

## CHANTIER 3 : Service de base de données

### Objectif
Implémenter SQLite pour stocker les contacts et l'historique.

### Tâches
1. Créer `lib/services/database_service.dart` :
   - Singleton pour gérer la connexion SQLite
   - Méthode `initDatabase()` créant les tables :
     - `tracked_contacts` avec colonne **birthday (TEXT nullable)**
     - `contact_history` (anciennement call_history) avec colonnes :
       - **contact_method (TEXT)** - "call" ou "sms"
       - **context (TEXT)** - "normal" ou "birthday"
   - CRUD pour `tracked_contacts` :
     - `insertContact(TrackedContact contact)`
     - `getContacts()`
     - `updateContact(TrackedContact contact)`
     - `deleteContact(int id)`
   - CRUD pour `contact_history` :
     - `insertContactRecord(ContactRecord record)`
     - `getContactHistory(int contactId)`
     - `deleteContactHistory(int contactId)`

2. Ajouter la gestion des erreurs avec try-catch
3. Tester la compilation

### Commit
```
git add .
git commit -m "chantier 3: implémentation service base de données SQLite"
```

---

## CHANTIER 4 : Utilitaires de calcul de priorité

### Objectif
Créer la logique de calcul de priorité et formatage des dates.

### Tâches
1. Créer `lib/utils/constants.dart` :
   - Constantes pour les durées (7, 14, 30, 90, 365 jours)
   - Constantes de couleurs pour les priorités (incluant couleur anniversaire)
   - **Constante pour seuil anniversaire proche (7 jours)**
   - **Message SMS d'anniversaire par défaut**
   - Constantes de textes

2. Créer `lib/utils/date_utils.dart` :
   - Fonction `formatDate(DateTime date)` pour affichage
   - Fonction `daysSinceLastContact(DateTime? lastContact)`

3. Créer `lib/utils/birthday_utils.dart` :
   - **Fonction `getNextBirthday(DateTime birthday)` retournant prochain anniversaire**
   - **Fonction `daysUntilBirthday(DateTime? birthday)` retournant nombre de jours**
   - **Fonction `isBirthdayToday(DateTime? birthday)` retournant bool**
   - **Fonction `isBirthdaySoon(DateTime? birthday)` (dans les 7 jours)**

4. Créer `lib/utils/priority_calculator.dart` :
   - Fonction `calculatePriority(TrackedContact contact)` retournant Priority
     - **Vérifier d'abord si anniversaire aujourd'hui → Priority.birthday**
   - Fonction `getDaysUntilNextContact(TrackedContact contact)`
   - Fonction `getExpectedDelay(CallFrequency frequency)` en jours

5. Ajouter des tests unitaires dans `test/priority_calculator_test.dart` et `test/birthday_utils_test.dart`

### Commit
```
git add .
git commit -m "chantier 4: utilitaires de calcul de priorité et dates"
```

---

## CHANTIER 5 : Service de permissions

### Objectif
Gérer les permissions Android (contacts et appels).

### Tâches
1. Créer `lib/services/permission_service.dart` :
   - Méthode `requestContactsPermission()` retournant bool
   - Méthode `requestCallPermission()` retournant bool
   - **Méthode `requestSmsPermission()` retournant bool**
   - Méthode `checkContactsPermission()` (vérification sans demande)
   - Méthode `openAppSettings()` si permissions refusées définitivement

2. Gérer les différents états de permissions (granted, denied, permanentlyDenied)
3. Tester la compilation

### Commit
```
git add .
git commit -m "chantier 5: service de gestion des permissions Android"
```

---

## CHANTIER 6 : Service de contacts Android

### Objectif
Accéder au répertoire de contacts Android.

### Tâches
1. Créer `lib/services/contacts_service.dart` :
   - Méthode `getAndroidContacts()` retournant List de contacts natifs
   - **Méthode `getContactBirthday(Contact contact)` pour récupérer anniversaire si disponible**
   - Méthode `searchContacts(String query)` pour recherche
   - Gestion des permissions avant accès
   - Gestion des erreurs

2. Tester la compilation

### Commit
```
git add .
git commit -m "chantier 6: service d'accès aux contacts Android"
```

---

## CHANTIER 7 : Service de communication (appels et SMS)

### Objectif
Lancer des appels, envoyer des SMS et enregistrer l'historique.

### Tâches
1. Créer `lib/services/communication_service.dart` (anciennement call_service.dart) :
   - **Méthode `makeCall(String phoneNumber)` utilisant url_launcher (tel:)**
   - **Méthode `sendSms(String phoneNumber, {String? message})` utilisant url_launcher (sms:)**
   - **Méthode `sendBirthdaySms(String phoneNumber, String firstName)` avec message pré-rempli**
   - **Méthode `recordContact(int contactId, ContactMethod method, ContactContext context)`**
   - Gestion des permissions avant appel/SMS
   - Gestion des erreurs

2. Tester la compilation

### Commit
```
git add .
git commit -m "chantier 7: service de communication (appels et SMS) et enregistrement"
```

---

## CHANTIER 8 : Provider pour les contacts

### Objectif
Gérer l'état des contacts suivis avec Provider.

### Tâches
1. Créer `lib/providers/contacts_provider.dart` :
   - Classe `ContactsProvider extends ChangeNotifier`
   - Liste `_contacts` de TrackedContact
   - Méthode `loadContacts()` depuis la BDD
   - Méthode `addContact(TrackedContact contact)`
   - Méthode `updateContact(TrackedContact contact)`
   - Méthode `deleteContact(int id)`
   - **Méthode `recordContact(int contactId, ContactMethod method, ContactContext context)`**
   - **Méthode `getSortedContacts()` triée par :**
     - **1. Anniversaire aujourd'hui (Priority.birthday)**
     - **2. Anniversaire dans 7 jours (avec badge)**
     - **3. Priorité contact (high → low)**
     - **4. Délai écoulé**
   - Appeler `notifyListeners()` après chaque modification

2. Tester la compilation

### Commit
```
git add .
git commit -m "chantier 8: provider pour gestion d'état des contacts"
```

---

## CHANTIER 9 : Provider pour les filtres

### Objectif
Gérer l'état des filtres de la liste.

### Tâches
1. Créer `lib/providers/filters_provider.dart` :
   - Classe `FiltersProvider extends ChangeNotifier`
   - Propriétés : `selectedCategory`, `selectedFrequency`, `selectedPriority`
   - **Propriété `showOnlyBirthdays` (bool)** - filtre anniversaires uniquement
   - Méthodes pour changer chaque filtre
   - **Méthode `toggleBirthdaysFilter()`**
   - Méthode `applyFilters(List<TrackedContact> contacts)` retournant liste filtrée
     - **Inclure logique de filtrage par anniversaire proche**
   - Méthode `resetFilters()`

2. Tester la compilation

### Commit
```
git add .
git commit -m "chantier 9: provider pour gestion des filtres"
```

---

## CHANTIER 10 : Widgets réutilisables

### Objectif
Créer les widgets personnalisés pour l'UI.

### Tâches
1. Créer `lib/widgets/priority_indicator.dart` :
   - Widget affichant une pastille de couleur selon Priority
   - Utiliser les constantes de couleurs

2. **Créer `lib/widgets/birthday_badge.dart` :**
   - **Widget affichant badge anniversaire (icône gâteau 🎂)**
   - **Afficher si anniversaire aujourd'hui ou dans les 7 jours**
   - **Afficher nombre de jours restants**

3. Créer `lib/widgets/contact_card.dart` :
   - Card affichant un TrackedContact
   - Photo, nom, catégorie, dernière date de contact
   - PriorityIndicator intégré
   - **BirthdayBadge si anniversaire proche**
   - **Actions : boutons Téléphone et SMS**
   - **Menu contextuel au tap : Appeler / SMS / Marquer contacté**

4. Créer `lib/widgets/empty_state.dart` :
   - Widget affiché quand liste vide
   - Message + icône + bouton CTA

5. Créer `lib/widgets/filter_chips.dart` :
   - Chips pour filtrage rapide
   - **Inclure chip/toggle "Anniversaires"**
   - Utilise FiltersProvider

5. Tester la compilation

### Commit
```
git add .
git commit -m "chantier 10: création des widgets réutilisables"
```

---

## CHANTIER 11 : Écran d'accueil (Home)

### Objectif
Créer l'écran principal avec la liste des contacts.

### Tâches
1. Créer `lib/screens/home_screen.dart` :
   - AppBar avec titre "CallLog"
   - Consumer de ContactsProvider et FiltersProvider
   - ListView.builder avec ContactCard pour chaque contact
   - FloatingActionButton pour ajouter un contact
   - Afficher EmptyState si liste vide
   - Afficher FilterChips en haut de la liste
   - Pull-to-refresh pour recharger

2. Tester la compilation

### Commit
```
git add .
git commit -m "chantier 11: écran d'accueil avec liste des contacts"
```

---

## CHANTIER 12 : Écran d'ajout de contact

### Objectif
Permettre d'ajouter un contact depuis le répertoire Android.

### Tâches
1. Créer `lib/screens/add_contact_screen.dart` :
   - AppBar avec titre "Ajouter un contact"
   - Champ de recherche de contacts
   - Liste des contacts Android filtrée
   - Sélection d'un contact ouvre un formulaire :
     - Dropdown pour fréquence (CallFrequency)
     - Dropdown/Radio pour catégorie (ContactCategory)
     - **DatePicker pour date d'anniversaire (optionnel)**
     - **Tentative d'import automatique anniversaire depuis contact Android**
     - Bouton "Ajouter au suivi"
   - Vérifier permissions avant d'accéder aux contacts
   - Gérer le cas où permissions refusées
   - Retour à l'écran d'accueil après ajout

2. Tester la compilation

### Commit
```
git add .
git commit -m "chantier 12: écran d'ajout de contact depuis répertoire"
```

---

## CHANTIER 13 : Écran de détails d'un contact

### Objectif
Afficher les détails et l'historique d'un contact.

### Tâches
1. Créer `lib/screens/contact_detail_screen.dart` :
   - AppBar avec nom du contact et bouton supprimer
   - Section informations : photo, nom, téléphone, catégorie, fréquence
   - **Affichage anniversaire avec âge si disponible**
   - Indicateur de priorité
   - **Section "Actions rapides" :**
     - **Bouton "Appeler"**
     - **Bouton "SMS"**
     - **Si anniversaire proche : bouton "SMS d'anniversaire" avec message pré-rempli**
   - Bouton "Marquer comme contacté"
   - **Section "Historique des contacts" :**
     - **Liste des ContactRecord depuis la BDD**
     - **Affichage date, heure, type (appel/SMS), contexte (normal/anniversaire)**
     - **Icônes différentes pour appel vs SMS**
   - Bouton "Modifier" pour éditer fréquence/catégorie/anniversaire
   - Dialog de confirmation pour suppression

2. Tester la compilation

### Commit
```
git add .
git commit -m "chantier 13: écran de détails et historique d'un contact"
```

---

## CHANTIER 14 : Écran/Modal de filtres

### Objectif
Interface complète de filtrage.

### Tâches
1. Créer `lib/screens/filter_screen.dart` (ou BottomSheet) :
   - Section "Catégorie" avec radio buttons (Tous, Famille, Amis, Pro)
   - Section "Fréquence" avec radio buttons (Tous, Hebdo, Bihebdo, etc.)
   - Section "Priorité" avec radio buttons (Tous, Haute, Moyenne, Basse)
   - Bouton "Appliquer"
   - Bouton "Réinitialiser"
   - Met à jour FiltersProvider

2. Lier cette modal à l'icône de filtre dans HomeScreen

3. Tester la compilation

### Commit
```
git add .
git commit -m "chantier 14: écran/modal de filtrage avancé"
```

---

## CHANTIER 15 : Configuration du main.dart

### Objectif
Assembler l'application avec les providers et initialisation.

### Tâches
1. Modifier `lib/main.dart` :
   - Initialiser DatabaseService dans `main()`
   - Configurer MultiProvider avec ContactsProvider et FiltersProvider
   - Définir MaterialApp avec theme Material Design 3
   - Définir HomeScreen comme écran initial
   - Configurer les routes nommées pour les écrans
   - Gérer le chargement initial (SplashScreen ou CircularProgressIndicator)

2. Tester la compilation complète : `flutter run`

### Commit
```
git add .
git commit -m "chantier 15: configuration main.dart et assembly de l'app"
```

---

## CHANTIER 16 : Tests et corrections de bugs

### Objectif
Tester l'application de bout en bout et corriger les bugs.

### Tâches
1. Tester chaque flux utilisateur :
   - Ajout d'un contact
   - Marquage d'appel manuel
   - Lancement d'un appel téléphonique
   - Filtrage
   - Suppression d'un contact
   - Édition d'un contact

2. Vérifier les permissions sur un vrai appareil Android

3. Corriger les bugs identifiés

4. Vérifier la gestion des cas limites :
   - Liste vide
   - Permissions refusées
   - Contact sans numéro de téléphone
   - Base de données corrompue

5. Optimiser les performances si nécessaire

### Commit
```
git add .
git commit -m "chantier 16: tests complets et corrections de bugs"
```

---

## CHANTIER 17 : Améliorations UI/UX et finalisation

### Objectif
Peaufiner l'interface et l'expérience utilisateur.

### Tâches
1. Ajouter des animations (Hero, transitions)
2. Améliorer le responsive design
3. Ajouter des messages de confirmation (SnackBar)
4. Améliorer l'accessibilité (labels, semantics)
5. Optimiser les couleurs et le thème
6. Ajouter une icône d'application personnalisée
7. Mettre à jour le README.md avec :
   - Description complète
   - Screenshots (si possible)
   - Instructions d'installation
   - Technologies utilisées

### Commit
```
git add .
git commit -m "chantier 17: améliorations UI/UX et finalisation"
```

---

## CHANTIER 18 : Build de production

### Objectif
Générer l'APK de production.

### Tâches
1. Configurer `android/app/build.gradle` :
   - Vérifier versionCode et versionName
   - Configurer minSdkVersion (21 minimum)
   - Configurer targetSdkVersion (33+)

2. Générer l'APK de production :
   ```bash
   flutter build apk --release
   ```

3. Tester l'APK sur un appareil réel

4. Créer un fichier `INSTALLATION.md` avec instructions

### Commit
```
git add .
git commit -m "chantier 18: configuration et build de production"
git tag v1.0.0
```

---

## Notes importantes pour l'IA

### Sécurité
- Ne jamais commit de clés API ou secrets
- Valider toutes les entrées utilisateur
- Gérer proprement les permissions Android
- Utiliser des transactions SQLite pour l'intégrité des données

### Qualité du code
- Respecter les conventions Dart (linter)
- Commenter les fonctions complexes
- Gérer tous les cas d'erreur avec try-catch
- Utiliser const pour les widgets constants (performance)

### Points de reprise
Après chaque chantier, le projet doit :
1. ✅ Compiler sans erreur
2. ✅ Être committé dans git
3. ✅ Avoir un message de commit clair
4. ✅ Être dans un état stable (pas de régression)

### Commandes utiles
```bash
# Vérifier le code
flutter analyze

# Formater le code
flutter format .

# Lancer l'app
flutter run

# Build debug
flutter build apk --debug

# Build release
flutter build apk --release

# Voir les logs
flutter logs
```

---

## CHANTIERS VERSION 1.2 - Synchronisation automatique du journal d'appels

### CHANTIER 19 : Service de lecture du journal d'appels Android

**Objectif** : Créer un service natif Android pour lire le journal d'appels via MethodChannel

**Tâches** :
1. ✅ Modifier `android/app/src/main/kotlin/.../MainActivity.kt` :
   - Créer méthode `getCallsSince(timestamp: Long)`
   - Query sur `CallLog.Calls.CONTENT_URI` avec projection (NUMBER, DATE, TYPE, DURATION)
   - Retourner List<Map<String, Any>> vers Flutter
2. ✅ Ajouter permission dans `AndroidManifest.xml` :
   ```xml
   <uses-permission android:name="android.permission.READ_CALL_LOG" />
   ```
3. ✅ Créer `lib/services/call_log_service.dart` :
   - Méthode `getCallsSince(DateTime since)` utilisant MethodChannel
   - Méthode `syncCallsWithTrackedContacts({DateTime? since})` :
     - Récupérer appels depuis N jours (défaut 30)
     - Filtrer uniquement appels sortants (type 2)
     - Filtrer uniquement appels > 10 secondes
     - Normaliser les numéros (06... → +336..., puis retirer +)
     - Matcher avec contacts suivis
     - Vérifier anti-doublons (tolérance 1 minute)
     - Enregistrer avec vraie date d'appel
   - Méthode `_normalizePhoneNumber(String phone)` pour matching
   - Retourner nombre d'appels synchronisés

**Commit** :
```
git add .
git commit -m "v1.2 chantier 19: service lecture journal d'appels Android"
```

---

### CHANTIER 20 : Synchronisation automatique au démarrage

**Objectif** : Lancer la synchronisation automatiquement au démarrage de l'app

**Tâches** :
1. ✅ Modifier `lib/screens/home_screen.dart` :
   - Dans `initState()`, appeler `_syncCallsInBackground()` après chargement contacts
   - Méthode `_syncCallsInBackground()` :
     - Appeler `CallLogService.syncCallsWithTrackedContacts()`
     - Si appels synchronisés > 0 : recharger contacts et afficher SnackBar
     - Si erreur : silencieuse (ne pas bloquer UI)
2. ✅ Tester sur appareil réel avec historique d'appels

**Commit** :
```
git add .
git commit -m "v1.2 chantier 20: synchronisation auto au démarrage"
```

---

### CHANTIER 21 : Corrections des bugs de dates et doublons

**Objectif** : Corriger les bugs identifiés lors de la synchronisation

**Tâches** :
1. ✅ **Bug dates incorrectes** : Modifier `database_service.recordContact()` :
   - Ajouter paramètre `DateTime? contactDate`
   - Utiliser `contactDate ?? DateTime.now()`
2. ✅ **Bug lastContactDate** : Modifier logique de mise à jour :
   - Ne mettre à jour que si `date.isAfter(contact.lastContactDate!)`
3. ✅ **Bug faux appels** : Ajouter filtre durée dans `call_log_service.dart` :
   - `if (duration < 10) continue;`
4. ✅ Modifier `call_log_service.dart` pour passer `callDateTime` à `recordContact()`

**Commit** :
```
git add .
git commit -m "v1.2 chantier 21: corrections bugs dates et filtrage appels"
```

---

### CHANTIER 22 : Fonctionnalités de gestion manuelle

**Objectif** : Ajouter boutons pour gestion manuelle des contacts

**Tâches** :
1. ✅ **Bouton Reset dernier contact** dans `contact_detail_screen.dart` :
   - Icône refresh à côté de "Dernier contact"
   - Dialog de confirmation
   - Créer nouveau `TrackedContact` avec `lastContactDate: null` (copyWith ne supporte pas null)
   - Afficher "Jamais contacté" si null
2. ✅ **Bouton Marquer comme contacté** :
   - Nouveau bouton "Marquer comme contacté"
   - Enregistrer avec `ContactMethod.other`
   - Mettre à jour `lastContactDate` à maintenant
3. ✅ Ajouter `ContactMethod.other` dans enums avec displayName

**Commit** :
```
git add .
git commit -m "v1.2 chantier 22: boutons reset et marquer comme contacté"
```

---

### CHANTIER 23 : Écran des paramètres avec outils de maintenance

**Objectif** : Créer écran paramètres avec synchronisation et outils debug

**Tâches** :
1. ✅ Créer `lib/screens/settings_screen.dart` :
   - Section "Synchronisation des appels" :
     - Affichage dernière sync
     - Bouton "Synchroniser maintenant"
     - Dropdown période de sync (7/14/30 jours)
   - Section "Maintenance" :
     - Bouton "Nettoyer les doublons"
     - Bouton "Effacer tout l'historique" (avec confirmation)
     - Bouton "Debug Georges" (affiche historique dans dialog)
   - Section "Sauvegarde" (existante) :
     - Export/Import JSON
     - Statistiques
2. ✅ Ajouter méthode `cleanupDuplicates()` dans `database_service.dart` :
   - Parcourir tous contacts
   - Pour chaque contact, récupérer historique
   - Détecter doublons (tolérance 1 minute)
   - Supprimer les doublons
   - Retourner nombre supprimé
3. ✅ Ajouter méthode `_clearAllHistory()` pour reset complet
4. ✅ Ajouter route '/settings' dans `main.dart`
5. ✅ Ajouter bouton Paramètres dans AppBar de `home_screen.dart`

**Commit** :
```
git add .
git commit -m "v1.2 chantier 23: écran paramètres avec outils maintenance"
```

---

### CHANTIER 24 : Ajustement du filtre de priorité

**Objectif** : Rendre le filtre "À contacter" plus strict

**Tâches** :
1. ✅ Modifier `lib/utils/constants.dart` :
   - Changer `mediumPriorityThreshold` de 0.8 à 0.95
2. ✅ Impact : Contacts affichés en "vert" uniquement si contactés dans les 95% du délai attendu

**Commit** :
```
git add .
git commit -m "v1.2 chantier 24: filtre priorité strict (95%)"
```

---

### CHANTIER 25 : Tests et validation v1.2

**Objectif** : Tester toutes les nouvelles fonctionnalités

**Tâches** :
1. ✅ Tester synchronisation au démarrage
2. ✅ Tester bouton synchronisation manuelle
3. ✅ Vérifier filtrage appels (sortants, >10s)
4. ✅ Vérifier dates correctes dans historique
5. ✅ Tester reset dernier contact
6. ✅ Tester marquer comme contacté
7. ✅ Tester nettoyage doublons
8. ✅ Tester effacer historique + resync
9. ✅ Vérifier normalisation numéros (06 vs +336)
10. ✅ Tester sur plusieurs contacts différents

**Commit** :
```
git add .
git commit -m "v1.2 chantier 25: tests et validation version 1.2"
```

---

### CHANTIER 26 : Build et release v1.2

**Objectif** : Générer l'APK de production v1.2

**Tâches** :
1. Mettre à jour `android/app/build.gradle` :
   - versionCode: 3
   - versionName: "1.2.0"
2. Générer APK release : `flutter build apk --release`
3. Tester APK sur appareil réel
4. Mettre à jour SPEC.md avec nouveautés v1.2 ✅
5. Mettre à jour CHANTIERS.md avec liste chantiers v1.2 ✅
6. Mettre à jour README.md avec fonctionnalités v1.2

**Commit** :
```
git add .
git commit -m "v1.2 chantier 26: build et documentation version 1.2"
git tag v1.2.0
```

---

**Version** : 1.2
**Date** : 2025-10-04
**Nombre de chantiers** : 26 (18 base + 8 v1.2)
