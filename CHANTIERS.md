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
│   │   ├── call_record.dart
│   │   └── enums.dart
│   ├── services/
│   │   ├── database_service.dart
│   │   ├── contacts_service.dart
│   │   ├── call_service.dart
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
│   │   └── empty_state.dart
│   └── utils/
│       ├── constants.dart
│       ├── date_utils.dart
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
   - Enum `Priority` (high, medium, low)

2. Créer `lib/models/tracked_contact.dart` :
   - Classe `TrackedContact` avec tous les champs
   - Méthodes `toMap()` et `fromMap()` pour SQLite
   - Méthode `copyWith()`

3. Créer `lib/models/call_record.dart` :
   - Classe `CallRecord` avec les champs
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
   - Méthode `initDatabase()` créant les tables `tracked_contacts` et `call_history`
   - CRUD pour `tracked_contacts` :
     - `insertContact(TrackedContact contact)`
     - `getContacts()`
     - `updateContact(TrackedContact contact)`
     - `deleteContact(int id)`
   - CRUD pour `call_history` :
     - `insertCallRecord(CallRecord record)`
     - `getCallHistory(int contactId)`
     - `deleteCallHistory(int contactId)`

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
   - Constantes de couleurs pour les priorités
   - Constantes de textes

2. Créer `lib/utils/date_utils.dart` :
   - Fonction `formatDate(DateTime date)` pour affichage
   - Fonction `daysSinceLastCall(DateTime? lastCall)`

3. Créer `lib/utils/priority_calculator.dart` :
   - Fonction `calculatePriority(TrackedContact contact)` retournant Priority
   - Fonction `getDaysUntilNextCall(TrackedContact contact)`
   - Fonction `getExpectedDelay(CallFrequency frequency)` en jours

4. Ajouter des tests unitaires dans `test/priority_calculator_test.dart`

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

## CHANTIER 7 : Service d'appels téléphoniques

### Objectif
Lancer des appels et enregistrer l'historique.

### Tâches
1. Créer `lib/services/call_service.dart` :
   - Méthode `makeCall(String phoneNumber)` utilisant url_launcher
   - Méthode `recordCall(int contactId)` enregistrant dans la BDD
   - Gestion des permissions avant appel
   - Gestion des erreurs

2. Tester la compilation

### Commit
```
git add .
git commit -m "chantier 7: service d'appels téléphoniques et enregistrement"
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
   - Méthode `recordCall(int contactId)`
   - Méthode `getSortedContacts()` triée par priorité
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
   - Méthodes pour changer chaque filtre
   - Méthode `applyFilters(List<TrackedContact> contacts)` retournant liste filtrée
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

2. Créer `lib/widgets/contact_card.dart` :
   - Card affichant un TrackedContact
   - Photo, nom, catégorie, dernière date d'appel
   - PriorityIndicator intégré
   - Actions : tap pour appeler, bouton "Appelé", bouton détails

3. Créer `lib/widgets/empty_state.dart` :
   - Widget affiché quand liste vide
   - Message + icône + bouton CTA

4. Créer `lib/widgets/filter_chips.dart` :
   - Chips pour filtrage rapide
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
   - Indicateur de priorité
   - Bouton "Appeler maintenant"
   - Bouton "Marquer comme appelé"
   - Section "Historique des appels" :
     - Liste des CallRecord depuis la BDD
     - Affichage date et heure de chaque appel
   - Bouton "Modifier" pour éditer fréquence/catégorie
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

**Version** : 1.0
**Date** : 2025-10-03
**Nombre de chantiers** : 18
