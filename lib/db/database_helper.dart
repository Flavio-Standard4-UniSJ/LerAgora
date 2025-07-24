import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/book.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future _initDB() async {
    final path = join(await getDatabasesPath(), 'books.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE books (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            file_path TEXT,
            username TEXT
          )
        ''');
        await db.execute('''
        CREATE TABLE users(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          username TEXT,
          passwordHash TEXT
        )
      ''');
      },
    );
  }

  Future<int> insertUser(String username, String password) async {
    final dbClient = await db;
    final passwordHash = sha256.convert(utf8.encode(password)).toString();
    return await dbClient.insert('users', {
      'username': username,
      'passwordHash': passwordHash,
    });
  }

  Future<bool> loginUser(String username, String password) async {
    final dbClient = await db;
    final passwordHash = sha256.convert(utf8.encode(password)).toString();
    final result = await dbClient.query(
      'users',
      where: 'username = ? AND passwordHash = ?',
      whereArgs: [username, passwordHash],
    );
    return result.isNotEmpty;
  }

  Future<void> insertBook(Book book) async {
    final dbClient = await db;
    await dbClient.insert('books', book.toMap());
  }

  Future<List<Book>> getBooks({required String username}) async {
    final dbClient = await db;
    final maps = await dbClient.query(
      'books',
      where: 'username = ?',
      whereArgs: [username],
    );

    return List.generate(maps.length, (i) => Book.fromMap(maps[i]));
  }

  Future<void> deleteBook(int id) async {
    final dbClient = await db;
    await dbClient.delete('books', where: 'id = ?', whereArgs: [id]);
  }
}
