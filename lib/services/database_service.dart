import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/tracked_contact.dart';
import '../models/contact_record.dart';
import '../models/contact_note.dart';
import '../models/enums.dart';

/// Service singleton pour gérer la base de données SQLite
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  /// Récupère l'instance de la base de données
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }

  /// Initialise la base de données et crée les tables
  Future<Database> initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'calllog.db');

    return await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Crée les tables de la base de données
  Future<void> _onCreate(Database db, int version) async {
    // Table tracked_contacts
    await db.execute('''
      CREATE TABLE tracked_contacts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        contact_id TEXT NOT NULL,
        contact_name TEXT NOT NULL,
        contact_phone TEXT NOT NULL,
        frequency TEXT NOT NULL,
        category TEXT NOT NULL,
        last_contact_date TEXT,
        birthday TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Table contact_history
    await db.execute('''
      CREATE TABLE contact_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tracked_contact_id INTEGER NOT NULL,
        contact_date TEXT NOT NULL,
        contact_method TEXT NOT NULL,
        contact_type TEXT NOT NULL,
        context TEXT NOT NULL,
        FOREIGN KEY (tracked_contact_id) REFERENCES tracked_contacts (id) ON DELETE CASCADE
      )
    ''');

    // Index pour améliorer les performances
    await db.execute('''
      CREATE INDEX idx_tracked_contact_id ON contact_history(tracked_contact_id)
    ''');

    // Table contact_notes
    await db.execute('''
      CREATE TABLE contact_notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tracked_contact_id INTEGER NOT NULL,
        content TEXT NOT NULL,
        audio_path TEXT,
        category TEXT NOT NULL DEFAULT 'general',
        importance TEXT NOT NULL DEFAULT 'medium',
        is_pinned INTEGER NOT NULL DEFAULT 0,
        is_action_item INTEGER NOT NULL DEFAULT 0,
        due_date TEXT,
        is_completed INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY (tracked_contact_id) REFERENCES tracked_contacts (id) ON DELETE CASCADE
      )
    ''');

    // Index pour améliorer les performances
    await db.execute('''
      CREATE INDEX idx_note_contact_id ON contact_notes(tracked_contact_id)
    ''');
  }

  /// Gère les migrations de version de la base de données
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Migration vers version 2: ajout de la table contact_notes
      await db.execute('''
        CREATE TABLE contact_notes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          tracked_contact_id INTEGER NOT NULL,
          content TEXT NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT,
          FOREIGN KEY (tracked_contact_id) REFERENCES tracked_contacts (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE INDEX idx_note_contact_id ON contact_notes(tracked_contact_id)
      ''');
    }

    if (oldVersion < 3) {
      // Migration vers version 3: ajout des nouvelles colonnes aux notes
      await db.execute('ALTER TABLE contact_notes ADD COLUMN category TEXT NOT NULL DEFAULT "general"');
      await db.execute('ALTER TABLE contact_notes ADD COLUMN importance TEXT NOT NULL DEFAULT "medium"');
      await db.execute('ALTER TABLE contact_notes ADD COLUMN is_pinned INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE contact_notes ADD COLUMN is_action_item INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE contact_notes ADD COLUMN due_date TEXT');
      await db.execute('ALTER TABLE contact_notes ADD COLUMN is_completed INTEGER NOT NULL DEFAULT 0');
    }

    if (oldVersion < 4) {
      // Migration vers version 4: ajout de la colonne audio_path aux notes
      await db.execute('ALTER TABLE contact_notes ADD COLUMN audio_path TEXT');
    }
  }

  // ==================== CRUD TrackedContact ====================

  /// Insère un nouveau contact suivi
  Future<int> insertContact(TrackedContact contact) async {
    try {
      final db = await database;
      return await db.insert(
        'tracked_contacts',
        contact.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw Exception('Erreur lors de l\'insertion du contact: $e');
    }
  }

  /// Récupère tous les contacts suivis
  Future<List<TrackedContact>> getContacts() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('tracked_contacts');

      return List.generate(maps.length, (i) {
        return TrackedContact.fromMap(maps[i]);
      });
    } catch (e) {
      throw Exception('Erreur lors de la récupération des contacts: $e');
    }
  }

  /// Récupère un contact par son ID
  Future<TrackedContact?> getContactById(int id) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'tracked_contacts',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isEmpty) return null;
      return TrackedContact.fromMap(maps.first);
    } catch (e) {
      throw Exception('Erreur lors de la récupération du contact: $e');
    }
  }

  /// Récupère un contact par son ID (alias pour compatibilité)
  Future<TrackedContact?> getTrackedContactById(int id) async {
    return getContactById(id);
  }

  /// Met à jour un contact existant
  Future<int> updateContact(TrackedContact contact) async {
    try {
      final db = await database;
      return await db.update(
        'tracked_contacts',
        contact.toMap(),
        where: 'id = ?',
        whereArgs: [contact.id],
      );
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du contact: $e');
    }
  }

  /// Met à jour un contact existant (alias pour compatibilité)
  Future<int> updateTrackedContact(TrackedContact contact) async {
    return updateContact(contact);
  }

  /// Supprime un contact et son historique
  Future<int> deleteContact(int id) async {
    try {
      final db = await database;

      // Supprimer d'abord l'historique (cascade normalement mais par sécurité)
      await deleteContactHistory(id);

      // Supprimer le contact
      return await db.delete(
        'tracked_contacts',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw Exception('Erreur lors de la suppression du contact: $e');
    }
  }

  // ==================== CRUD ContactRecord ====================

  /// Insère un nouvel enregistrement de contact
  Future<int> insertContactRecord(ContactRecord record) async {
    try {
      final db = await database;
      return await db.insert(
        'contact_history',
        record.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw Exception('Erreur lors de l\'insertion de l\'enregistrement: $e');
    }
  }

  /// Récupère l'historique des contacts pour un contact donné
  Future<List<ContactRecord>> getContactHistory(int contactId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'contact_history',
        where: 'tracked_contact_id = ?',
        whereArgs: [contactId],
        orderBy: 'contact_date DESC',
      );

      return List.generate(maps.length, (i) {
        return ContactRecord.fromMap(maps[i]);
      });
    } catch (e) {
      throw Exception('Erreur lors de la récupération de l\'historique: $e');
    }
  }

  /// Récupère le dernier contact pour un contact donné
  Future<ContactRecord?> getLastContact(int contactId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'contact_history',
        where: 'tracked_contact_id = ?',
        whereArgs: [contactId],
        orderBy: 'contact_date DESC',
        limit: 1,
      );

      if (maps.isEmpty) return null;
      return ContactRecord.fromMap(maps.first);
    } catch (e) {
      throw Exception('Erreur lors de la récupération du dernier contact: $e');
    }
  }

  /// Supprime tout l'historique d'un contact
  Future<int> deleteContactHistory(int contactId) async {
    try {
      final db = await database;
      return await db.delete(
        'contact_history',
        where: 'tracked_contact_id = ?',
        whereArgs: [contactId],
      );
    } catch (e) {
      throw Exception('Erreur lors de la suppression de l\'historique: $e');
    }
  }

  /// Supprime un enregistrement spécifique
  Future<int> deleteContactRecord(int recordId) async {
    try {
      final db = await database;
      return await db.delete(
        'contact_history',
        where: 'id = ?',
        whereArgs: [recordId],
      );
    } catch (e) {
      throw Exception('Erreur lors de la suppression de l\'enregistrement: $e');
    }
  }

  /// Enregistre un contact avec toutes les métadonnées
  Future<void> recordContact({
    required int trackedContactId,
    required ContactMethod contactMethod,
    required ContactContext context,
    DateTime? contactDate,
  }) async {
    try {
      final date = contactDate ?? DateTime.now();

      final record = ContactRecord(
        trackedContactId: trackedContactId,
        contactDate: date,
        contactMethod: contactMethod,
        contactType: contactMethod.toJson(), // compatibility
        context: context,
      );

      await insertContactRecord(record);

      // Mettre à jour la date de dernier contact si c'est plus récent
      final contact = await getContactById(trackedContactId);
      if (contact != null) {
        // Ne mettre à jour que si la nouvelle date est plus récente
        if (contact.lastContactDate == null || date.isAfter(contact.lastContactDate!)) {
          final updatedContact = contact.copyWith(lastContactDate: date);
          await updateContact(updatedContact);
        }
      }
    } catch (e) {
      throw Exception('Erreur lors de l\'enregistrement du contact: $e');
    }
  }

  // ==================== CRUD ContactNote ====================

  /// Insère une nouvelle note
  Future<int> insertNote(ContactNote note) async {
    try {
      final db = await database;
      return await db.insert(
        'contact_notes',
        note.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw Exception('Erreur lors de l\'insertion de la note: $e');
    }
  }

  /// Récupère toutes les notes pour un contact donné
  /// Triées par: épinglées d'abord, puis par date de création décroissante
  Future<List<ContactNote>> getNotes(int contactId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'contact_notes',
        where: 'tracked_contact_id = ?',
        whereArgs: [contactId],
        orderBy: 'is_pinned DESC, created_at DESC',
      );

      return List.generate(maps.length, (i) {
        return ContactNote.fromMap(maps[i]);
      });
    } catch (e) {
      throw Exception('Erreur lors de la récupération des notes: $e');
    }
  }

  /// Met à jour une note existante
  Future<int> updateNote(ContactNote note) async {
    try {
      final db = await database;
      return await db.update(
        'contact_notes',
        note.toMap(),
        where: 'id = ?',
        whereArgs: [note.id],
      );
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de la note: $e');
    }
  }

  /// Supprime une note
  Future<int> deleteNote(int noteId) async {
    try {
      final db = await database;
      return await db.delete(
        'contact_notes',
        where: 'id = ?',
        whereArgs: [noteId],
      );
    } catch (e) {
      throw Exception('Erreur lors de la suppression de la note: $e');
    }
  }

  // ==================== Utilitaires ====================

  /// Supprime les doublons dans l'historique des contacts
  /// Garde uniquement le premier enregistrement pour chaque date/heure
  Future<int> cleanupDuplicates() async {
    try {
      final db = await database;
      int deletedCount = 0;

      // Récupérer tous les contacts
      final contacts = await getContacts();

      for (var contact in contacts) {
        if (contact.id == null) continue;

        // Récupérer l'historique du contact
        final history = await getContactHistory(contact.id!);

        // Grouper par date (avec tolérance de 1 minute)
        final toDelete = <int>[];
        for (int i = 0; i < history.length; i++) {
          for (int j = i + 1; j < history.length; j++) {
            final diff = history[i].contactDate.difference(history[j].contactDate).abs();
            if (diff.inMinutes < 1 && history[j].id != null) {
              // Marquer le deuxième comme doublon
              toDelete.add(history[j].id!);
            }
          }
        }

        // Supprimer les doublons
        for (var recordId in toDelete) {
          await deleteContactRecord(recordId);
          deletedCount++;
        }
      }

      return deletedCount;
    } catch (e) {
      throw Exception('Erreur lors du nettoyage des doublons: $e');
    }
  }

  /// Ferme la connexion à la base de données
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// Supprime toute la base de données (utile pour les tests)
  Future<void> deleteDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'calllog.db');
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}
