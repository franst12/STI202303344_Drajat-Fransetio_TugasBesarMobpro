import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/destination_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('travel_wisata.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const realType = 'REAL NOT NULL';

    await db.execute('''
      CREATE TABLE destinations ( 
        id $idType, 
        name $textType,
        description $textType,
        address $textType,
        openTime $textType,
        closeTime $textType, 
        imagePath $textType,
        latitude $realType,
        longitude $realType
      )
    ''');
  }

  Future<int> create(Destination destination) async {
    final db = await instance.database;
    return await db.insert('destinations', destination.toMap());
  }

  Future<List<Destination>> readAllDestinations() async {
    final db = await instance.database;
    final result = await db.query('destinations', orderBy: 'id DESC');
    return result.map((json) => Destination.fromMap(json)).toList();
  }

  Future<Destination> readDestination(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'destinations',
      columns: null,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Destination.fromMap(maps.first);
    } else {
      throw Exception('ID $id not found');
    }
  }

  Future<int> update(Destination destination) async {
    final db = await instance.database;
    return db.update(
      'destinations',
      destination.toMap(),
      where: 'id = ?',
      whereArgs: [destination.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await instance.database;
    return await db.delete(
      'destinations',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Destination>> searchDestinations(String keyword) async {
    final db = await instance.database;
    final result = await db.query(
      'destinations',
      where: 'name LIKE ? OR address LIKE ?',
      whereArgs: ['%$keyword%', '%$keyword%'],
      orderBy: 'id DESC',
    );
    return result.map((json) => Destination.fromMap(json)).toList();
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
