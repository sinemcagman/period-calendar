import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('period_tracker.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onConfigure: _onConfigure,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _onConfigure(Database db) async {
    await db.execute("PRAGMA foreign_keys = ON;");
    await db.execute("PRAGMA encoding = 'UTF-8';");
  }

  Future _createDB(Database db, int version) async {
    // Users Table
    await db.execute('''
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      dark_mode INTEGER NOT NULL
    )
    ''');

    // Cycles Table
    await db.execute('''
    CREATE TABLE cycles (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      start_date TEXT NOT NULL,
      end_date TEXT
    )
    ''');

    // DailyLogs Table
    await db.execute('''
    CREATE TABLE daily_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      date TEXT NOT NULL UNIQUE,
      mood_type TEXT NOT NULL,
      physical_symptoms TEXT NOT NULL,
      notes TEXT NOT NULL
    )
    ''');

    // WaterIntake Table
    await db.execute('''
    CREATE TABLE water_intake (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      date TEXT NOT NULL UNIQUE,
      amount INTEGER NOT NULL
    )
    ''');

    // Inventory Table
    await db.execute('''
    CREATE TABLE inventory (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      item_type TEXT NOT NULL UNIQUE,
      current_stock INTEGER NOT NULL
    )
    ''');
    
    // Seed initial inventory
    await db.insert('inventory', {'item_type': 'ped', 'current_stock': 10});
    await db.insert('inventory', {'item_type': 'tampon', 'current_stock': 10});

    // Reminders Table
    await db.execute('''
    CREATE TABLE reminders (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      text TEXT NOT NULL,
      trigger_time TEXT NOT NULL,
      is_active INTEGER NOT NULL DEFAULT 1,
      recurrence_type TEXT NOT NULL DEFAULT 'none'
    )
    ''');

    // BlogPosts Table
    await db.execute('''
    CREATE TABLE blog_posts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      category TEXT NOT NULL,
      read_time INTEGER NOT NULL,
      image_url TEXT NOT NULL,
      content TEXT NOT NULL
    )
    ''');
    
    await _seedBlogPosts(db);
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE reminders ADD COLUMN is_recurring INTEGER NOT NULL DEFAULT 0;");
    }
    if (oldVersion < 3) {
      // SQLite doesn't easily let you drop columns, so we add the new one.
      // We'll migrate the data from is_recurring to recurrence_type.
      await db.execute("ALTER TABLE reminders ADD COLUMN recurrence_type TEXT NOT NULL DEFAULT 'none';");
      await db.execute("UPDATE reminders SET recurrence_type = 'daily' WHERE is_recurring = 1;");
    }
  }
  
  Future _seedBlogPosts(Database db) async {
    final posts = [
      {
        'title': 'Kramplara ne iyi gelir?',
        'category': 'AĞRI YÖNETİMİ',
        'read_time': 3,
        'image_url': 'https://plus.unsplash.com/premium_photo-1661778949004-bb50c26da234',
        'content': 'Sıcak su torbası uygulamak ve papatya çayı içmek kramplarınızı hafifletebilir.'
      },
      {
        'title': 'Regl döneminde beslenme',
        'category': 'BESLENME',
        'read_time': 5,
        'image_url': 'https://images.unsplash.com/photo-1490645935967-10de6ba17061',
        'content': 'Demir açısından zengin besinler tüketmek bu dönemde yaşanan halsizliği ve enerji düşüşünü engelleyebilir.'
      },
      {
        'title': 'Egzersiz ve Regl',
        'category': 'HAREKET',
        'read_time': 4,
        'image_url': 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b',
        'content': 'Hafif tempolu yürüyüşler ve yoga pelvik bölgedeki kan akışını hızlandırarak ağrıları dindirebilir.'
      },
      {
        'title': 'Mod Değişimleri',
        'category': 'PSİKOLOJİ',
        'read_time': 6,
        'image_url': 'https://images.unsplash.com/photo-1515023115689-589c33041d3c',
        'content': 'PMS (Adet Öncesi Sendrom) semptomlarını hafifletmek için magnezyum takviyesi ve meditasyon önerilir.'
      },
      {
        'title': 'Uyku Kalitesi',
        'category': 'UYKU',
        'read_time': 3,
        'image_url': 'https://images.unsplash.com/photo-1541781774459-bb2af2f05b55',
        'content': 'Serin bir oda ve karanlık ortam, regl sırasında sık bölünen uykuya yardımcı olur.'
      }
    ];

    for (var post in posts) {
      await db.insert('blog_posts', post);
    }
  }
  
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
