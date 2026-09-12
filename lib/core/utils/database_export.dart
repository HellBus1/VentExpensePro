import 'dart:convert';

import '../../data/datasources/local_database.dart';
import '../../domain/entities/sync_exception.dart';

/// Utility for exporting / importing the entire local database
/// as a JSON-serializable map.
///
/// Backup format (v2):
/// ```json
/// {
///   "version": 2,
///   "exportedAt": "2026-09-12T10:00:00.000",
///   "accounts": [ ... ],
///   "transactions": [ ... ],
///   "categories": [ ... ]
/// }
/// ```
class DatabaseExport {
  /// The current export schema version.
  static const int _version = 2;

  /// Exports all rows from accounts, transactions, and categories
  /// into a single JSON-encodable map.
  static Future<Map<String, dynamic>> exportAll() async {
    final db = await LocalDatabase.database;

    final accounts = await db.query('accounts');
    final transactions = await db.query('transactions');
    final categories = await db.query('categories');

    return {
      'version': _version,
      'exportedAt': DateTime.now().toIso8601String(),
      'accounts': accounts,
      'transactions': transactions,
      'categories': categories,
    };
  }

  /// Exports all data as a JSON string ready for upload.
  static Future<String> exportAsJson() async {
    final data = await exportAll();
    return jsonEncode(data);
  }

  /// Replaces **all** local data with the contents of [data].
  ///
  /// Handles both v1 and v2 backup formats:
  /// - v1: accounts may lack `statement_close_day` — SQLite defaults to null.
  /// - v2: all fields present.
  ///
  /// Wraps the entire operation in a database transaction
  /// for atomicity — if anything fails, no changes are committed.
  static Future<void> importAll(Map<String, dynamic> data) async {
    final version = data['version'] as int? ?? 1;

    // Guard against future versions this app can't handle
    if (version > _version) {
      throw SyncException(
        SyncErrorType.restoreFailed,
        'Backup format v$version is not supported by this app version. '
            'Please update the app.',
      );
    }

    final db = await LocalDatabase.database;

    await db.transaction((txn) async {
      // 1. Clear existing data (order matters for FK constraints).
      await txn.delete('transactions');
      await txn.delete('accounts');
      await txn.delete('categories');

      // 2. Re-insert categories.
      final categories = data['categories'] as List<dynamic>? ?? [];
      for (final row in categories) {
        await txn.insert('categories', Map<String, dynamic>.from(row as Map));
      }

      // 3. Re-insert accounts.
      // v1 backups won't have statement_close_day — that's fine,
      // SQLite will default the missing column to null.
      final accounts = data['accounts'] as List<dynamic>? ?? [];
      for (final row in accounts) {
        await txn.insert('accounts', Map<String, dynamic>.from(row as Map));
      }

      // 4. Re-insert transactions.
      final transactions = data['transactions'] as List<dynamic>? ?? [];
      for (final row in transactions) {
        await txn.insert(
            'transactions', Map<String, dynamic>.from(row as Map));
      }
    });
  }

  /// Convenience: decode a JSON string and import.
  static Future<void> importFromJson(String jsonString) async {
    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    await importAll(data);
  }
}

