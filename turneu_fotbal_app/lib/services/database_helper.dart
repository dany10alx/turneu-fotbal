import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Gestionează baza de date SQLite locală a aplicației. Toate datele
/// turneului (echipe, meciuri, fază eliminatorie) trăiesc doar pe acest
/// dispozitiv — nu există niciun server sau sincronizare între instalări.
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'turneu_fotbal.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE teams (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            group_name TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE matches (
            id TEXT PRIMARY KEY,
            home_team_id TEXT NOT NULL,
            away_team_id TEXT NOT NULL,
            home_score INTEGER NOT NULL DEFAULT 0,
            away_score INTEGER NOT NULL DEFAULT 0,
            status TEXT NOT NULL DEFAULT 'scheduled',
            group_name TEXT,
            round TEXT,
            bracket_slot INTEGER
          )
        ''');
      },
    );
  }
}
