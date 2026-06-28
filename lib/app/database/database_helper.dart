import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// SQLite database helper for managing conversations, translations, and settings
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  /// Get database instance (creates if doesn't exist)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('speech_translator.db');
    return _database!;
  }

  /// Initialize database
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    debugPrint('DatabaseHelper: Initializing database at $path');

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
      onConfigure: _onConfigure,
    );
  }

  /// Configure database (enable foreign keys)
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
    debugPrint('DatabaseHelper: Foreign key constraints enabled');
  }

  /// Upgrade database from old version to new version
  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    debugPrint(
        'DatabaseHelper: Upgrading database from v$oldVersion to v$newVersion');

    if (oldVersion < 3) {
      // Remove incidents, alerts, and alert_acknowledgments tables
      // These are now managed by the online API
      await db.execute('DROP TABLE IF EXISTS alert_acknowledgments');
      await db.execute('DROP TABLE IF EXISTS alerts');
      await db.execute('DROP TABLE IF EXISTS incidents');
      debugPrint(
          'DatabaseHelper: Dropped incidents/alerts/alert_acknowledgments tables (now API-based)');
    }
  }

  /// Create database tables
  Future<void> _createDB(Database db, int version) async {
    debugPrint('DatabaseHelper: Creating database schema version $version');

    // Create conversations table
    await db.execute('''
      CREATE TABLE conversations (
        id TEXT PRIMARY KEY,
        source_language TEXT NOT NULL,
        target_language TEXT NOT NULL,
        start_time INTEGER NOT NULL,
        end_time INTEGER,
        audio_file_path TEXT,
        duration_seconds INTEGER,
        created_at INTEGER NOT NULL DEFAULT (strftime('%s','now') * 1000),
        updated_at INTEGER NOT NULL DEFAULT (strftime('%s','now') * 1000)
      )
    ''');
    debugPrint('DatabaseHelper: Created conversations table');

    // Create translations table
    await db.execute('''
      CREATE TABLE translations (
        id TEXT PRIMARY KEY,
        conversation_id TEXT NOT NULL,
        original_text TEXT NOT NULL,
        translated_text TEXT NOT NULL,
        source_language TEXT NOT NULL,
        target_language TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        is_final INTEGER NOT NULL DEFAULT 0,
        audio_file_path TEXT,
        audio_start_offset_ms INTEGER,
        audio_duration_ms INTEGER,
        created_at INTEGER NOT NULL DEFAULT (strftime('%s','now') * 1000),
        FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE
      )
    ''');
    debugPrint('DatabaseHelper: Created translations table');

    // Create settings table
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        value_type TEXT NOT NULL,
        updated_at INTEGER NOT NULL DEFAULT (strftime('%s','now') * 1000)
      )
    ''');
    debugPrint('DatabaseHelper: Created settings table');

    // Create indexes for performance
    await db.execute(
        'CREATE INDEX idx_translations_conversation_id ON translations(conversation_id)');
    await db.execute(
        'CREATE INDEX idx_translations_timestamp ON translations(timestamp DESC)');
    await db.execute(
        'CREATE INDEX idx_conversations_start_time ON conversations(start_time DESC)');

    debugPrint('DatabaseHelper: Created indexes');
    debugPrint('DatabaseHelper: Database schema created successfully');
  }

  /// Close database connection
  Future<void> close() async {
    final db = await instance.database;
    await db.close();
    debugPrint('DatabaseHelper: Database closed');
  }

  /// Delete database (for testing/reset purposes)
  Future<void> deleteDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'speech_translator.db');
    await deleteDatabase(path);
    _database = null;
    debugPrint('DatabaseHelper: Database deleted');
  }
}
