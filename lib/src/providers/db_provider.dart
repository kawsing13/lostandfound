import 'dart:io';
import 'package:lostandfound/src/models/files.dart';
import 'package:lostandfound/src/models/endpoints.dart';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';


class DBProvider {
  static Database? _database;
  static final DBProvider db = DBProvider._();

  DBProvider._();

  Future<Database?> get database async {
    // If database exists, return database
    if (_database != null) return _database;

    // If database don't exists, create one
    _database = await initDB();

    return _database;
  }

  // Create the database and the Item table
  initDB() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'lostandfound.db');
    //final path = "item_manager.db";

    //print(path);
    //deleteDatabase(path);
    return await openDatabase(path, version: 2, onOpen: (db) {},
        onCreate: (Database db, int version) async {
          await db.execute('CREATE TABLE Endpoints('
              'id INTEGER,'
              'name TEXT,'
              'url TEXT,'
              'endpoint TEXT,'
              'PRIMARY KEY(id)'
              ')');

          await db.execute('CREATE TABLE Files('
              'id INT,'
              'endpoint INT,'
              'name TEXT,'
              'type TEXT,'
              'PRIMARY KEY(id, endpoint)'
              ')');
        },
        onUpgrade: (Database db, int oldVersion, int newVersion) async {
          try {

          } catch (e) {
            print(e);
          }
        }
    );
  }


  Future<List<Endpoints>> getAllEndpoints() async {
    final db = await database;
    final res = await db!.rawQuery(
        "SELECT * FROM Endpoints where id>0   ORDER  BY name desc");

    List<Endpoints> list =
    res.isNotEmpty ? res.map((c) => Endpoints.fromJson(c)).toList() : [];

    return list;
  }

  Future<List<Endpoints>> getEndpoint(int id) async {
    final db = await database;
    final res = await db!.rawQuery("SELECT * FROM Endpoints where id=$id");

    List<Endpoints> list =
    res.isNotEmpty ? res.map((c) => Endpoints.fromJson(c)).toList() : [];

    return list;
  }

  getEndpointId() async {
    int id = 0;
    final db = await database;
    final res = await db!.rawQuery("SELECT max(id) as id FROM Endpoints");

    try {
      if (res.isNotEmpty) {
        res.forEach((f) {
          id = int.parse(f["id"].toString());
        });
      }
      return (id==0?-1:id);
    } catch (e) {
      return -1;
    }
  }


  void deleteEndpoint(int id) async {
    final db = await database;
    final res = await db!.rawQuery("Delete from Endpoints  where id=$id");
  }

  saveEndpoint(Endpoints newEndpoint) async {
    final db = await database;
    try {
      final res = await db!.insert('Endpoints', newEndpoint.toJson());
      return res;
    } catch(e) {
      return null;
    }
  }

  updateEndpoint(Endpoints newEndpoint) async {
    //await deleteItem(newItem.id,newItem.unit);
    final db = await database;
    final res = await db?.update('Endpoints', newEndpoint.toJson(), where: 'id = ?', whereArgs: [ newEndpoint.id ]  );
    return res;
  }


  Future<List<Files>> getAllFiles(int id) async {
    final db = await database;
    final res = await db!.rawQuery(
        "SELECT * FROM Files where endpoint=$id   ORDER  BY name desc");

    List<Files> list =
    res.isNotEmpty ? res.map((c) => Files.fromJson(c)).toList() : [];

    return list;
  }

  Future<List<Files>> getAllDistinctFiles(int id) async {
    final db = await database;
    final res = await db!.rawQuery(
        "SELECT * FROM Files where endpoint=$id  GROUP BY type ORDER  BY name desc");

    List<Files> list =
    res.isNotEmpty ? res.map((c) => Files.fromJson(c)).toList() : [];

    return list;
  }

  Future<List<Files>> getFile(int id) async {
    final db = await database;
    final res = await db!.rawQuery("SELECT * FROM Files where id=$id");

    List<Files> list =
    res.isNotEmpty ? res.map((c) => Files.fromJson(c)).toList() : [];

    return list;
  }

  getFilesId(int id) async {
    int id = 0;
    final db = await database;
    final res = await db!.rawQuery("SELECT max(id) as id FROM Files");

    try {
      if (res.isNotEmpty) {
        res.forEach((f) {
          id = int.parse(f["id"].toString());
        });
      }
      return (id==0?-1:id);
    } catch (e) {
      return -1;
    }
  }

  saveFile(Files newFile) async {
    final db = await database;
    try {
      final res = await db!.insert('Files', newFile.toJson());
      return res;
    } catch(e) {
      return null;
    }
  }

  updateFile(Files newFile) async {
    //await deleteItem(newItem.id,newItem.unit);
    final db = await database;
    final res = await db?.update('Files', newFile.toJson(), where: 'id = ?', whereArgs: [ newFile.id ]  );
    return res;
  }


  
}

