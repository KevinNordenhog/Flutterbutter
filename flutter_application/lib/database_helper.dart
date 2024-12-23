import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Future<Database> initializeDatabase() async {
    String path = join(await getDatabasesPath(), 'people_database.db');
    return openDatabase(
      path,
      version: 3,
      onCreate: (Database db, int version) async {
        await db.execute(
          "CREATE TABLE groups(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, parentId INTEGER)",
        );
        await db.execute(
          "CREATE TABLE people(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, groupIds TEXT)",
        );
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 2) {
          await db.execute("ALTER TABLE people ADD COLUMN groupIds TEXT");
        }
        if (oldVersion < 3) {
          try {
            await db.execute("ALTER TABLE groups ADD COLUMN parentId INTEGER");
          } catch (e) {
            // Column might already exist, ignore the error
          }
        }
      },
    );
  }
}
