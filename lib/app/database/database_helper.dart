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
      version: 2,
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

    if (oldVersion < 2) {
      // Add incidents table
      await db.execute('''
        CREATE TABLE incidents (
          id TEXT PRIMARY KEY,
          type TEXT NOT NULL,
          title TEXT NOT NULL,
          description TEXT NOT NULL,
          location_name TEXT NOT NULL,
          latitude REAL,
          longitude REAL,
          severity TEXT NOT NULL,
          status TEXT NOT NULL,
          reporter_id TEXT NOT NULL,
          reporter_name TEXT NOT NULL,
          assigned_to_id TEXT,
          assigned_to_name TEXT,
          media_file_paths TEXT,
          created_at INTEGER NOT NULL DEFAULT (strftime('%s','now') * 1000),
          updated_at INTEGER NOT NULL DEFAULT (strftime('%s','now') * 1000),
          resolved_at INTEGER
        )
      ''');

      // Add alerts table
      await db.execute('''
        CREATE TABLE alerts (
          id TEXT PRIMARY KEY,
          incident_id TEXT,
          title TEXT NOT NULL,
          message TEXT NOT NULL,
          severity TEXT NOT NULL,
          target_audience TEXT NOT NULL,
          sent_at INTEGER NOT NULL,
          expires_at INTEGER,
          created_by_id TEXT NOT NULL,
          created_by_name TEXT NOT NULL,
          FOREIGN KEY (incident_id) REFERENCES incidents(id) ON DELETE CASCADE
        )
      ''');

      // Add alert_acknowledgments table
      await db.execute('''
        CREATE TABLE alert_acknowledgments (
          id TEXT PRIMARY KEY,
          alert_id TEXT NOT NULL,
          staff_id TEXT NOT NULL,
          staff_name TEXT NOT NULL,
          acknowledged_at INTEGER NOT NULL DEFAULT (strftime('%s','now') * 1000),
          FOREIGN KEY (alert_id) REFERENCES alerts(id) ON DELETE CASCADE
        )
      ''');

      // Create indexes for new tables
      await db.execute(
          'CREATE INDEX idx_incidents_created_at ON incidents(created_at DESC)');
      await db.execute(
          'CREATE INDEX idx_incidents_status ON incidents(status)');
      await db.execute(
          'CREATE INDEX idx_incidents_severity ON incidents(severity)');
      await db.execute(
          'CREATE INDEX idx_incidents_type ON incidents(type)');

      await db.execute(
          'CREATE INDEX idx_alerts_sent_at ON alerts(sent_at DESC)');
      await db.execute(
          'CREATE INDEX idx_alerts_severity ON alerts(severity)');
      await db.execute(
          'CREATE INDEX idx_alerts_target ON alerts(target_audience)');

      await db.execute(
          'CREATE INDEX idx_alert_acks_alert_id ON alert_acknowledgments(alert_id)');
      await db.execute(
          'CREATE INDEX idx_alert_acks_staff_id ON alert_acknowledgments(staff_id)');

      debugPrint('DatabaseHelper: Upgraded to version 2');
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

    // Create incidents table
    await db.execute('''
      CREATE TABLE incidents (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        location_name TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        severity TEXT NOT NULL,
        status TEXT NOT NULL,
        reporter_id TEXT NOT NULL,
        reporter_name TEXT NOT NULL,
        assigned_to_id TEXT,
        assigned_to_name TEXT,
        media_file_paths TEXT,
        created_at INTEGER NOT NULL DEFAULT (strftime('%s','now') * 1000),
        updated_at INTEGER NOT NULL DEFAULT (strftime('%s','now') * 1000),
        resolved_at INTEGER
      )
    ''');
    debugPrint('DatabaseHelper: Created incidents table');

    // Create alerts table
    await db.execute('''
      CREATE TABLE alerts (
        id TEXT PRIMARY KEY,
        incident_id TEXT,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        severity TEXT NOT NULL,
        target_audience TEXT NOT NULL,
        sent_at INTEGER NOT NULL,
        expires_at INTEGER,
        created_by_id TEXT NOT NULL,
        created_by_name TEXT NOT NULL,
        FOREIGN KEY (incident_id) REFERENCES incidents(id) ON DELETE CASCADE
      )
    ''');
    debugPrint('DatabaseHelper: Created alerts table');

    // Create alert_acknowledgments table
    await db.execute('''
      CREATE TABLE alert_acknowledgments (
        id TEXT PRIMARY KEY,
        alert_id TEXT NOT NULL,
        staff_id TEXT NOT NULL,
        staff_name TEXT NOT NULL,
        acknowledged_at INTEGER NOT NULL DEFAULT (strftime('%s','now') * 1000),
        FOREIGN KEY (alert_id) REFERENCES alerts(id) ON DELETE CASCADE
      )
    ''');
    debugPrint('DatabaseHelper: Created alert_acknowledgments table');

    // Create indexes for performance
    await db.execute(
        'CREATE INDEX idx_translations_conversation_id ON translations(conversation_id)');
    await db.execute(
        'CREATE INDEX idx_translations_timestamp ON translations(timestamp DESC)');
    await db.execute(
        'CREATE INDEX idx_conversations_start_time ON conversations(start_time DESC)');

    // Create indexes for incidents
    await db.execute(
        'CREATE INDEX idx_incidents_created_at ON incidents(created_at DESC)');
    await db.execute(
        'CREATE INDEX idx_incidents_status ON incidents(status)');
    await db.execute(
        'CREATE INDEX idx_incidents_severity ON incidents(severity)');
    await db.execute(
        'CREATE INDEX idx_incidents_type ON incidents(type)');

    // Create indexes for alerts
    await db.execute(
        'CREATE INDEX idx_alerts_sent_at ON alerts(sent_at DESC)');
    await db.execute(
        'CREATE INDEX idx_alerts_severity ON alerts(severity)');
    await db.execute(
        'CREATE INDEX idx_alerts_target ON alerts(target_audience)');

    // Create indexes for alert_acknowledgments
    await db.execute(
        'CREATE INDEX idx_alert_acks_alert_id ON alert_acknowledgments(alert_id)');
    await db.execute(
        'CREATE INDEX idx_alert_acks_staff_id ON alert_acknowledgments(staff_id)');

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
