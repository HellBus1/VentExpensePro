import 'package:sqflite/sqflite.dart';

/// SQLite database provider — singleton access to the local ledger database.
class LocalDatabase {
  static const String _dbName = 'vent_expense.db';
  static const int _dbVersion = 1;

  static Database? _database;

  /// Returns the singleton database instance, creating it on first access.
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = '$dbPath/$_dbName';

    return openDatabase(path, version: _dbVersion, onCreate: _onCreate);
  }

  static Future<void> _onCreate(Database db, int version) async {
    // — Accounts table —
    await db.execute('''
      CREATE TABLE accounts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type INTEGER NOT NULL,
        balance INTEGER NOT NULL DEFAULT 0,
        currency TEXT NOT NULL DEFAULT 'IDR',
        is_archived INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL
      )
    ''');

    // — Transactions table —
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        amount INTEGER NOT NULL,
        type INTEGER NOT NULL,
        category_id TEXT NOT NULL,
        account_id TEXT NOT NULL,
        to_account_id TEXT,
        note TEXT,
        is_settlement INTEGER NOT NULL DEFAULT 0,
        date_time INTEGER NOT NULL,
        FOREIGN KEY (account_id) REFERENCES accounts(id),
        FOREIGN KEY (to_account_id) REFERENCES accounts(id),
        FOREIGN KEY (category_id) REFERENCES categories(id)
      )
    ''');

    // — Categories table —
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        is_custom INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // — Pre-seed default categories —
    await _seedCategories(db);
  }

  /// Inserts the default category set.
  static Future<void> _seedCategories(Database db) async {
    const defaults = [
      {'id': 'food', 'name': 'Food', 'icon': 'food', 'is_custom': 0},
      {
        'id': 'transport',
        'name': 'Transport',
        'icon': 'transport',
        'is_custom': 0,
      },
      {'id': 'bills', 'name': 'Bills', 'icon': 'bills', 'is_custom': 0},
      {
        'id': 'shopping',
        'name': 'Shopping',
        'icon': 'shopping',
        'is_custom': 0,
      },
      {
        'id': 'entertainment',
        'name': 'Entertainment',
        'icon': 'entertainment',
        'is_custom': 0,
      },
      {'id': 'health', 'name': 'Health', 'icon': 'health', 'is_custom': 0},
      {
        'id': 'education',
        'name': 'Education',
        'icon': 'education',
        'is_custom': 0,
      },
      {'id': 'other', 'name': 'Other', 'icon': 'other', 'is_custom': 0},
      {
        'id': 'settlement',
        'name': 'Settlement',
        'icon': 'settlement',
        'is_custom': 0,
      },
    ];

    final batch = db.batch();
    for (final category in defaults) {
      batch.insert('categories', category);
    }
    await batch.commit(noResult: true);
  }

  /// Closes the database (for testing or cleanup).
  static Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
