import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class SQFLiteHelper {
  static final _databaseName = "vent_expense_pro_finansial.db";
  static final _databaseVersion = 1;

  // Table names
  static final categoryTable = 'categories';
  static final transactionTable = 'transactions';
  static final walletTable = 'wallets';
  static final iconTable = 'icons';

  SQFLiteHelper._privateConstructor();
  static final SQFLiteHelper instance = SQFLiteHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $iconTable (
        icon_id INTEGER PRIMARY KEY AUTOINCREMENT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        icon_code INTEGER NOT NULL,
        icon_color TEXT NOT NULL
      )
    ''');

    // Category table
    await db.execute('''
      CREATE TABLE $categoryTable (
        ctg_id INTEGER PRIMARY KEY AUTOINCREMENT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        ctg_name TEXT NOT NULL,
        ctg_icon TEXT NOT NULL,
        ctg_transaction TEXT NOT NULL,
        FOREIGN KEY (ctg_icon) REFERENCES $iconTable (icon_id)
      )
    ''');

    // Wallet table
    await db.execute('''
      CREATE TABLE $walletTable (
        wlt_id INTEGER PRIMARY KEY AUTOINCREMENT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        wlt_name TEXT NOT NULL,
        wlt_icon TEXT,
        wlt_balance REAL NOT NULL,
        FOREIGN KEY (wlt_icon) REFERENCES $iconTable (icon_id)
      )
    ''');

    // Transaction table (renamed from 'transaction')
    await db.execute('''
      CREATE TABLE $transactionTable (
        trx_id INTEGER PRIMARY KEY AUTOINCREMENT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        trx_source INTEGER NOT NULL,
        trx_amount REAL NOT NULL,
        trx_title TEXT,
        trx_description TEXT,
        trx_type TEXT NOT NULL,
        trx_target INTEGER NOT NULL,
        FOREIGN KEY (trx_source) REFERENCES $walletTable (wlt_id),
        FOREIGN KEY (trx_target) REFERENCES $walletTable (wlt_id)
      )
    ''');
  }

  Future close() async {
    final db = await database;
    db.close();
  }
}
