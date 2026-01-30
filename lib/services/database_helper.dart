import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "products.db");

    File dbFile = File(path);

    // --- 🚀 SMART COPY LOGIC ---
    // Only skip copy if file exists AND is bigger than 5MB (meaning it's real data)
    if (await dbFile.exists() && await dbFile.length() > 5 * 1024 * 1024) {
      print("✅ Valid Database found (${await dbFile.length()} bytes). Skipping copy.");
    } else {
      print("⚠️ Database missing or too small. Copying from assets...");
      print("⏳ This might take 10-20 seconds...");
      
      try {
        ByteData data = await rootBundle.load(join("assets", "database", "products.db"));
        List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await dbFile.writeAsBytes(bytes, flush: true);
        print("✅ Database copied successfully!");
      } catch (e) {
        throw Exception("Error copying database: $e");
      }
    }

    return await openDatabase(path, version: 1);
  }

  Future<Map<String, dynamic>?> getProduct(String barcode) async {
    final db = await database;

    // Simple, fast query. The 'barcode' column is a Primary Key,
    // so this lookup happens in milliseconds (O(1) speed).
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'barcode = ?',
      whereArgs: [barcode],
    );

    if (maps.isNotEmpty) return maps.first;
    return null;
  }
}
