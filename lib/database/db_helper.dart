import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_model.dart';
import '../models/schedule_model.dart';
import '../models/note_model.dart';
import '../models/habit_model.dart';
import '../models/target_model.dart';
import '../models/study_session_model.dart';
import '../models/reminder_model.dart';
import '../models/pomodoro_model.dart';
import '../models/deck_model.dart';
import '../models/flashcard_model.dart';

class DbHelper {
  static Database? _database;
  static const String dbName = 'studysync.db';
  static const int dbVersion = 2;
  // bumped to 3 to add scheduleId in tasks
  static const int _targetDbVersion = 3;

  static Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError(
        'Database is not supported on web. Use SharedPreferences fallback instead.',
      );
    }
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final pathString = join(dbPath, dbName);

    return await openDatabase(
      pathString,
      version: _targetDbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE study_sessions ADD COLUMN taskId INTEGER');
    }
    if (oldVersion < 3) {
      // Add optional schedule link on tasks
      await db.execute('ALTER TABLE tasks ADD COLUMN scheduleId INTEGER');
    }
  }

  static Future<void> _onCreate(Database db, int version) async {
    // Tasks table
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        dueDate TEXT NOT NULL,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        priority TEXT NOT NULL,
        category TEXT NOT NULL,
        scheduleId INTEGER
      )
    ''');

    // Schedules table
    await db.execute('''
      CREATE TABLE schedules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        location TEXT,
        date TEXT NOT NULL,
        startTime TEXT NOT NULL,
        endTime TEXT NOT NULL,
        color INTEGER NOT NULL,
        lecturer TEXT
      )
    ''');

    // Notes table
    await db.execute('''
      CREATE TABLE notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT,
        createdAt TEXT NOT NULL,
        color INTEGER NOT NULL,
        isPinned INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Habits table
    await db.execute('''
      CREATE TABLE habits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        frequency TEXT NOT NULL,
        streak INTEGER NOT NULL DEFAULT 0,
        lastCompleted TEXT
      )
    ''');

    // Targets table
    await db.execute('''
      CREATE TABLE targets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        courseName TEXT NOT NULL,
        targetGrade TEXT NOT NULL,
        targetScore REAL NOT NULL,
        currentScore REAL NOT NULL,
        notes TEXT
      )
    ''');

    // Study Sessions table
    await db.execute('''
      CREATE TABLE study_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        taskId INTEGER,
        subject TEXT NOT NULL,
        date TEXT NOT NULL,
        durationSeconds INTEGER NOT NULL,
        notes TEXT
      )
    ''');

    // Reminders table
    await db.execute('''
      CREATE TABLE reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        dateTime TEXT NOT NULL,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        repeatType TEXT NOT NULL
      )
    ''');

    // Pomodoro History table
    await db.execute('''
      CREATE TABLE pomodoro_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        durationMinutes INTEGER NOT NULL,
        dateTime TEXT NOT NULL,
        category TEXT NOT NULL
      )
    ''');

    // Flashcard Decks table
    await db.execute('''
      CREATE TABLE flashcard_decks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        color INTEGER NOT NULL
      )
    ''');

    // Flashcards table
    await db.execute('''
      CREATE TABLE flashcards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        deckId INTEGER NOT NULL,
        question TEXT NOT NULL,
        answer TEXT NOT NULL,
        isLearned INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  // --- WEB FALLBACK PERSISTENCE HELPERS ---
  static Future<List<Map<String, dynamic>>> _getWebData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonStr = prefs.getString(key);
    if (jsonStr == null) return [];
    try {
      final List<dynamic> decoded = json.decode(jsonStr);
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _saveWebData(
    String key,
    List<Map<String, dynamic>> data,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, json.encode(data));
  }

  // --- SEED SAMPLE DATA METHOD ---
  static Future<void> seedSampleData() async {
    final existingTasks = await getAllTasks();
    if (existingTasks.isNotEmpty) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));

    // Seed Tasks
    await insertTask(
      TaskModel(
        title: 'Tugas Pemrograman Mobile',
        description: 'Membuat rancangan UI aplikasi Flutter dengan Material 3.',
        dueDate: today.add(const Duration(days: 2)),
        isCompleted: false,
        priority: 'High',
        category: 'Tugas',
      ),
    );
    await insertTask(
      TaskModel(
        title: 'Projek Akhir Basis Data',
        description:
            'Normalisasi database dan merancang skema ERD untuk sistem informasi kampus.',
        dueDate: today.add(const Duration(days: 5)),
        isCompleted: false,
        priority: 'High',
        category: 'Projek',
      ),
    );
    await insertTask(
      TaskModel(
        title: 'Kuis Statistika',
        description: 'Materi distribusi probabilitas binomial dan normal.',
        dueDate: today.add(const Duration(days: 1)),
        isCompleted: false,
        priority: 'Medium',
        category: 'Ujian',
      ),
    );
    await insertTask(
      TaskModel(
        title: 'Review Jurnal AI',
        description:
            'Membaca dan merangkum jurnal kecerdasan buatan tentang transformer models.',
        dueDate: today.subtract(const Duration(days: 1)),
        isCompleted: true,
        priority: 'Low',
        category: 'Tugas',
      ),
    );
    await insertTask(
      TaskModel(
        title: 'Laporan Praktikum Jaringan',
        description:
            'Konfigurasi subnetting dan routing statis di Cisco Packet Tracer.',
        dueDate: today.subtract(const Duration(days: 3)),
        isCompleted: true,
        priority: 'Medium',
        category: 'Tugas',
      ),
    );

    // Seed Schedules
    await insertSchedule(
      ScheduleModel(
        title: 'Pemrograman Mobile',
        location: 'Lab Komputer 3',
        date: monday,
        startTime: '08:00',
        endTime: '10:30',
        color: 0xFF6366F1, // Indigo
        lecturer: 'Dr. Eng. Farid',
      ),
    );
    await insertSchedule(
      ScheduleModel(
        title: 'Jaringan Komputer',
        location: 'Ruang Kuliah 302',
        date: monday.add(const Duration(days: 1)),
        startTime: '10:45',
        endTime: '13:15',
        color: 0xFF10B981, // Emerald
        lecturer: 'Ahmad Dahlan, M.T.',
      ),
    );
    await insertSchedule(
      ScheduleModel(
        title: 'Basis Data Lanjut',
        location: 'Ruang Kuliah 204',
        date: monday.add(const Duration(days: 2)),
        startTime: '13:30',
        endTime: '16:00',
        color: 0xFFF59E0B, // Amber
        lecturer: 'Siti Aminah, M.Kom.',
      ),
    );
    await insertSchedule(
      ScheduleModel(
        title: 'Kecerdasan Buatan',
        location: 'Ruang Kuliah 301',
        date: monday.add(const Duration(days: 3)),
        startTime: '08:00',
        endTime: '10:30',
        color: 0xFFEC4899, // Pink
        lecturer: 'Prof. Hermawan',
      ),
    );

    // Seed Notes
    await insertNote(
      NoteModel(
        title: 'Rumus Kalkulus II',
        content:
            '1. Integral Lipat Dua: digunakan untuk menghitung volume di bawah permukaan z = f(x,y).\n2. Teorema Green: menghubungkan integral garis di sepanjang kurva tertutup C dengan integral lipat dua di atas daerah R.',
        createdAt: today,
        color: 0xFFFFEDD5, // Pastel Amber
        isPinned: true,
      ),
    );
    await insertNote(
      NoteModel(
        title: 'Ide Judul PKM 2026',
        content:
            '1. Sistem IoT Smart Agriculture berbasis nodemcu untuk optimalisasi penyiraman tanaman.\n2. Aplikasi StudySync untuk meningkatkan efektivitas belajar kelompok mahasiswa.',
        createdAt: today.subtract(const Duration(days: 1)),
        color: 0xFFE0F2FE, // Pastel Blue
        isPinned: true,
      ),
    );
    await insertNote(
      NoteModel(
        title: 'Daftar Referensi Buku Flutter',
        content:
            '1. Flutter in Action oleh Eric Windmill.\n2. Cookbooks Flutter resmi di flutter.dev.\n3. Kursus praktis di YouTube Flutter Indonesia.',
        createdAt: today.subtract(const Duration(days: 3)),
        color: 0xFFF3E8FF, // Pastel Purple
        isPinned: false,
      ),
    );

    // Seed Targets
    await insertTarget(
      TargetModel(
        courseName: 'Pemrograman Mobile',
        targetGrade: 'A',
        targetScore: 90.0,
        currentScore: 87.0,
        notes: 'Pertahankan nilai praktikum mingguan dan kuis.',
      ),
    );
    await insertTarget(
      TargetModel(
        courseName: 'Kecerdasan Buatan',
        targetGrade: 'A',
        targetScore: 88.0,
        currentScore: 82.0,
        notes: 'Belajar lebih keras untuk UTS materi Neural Networks.',
      ),
    );
    await insertTarget(
      TargetModel(
        courseName: 'Jaringan Komputer',
        targetGrade: 'B',
        targetScore: 80.0,
        currentScore: 78.0,
        notes: 'Latihan routing statis dan dinamis secara rutin.',
      ),
    );

    // Seed Study Sessions
    await insertStudySession(
      StudySessionModel(
        subject: 'Pemrograman Mobile',
        date: today.subtract(const Duration(days: 2)),
        durationSeconds: 2700, // 45 min
        notes:
            'Mempelajari State Management Flutter (ValueNotifier & Provider).',
      ),
    );
    await insertStudySession(
      StudySessionModel(
        subject: 'Kecerdasan Buatan',
        date: today.subtract(const Duration(days: 1)),
        durationSeconds: 3600, // 60 min
        notes: 'Mempelajari cara kerja algoritma A* Search.',
      ),
    );
    await insertStudySession(
      StudySessionModel(
        subject: 'Basis Data Lanjut',
        date: today,
        durationSeconds: 1800, // 30 min
        notes: 'Latihan membuat query JOIN yang kompleks.',
      ),
    );

    // Seed Reminders
    await insertReminder(
      ReminderModel(
        title: 'Kuis Statistika Besok Pagi',
        dateTime: today.add(const Duration(days: 1, hours: 7)),
        repeatType: 'None',
        isCompleted: false,
      ),
    );
    await insertReminder(
      ReminderModel(
        title: 'Kumpul Tugas Jaringan',
        dateTime: today.add(const Duration(hours: 23, minutes: 59)),
        repeatType: 'None',
        isCompleted: false,
      ),
    );

    // Seed Pomodoro History
    await insertPomodoroHistory(
      PomodoroModel(
        durationMinutes: 25,
        dateTime: today.subtract(const Duration(days: 1)),
        category: 'Belajar',
      ),
    );
    await insertPomodoroHistory(
      PomodoroModel(durationMinutes: 25, dateTime: today, category: 'Tugas'),
    );

    // Seed Flashcards Decks
    final deck1Id = await insertDeck(
      DeckModel(
        title: 'Pemrograman Mobile',
        description:
            'Materi dasar Flutter, State Management, Widget, dan Lifecycle.',
        color: 0xFF6366F1, // Indigo
      ),
    );
    final deck2Id = await insertDeck(
      DeckModel(
        title: 'Kecerdasan Buatan (AI)',
        description:
            'Pengenalan Machine Learning, Neural Networks, dan Search Algorithms.',
        color: 0xFFEC4899, // Pink
      ),
    );

    // Seed Flashcards inside Deck 1
    await insertFlashcard(
      FlashcardModel(
        deckId: deck1Id,
        question: 'Apa itu Flutter?',
        answer:
            'Framework UI open-source buatan Google untuk membangun aplikasi multiplatform berkualitas tinggi dari satu codebase tunggal.',
        isLearned: true,
      ),
    );
    await insertFlashcard(
      FlashcardModel(
        deckId: deck1Id,
        question: 'Apa perbedaan utama StatelessWidget dan StatefulWidget?',
        answer:
            'StatelessWidget bersifat statis dan tidak dapat diubah setelah dirender, sedangkan StatefulWidget dapat menyimpan data dinamis (state) dan merender ulang dirinya sendiri saat state berubah.',
        isLearned: false,
      ),
    );
    await insertFlashcard(
      FlashcardModel(
        deckId: deck1Id,
        question: 'Sebutkan 3 jenis State Management yang populer di Flutter!',
        answer:
            '1. Provider (sangat ramah pemula)\n2. BLoC (cocok untuk skala enterprise)\n3. Riverpod (versi modern dari Provider).',
        isLearned: false,
      ),
    );

    // Seed Flashcards inside Deck 2
    await insertFlashcard(
      FlashcardModel(
        deckId: deck2Id,
        question: 'Apa itu Kecerdasan Buatan (AI)?',
        answer:
            'Simulasi kecerdasan manusia yang diprogram ke dalam komputer agar mampu berpikir, belajar, memecahkan masalah, dan mengambil keputusan.',
        isLearned: true,
      ),
    );
    await insertFlashcard(
      FlashcardModel(
        deckId: deck2Id,
        question: 'Jelaskan perbedaan Machine Learning dan Deep Learning!',
        answer:
            'Machine Learning adalah algoritma yang belajar dari data untuk membuat prediksi. Deep Learning adalah subbidang Machine Learning yang terinspirasi oleh otak manusia dengan jaringan saraf tiruan berlapis (Deep Neural Networks).',
        isLearned: false,
      ),
    );
  }

  // --- DATABASE OPERATIONS ---

  // 1. TASKS
  static Future<int> insertTask(TaskModel task) async {
    if (kIsWeb) {
      final data = await _getWebData('web_tasks');
      final newId = DateTime.now().millisecondsSinceEpoch;
      final item = task.copyWith(id: newId);
      data.add(item.toMap());
      await _saveWebData('web_tasks', data);
      return newId;
    }
    final db = await database;
    return await db.insert('tasks', task.toMap());
  }

  static Future<List<TaskModel>> getAllTasks() async {
    if (kIsWeb) {
      final data = await _getWebData('web_tasks');
      final list = data.map((map) => TaskModel.fromMap(map)).toList();
      list.sort((a, b) => a.dueDate.compareTo(b.dueDate));
      return list;
    }
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      orderBy: 'dueDate ASC',
    );
    return List.generate(maps.length, (i) => TaskModel.fromMap(maps[i]));
  }

  static Future<int> updateTask(TaskModel task) async {
    if (kIsWeb) {
      final data = await _getWebData('web_tasks');
      final index = data.indexWhere((map) => map['id'] == task.id);
      if (index != -1) {
        data[index] = task.toMap();
        await _saveWebData('web_tasks', data);
        return 1;
      }
      return 0;
    }
    final db = await database;
    return await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  static Future<int> deleteTask(int id) async {
    if (kIsWeb) {
      final data = await _getWebData('web_tasks');
      final initialLength = data.length;
      data.removeWhere((map) => map['id'] == id);
      if (data.length != initialLength) {
        await _saveWebData('web_tasks', data);
        return 1;
      }
      return 0;
    }
    final db = await database;
    return await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  // 2. SCHEDULES
  static Future<int> insertSchedule(ScheduleModel schedule) async {
    if (kIsWeb) {
      final data = await _getWebData('web_schedules');
      final newId = DateTime.now().millisecondsSinceEpoch;
      final item = schedule.copyWith(id: newId);
      data.add(item.toMap());
      await _saveWebData('web_schedules', data);
      return newId;
    }
    final db = await database;
    return await db.insert('schedules', schedule.toMap());
  }

  static Future<List<ScheduleModel>> getAllSchedules() async {
    if (kIsWeb) {
      final data = await _getWebData('web_schedules');
      final list = data.map((map) => ScheduleModel.fromMap(map)).toList();
      list.sort((a, b) => a.startTime.compareTo(b.startTime));
      return list;
    }
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'schedules',
      orderBy: 'startTime ASC',
    );
    return List.generate(maps.length, (i) => ScheduleModel.fromMap(maps[i]));
  }

  static Future<int> updateSchedule(ScheduleModel schedule) async {
    if (kIsWeb) {
      final data = await _getWebData('web_schedules');
      final index = data.indexWhere((map) => map['id'] == schedule.id);
      if (index != -1) {
        data[index] = schedule.toMap();
        await _saveWebData('web_schedules', data);
        return 1;
      }
      return 0;
    }
    final db = await database;
    return await db.update(
      'schedules',
      schedule.toMap(),
      where: 'id = ?',
      whereArgs: [schedule.id],
    );
  }

  static Future<int> deleteSchedule(int id) async {
    if (kIsWeb) {
      final data = await _getWebData('web_schedules');
      final initialLength = data.length;
      data.removeWhere((map) => map['id'] == id);
      if (data.length != initialLength) {
        await _saveWebData('web_schedules', data);
        return 1;
      }
      return 0;
    }
    final db = await database;
    return await db.delete('schedules', where: 'id = ?', whereArgs: [id]);
  }

  // 3. NOTES
  static Future<int> insertNote(NoteModel note) async {
    if (kIsWeb) {
      final data = await _getWebData('web_notes');
      final newId = DateTime.now().millisecondsSinceEpoch;
      final item = note.copyWith(id: newId);
      data.add(item.toMap());
      await _saveWebData('web_notes', data);
      return newId;
    }
    final db = await database;
    return await db.insert('notes', note.toMap());
  }

  static Future<List<NoteModel>> getAllNotes() async {
    if (kIsWeb) {
      final data = await _getWebData('web_notes');
      final list = data.map((map) => NoteModel.fromMap(map)).toList();
      list.sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return b.createdAt.compareTo(a.createdAt);
      });
      return list;
    }
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
      orderBy: 'isPinned DESC, createdAt DESC',
    );
    return List.generate(maps.length, (i) => NoteModel.fromMap(maps[i]));
  }

  static Future<int> updateNote(NoteModel note) async {
    if (kIsWeb) {
      final data = await _getWebData('web_notes');
      final index = data.indexWhere((map) => map['id'] == note.id);
      if (index != -1) {
        data[index] = note.toMap();
        await _saveWebData('web_notes', data);
        return 1;
      }
      return 0;
    }
    final db = await database;
    return await db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  static Future<int> deleteNote(int id) async {
    if (kIsWeb) {
      final data = await _getWebData('web_notes');
      final initialLength = data.length;
      data.removeWhere((map) => map['id'] == id);
      if (data.length != initialLength) {
        await _saveWebData('web_notes', data);
        return 1;
      }
      return 0;
    }
    final db = await database;
    return await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  // 4. HABITS
  static Future<int> insertHabit(HabitModel habit) async {
    if (kIsWeb) {
      final data = await _getWebData('web_habits');
      final newId = DateTime.now().millisecondsSinceEpoch;
      final item = habit.copyWith(id: newId);
      data.add(item.toMap());
      await _saveWebData('web_habits', data);
      return newId;
    }
    final db = await database;
    return await db.insert('habits', habit.toMap());
  }

  static Future<List<HabitModel>> getAllHabits() async {
    if (kIsWeb) {
      final data = await _getWebData('web_habits');
      return data.map((map) => HabitModel.fromMap(map)).toList();
    }
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('habits');
    return List.generate(maps.length, (i) => HabitModel.fromMap(maps[i]));
  }

  static Future<void> deleteSeedHabits() async {
    const seedHabitNames = [
      'Membaca Buku 15 Menit',
      'Belajar Coding 1 Jam',
      'Minum Air Putih 2L',
    ];

    if (kIsWeb) {
      final data = await _getWebData('web_habits');
      final initialLength = data.length;
      data.removeWhere((map) => seedHabitNames.contains(map['name']));
      if (data.length != initialLength) {
        await _saveWebData('web_habits', data);
      }
      return;
    }

    final db = await database;
    await db.delete(
      'habits',
      where: 'name IN (${List.filled(seedHabitNames.length, '?').join(', ')})',
      whereArgs: seedHabitNames,
    );
  }

  static Future<int> updateHabit(HabitModel habit) async {
    if (kIsWeb) {
      final data = await _getWebData('web_habits');
      final index = data.indexWhere((map) => map['id'] == habit.id);
      if (index != -1) {
        data[index] = habit.toMap();
        await _saveWebData('web_habits', data);
        return 1;
      }
      return 0;
    }
    final db = await database;
    return await db.update(
      'habits',
      habit.toMap(),
      where: 'id = ?',
      whereArgs: [habit.id],
    );
  }

  static Future<int> deleteHabit(int id) async {
    if (kIsWeb) {
      final data = await _getWebData('web_habits');
      final initialLength = data.length;
      data.removeWhere((map) => map['id'] == id);
      if (data.length != initialLength) {
        await _saveWebData('web_habits', data);
        return 1;
      }
      return 0;
    }
    final db = await database;
    return await db.delete('habits', where: 'id = ?', whereArgs: [id]);
  }

  // 5. TARGETS
  static Future<int> insertTarget(TargetModel target) async {
    if (kIsWeb) {
      final data = await _getWebData('web_targets');
      final newId = DateTime.now().millisecondsSinceEpoch;
      final item = target.copyWith(id: newId);
      data.add(item.toMap());
      await _saveWebData('web_targets', data);
      return newId;
    }
    final db = await database;
    return await db.insert('targets', target.toMap());
  }

  static Future<List<TargetModel>> getAllTargets() async {
    if (kIsWeb) {
      final data = await _getWebData('web_targets');
      return data.map((map) => TargetModel.fromMap(map)).toList();
    }
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('targets');
    return List.generate(maps.length, (i) => TargetModel.fromMap(maps[i]));
  }

  static Future<int> updateTarget(TargetModel target) async {
    if (kIsWeb) {
      final data = await _getWebData('web_targets');
      final index = data.indexWhere((map) => map['id'] == target.id);
      if (index != -1) {
        data[index] = target.toMap();
        await _saveWebData('web_targets', data);
        return 1;
      }
      return 0;
    }
    final db = await database;
    return await db.update(
      'targets',
      target.toMap(),
      where: 'id = ?',
      whereArgs: [target.id],
    );
  }

  static Future<int> deleteTarget(int id) async {
    if (kIsWeb) {
      final data = await _getWebData('web_targets');
      final initialLength = data.length;
      data.removeWhere((map) => map['id'] == id);
      if (data.length != initialLength) {
        await _saveWebData('web_targets', data);
        return 1;
      }
      return 0;
    }
    final db = await database;
    return await db.delete('targets', where: 'id = ?', whereArgs: [id]);
  }

  // 6. STUDY SESSIONS
  static Future<int> insertStudySession(StudySessionModel session) async {
    if (kIsWeb) {
      final data = await _getWebData('web_study_sessions');
      final newId = DateTime.now().millisecondsSinceEpoch;
      final item = session.copyWith(id: newId);
      data.add(item.toMap());
      await _saveWebData('web_study_sessions', data);
      return newId;
    }
    final db = await database;
    return await db.insert('study_sessions', session.toMap());
  }

  static Future<List<StudySessionModel>> getAllStudySessions() async {
    if (kIsWeb) {
      final data = await _getWebData('web_study_sessions');
      final list = data.map((map) => StudySessionModel.fromMap(map)).toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    }
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'study_sessions',
      orderBy: 'date DESC',
    );
    return List.generate(
      maps.length,
      (i) => StudySessionModel.fromMap(maps[i]),
    );
  }

  static Future<List<StudySessionModel>> getStudySessionsByTaskId(
    int taskId,
  ) async {
    if (kIsWeb) {
      final data = await _getWebData('web_study_sessions');
      final filtered = data.where((map) => map['taskId'] == taskId).toList();
      final list = filtered
          .map((map) => StudySessionModel.fromMap(map))
          .toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    }
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'study_sessions',
      where: 'taskId = ?',
      whereArgs: [taskId],
      orderBy: 'date DESC',
    );
    return List.generate(
      maps.length,
      (i) => StudySessionModel.fromMap(maps[i]),
    );
  }

  static Future<TaskModel?> getTaskById(int id) async {
    if (kIsWeb) {
      final data = await _getWebData('web_tasks');
      final map = data.firstWhere((m) => m['id'] == id, orElse: () => {});
      if (map.isEmpty) return null;
      return TaskModel.fromMap(map);
    }
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return TaskModel.fromMap(maps.first);
  }

  static Future<ScheduleModel?> getScheduleById(int id) async {
    if (kIsWeb) {
      final data = await _getWebData('web_schedules');
      final map = data.firstWhere((m) => m['id'] == id, orElse: () => {});
      if (map.isEmpty) return null;
      return ScheduleModel.fromMap(map);
    }
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'schedules',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return ScheduleModel.fromMap(maps.first);
  }

  static Future<int> updateStudySession(StudySessionModel session) async {
    if (kIsWeb) {
      final data = await _getWebData('web_study_sessions');
      final index = data.indexWhere((map) => map['id'] == session.id);
      if (index != -1) {
        data[index] = session.toMap();
        await _saveWebData('web_study_sessions', data);
        return 1;
      }
      return 0;
    }
    final db = await database;
    return await db.update(
      'study_sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  static Future<int> deleteStudySession(int id) async {
    if (kIsWeb) {
      final data = await _getWebData('web_study_sessions');
      final initialLength = data.length;
      data.removeWhere((map) => map['id'] == id);
      if (data.length != initialLength) {
        await _saveWebData('web_study_sessions', data);
        return 1;
      }
      return 0;
    }
    final db = await database;
    return await db.delete('study_sessions', where: 'id = ?', whereArgs: [id]);
  }

  // 7. REMINDERS
  static Future<int> insertReminder(ReminderModel reminder) async {
    if (kIsWeb) {
      final data = await _getWebData('web_reminders');
      final newId = DateTime.now().millisecondsSinceEpoch;
      final item = reminder.copyWith(id: newId);
      data.add(item.toMap());
      await _saveWebData('web_reminders', data);
      return newId;
    }
    final db = await database;
    return await db.insert('reminders', reminder.toMap());
  }

  static Future<List<ReminderModel>> getAllReminders() async {
    if (kIsWeb) {
      final data = await _getWebData('web_reminders');
      final list = data.map((map) => ReminderModel.fromMap(map)).toList();
      list.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      return list;
    }
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'reminders',
      orderBy: 'dateTime ASC',
    );
    return List.generate(maps.length, (i) => ReminderModel.fromMap(maps[i]));
  }

  static Future<int> updateReminder(ReminderModel reminder) async {
    if (kIsWeb) {
      final data = await _getWebData('web_reminders');
      final index = data.indexWhere((map) => map['id'] == reminder.id);
      if (index != -1) {
        data[index] = reminder.toMap();
        await _saveWebData('web_reminders', data);
        return 1;
      }
      return 0;
    }
    final db = await database;
    return await db.update(
      'reminders',
      reminder.toMap(),
      where: 'id = ?',
      whereArgs: [reminder.id],
    );
  }

  static Future<int> deleteReminder(int id) async {
    if (kIsWeb) {
      final data = await _getWebData('web_reminders');
      final initialLength = data.length;
      data.removeWhere((map) => map['id'] == id);
      if (data.length != initialLength) {
        await _saveWebData('web_reminders', data);
        return 1;
      }
      return 0;
    }
    final db = await database;
    return await db.delete('reminders', where: 'id = ?', whereArgs: [id]);
  }

  // 8. POMODORO HISTORY
  static Future<int> insertPomodoroHistory(PomodoroModel pomodoro) async {
    if (kIsWeb) {
      final data = await _getWebData('web_pomodoro_history');
      final newId = DateTime.now().millisecondsSinceEpoch;
      final item = pomodoro.copyWith(id: newId);
      data.add(item.toMap());
      await _saveWebData('web_pomodoro_history', data);
      return newId;
    }
    final db = await database;
    return await db.insert('pomodoro_history', pomodoro.toMap());
  }

  static Future<List<PomodoroModel>> getAllPomodoroHistory() async {
    if (kIsWeb) {
      final data = await _getWebData('web_pomodoro_history');
      final list = data.map((map) => PomodoroModel.fromMap(map)).toList();
      list.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      return list;
    }
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'pomodoro_history',
      orderBy: 'dateTime DESC',
    );
    return List.generate(maps.length, (i) => PomodoroModel.fromMap(maps[i]));
  }

  static Future<int> deletePomodoroHistory(int id) async {
    if (kIsWeb) {
      final data = await _getWebData('web_pomodoro_history');
      final initialLength = data.length;
      data.removeWhere((map) => map['id'] == id);
      if (data.length != initialLength) {
        await _saveWebData('web_pomodoro_history', data);
        return 1;
      }
      return 0;
    }
    final db = await database;
    return await db.delete(
      'pomodoro_history',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 9. FLASHCARD DECKS
  static Future<int> insertDeck(DeckModel deck) async {
    if (kIsWeb) {
      final data = await _getWebData('web_flashcard_decks');
      final newId = DateTime.now().millisecondsSinceEpoch;
      final item = deck.copyWith(id: newId);
      data.add(item.toMap());
      await _saveWebData('web_flashcard_decks', data);
      return newId;
    }
    final db = await database;
    return await db.insert('flashcard_decks', deck.toMap());
  }

  static Future<List<DeckModel>> getAllDecks() async {
    if (kIsWeb) {
      final data = await _getWebData('web_flashcard_decks');
      return data.map((map) => DeckModel.fromMap(map)).toList();
    }
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('flashcard_decks');
    return List.generate(maps.length, (i) => DeckModel.fromMap(maps[i]));
  }

  static Future<int> updateDeck(DeckModel deck) async {
    if (kIsWeb) {
      final data = await _getWebData('web_flashcard_decks');
      final index = data.indexWhere((map) => map['id'] == deck.id);
      if (index != -1) {
        data[index] = deck.toMap();
        await _saveWebData('web_flashcard_decks', data);
        return 1;
      }
      return 0;
    }
    final db = await database;
    return await db.update(
      'flashcard_decks',
      deck.toMap(),
      where: 'id = ?',
      whereArgs: [deck.id],
    );
  }

  static Future<int> deleteDeck(int id) async {
    if (kIsWeb) {
      final data = await _getWebData('web_flashcard_decks');
      final initialLength = data.length;
      data.removeWhere((map) => map['id'] == id);
      if (data.length != initialLength) {
        await _saveWebData('web_flashcard_decks', data);
        // Also delete associated flashcards
        final cards = await _getWebData('web_flashcards');
        cards.removeWhere((card) => card['deckId'] == id);
        await _saveWebData('web_flashcards', cards);
        return 1;
      }
      return 0;
    }
    final db = await database;
    await db.delete('flashcards', where: 'deckId = ?', whereArgs: [id]);
    return await db.delete('flashcard_decks', where: 'id = ?', whereArgs: [id]);
  }

  // 10. FLASHCARDS
  static Future<int> insertFlashcard(FlashcardModel flashcard) async {
    if (kIsWeb) {
      final data = await _getWebData('web_flashcards');
      final newId = DateTime.now().millisecondsSinceEpoch;
      final item = flashcard.copyWith(id: newId);
      data.add(item.toMap());
      await _saveWebData('web_flashcards', data);
      return newId;
    }
    final db = await database;
    return await db.insert('flashcards', flashcard.toMap());
  }

  static Future<List<FlashcardModel>> getAllFlashcards(int deckId) async {
    if (kIsWeb) {
      final data = await _getWebData('web_flashcards');
      final filtered = data.where((map) => map['deckId'] == deckId).toList();
      return filtered.map((map) => FlashcardModel.fromMap(map)).toList();
    }
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'flashcards',
      where: 'deckId = ?',
      whereArgs: [deckId],
    );
    return List.generate(maps.length, (i) => FlashcardModel.fromMap(maps[i]));
  }

  static Future<int> updateFlashcard(FlashcardModel flashcard) async {
    if (kIsWeb) {
      final data = await _getWebData('web_flashcards');
      final index = data.indexWhere((map) => map['id'] == flashcard.id);
      if (index != -1) {
        data[index] = flashcard.toMap();
        await _saveWebData('web_flashcards', data);
        return 1;
      }
      return 0;
    }
    final db = await database;
    return await db.update(
      'flashcards',
      flashcard.toMap(),
      where: 'id = ?',
      whereArgs: [flashcard.id],
    );
  }

  static Future<int> deleteFlashcard(int id) async {
    if (kIsWeb) {
      final data = await _getWebData('web_flashcards');
      final initialLength = data.length;
      data.removeWhere((map) => map['id'] == id);
      if (data.length != initialLength) {
        await _saveWebData('web_flashcards', data);
        return 1;
      }
      return 0;
    }
    final db = await database;
    return await db.delete('flashcards', where: 'id = ?', whereArgs: [id]);
  }
}
