import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    var dbPath = await getDatabasesPath();
    var path = join(dbPath, "products.db");

    var exists = await databaseExists(path);

    if (!exists) {
      print("Copying database from assets...");
      try {
        await Directory(dirname(path)).create(recursive: true);
        ByteData data = await rootBundle.load(
          url.join("assets", "database", "products.db"),
        );
        List<int> bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );
        await File(path).writeAsBytes(bytes, flush: true);
        print("Database copied successfully!");
      } catch (e) {
        print("Error copying database: $e");
      }
    } else {
      print("Database already exists at: $path");
    }

    return await openDatabase(path, readOnly: true);
  }

  Future<Map<String, dynamic>?> getProduct(String barcode) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'barcode = ?',
      whereArgs: [barcode],
    );

    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getAlternatives(
    String categoryString,
  ) async {
    final db = await database;

    if (categoryString.isEmpty) return [];

    // 1. Split the string by commas to get the hierarchy
    List<String> tags = categoryString.split(',');

    if (tags.isEmpty) return [];

    // 2. Grab the LAST tag
    String mostSpecificTag = tags.last.trim();

    print(
      "Searching for alternatives with specific tag: '$mostSpecificTag'",
    );

    // 3. Query the DB for products that share this EXACT specific tag
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'categories LIKE ?',
      whereArgs: ['%$mostSpecificTag%'],
      limit: 50,
    );

    return maps;
  }
}
