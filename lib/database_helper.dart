
import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  DatabaseHelper._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'leave_applications.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute(
        '''
      CREATE TABLE leave_application(
        id INTEGER PRIMARY KEY,
        leaveType TEXT,
        startDate TEXT,
        endDate TEXT,
        dayType TEXT,
        reason TEXT,
        remarks TEXT
      )
      '''
    );
  }

  Future<int> insertLeaveApplication(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert('leave_application', row);
  }

  Future<List<Map<String, dynamic>>> queryAllLeaveApplications() async {
    Database db = await instance.database;
    return await db.query('leave_application');
  }

  Future<int> updateLeaveApplication(Map<String, dynamic> row) async {
    Database db = await instance.database;
    int id = row['id'];
    return await db.update(
      'leave_application',
      row,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteLeaveApplication(int id) async {
    Database db = await instance.database;
    return await db.delete(
      'leave_application',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
