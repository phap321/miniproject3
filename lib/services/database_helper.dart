import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/transaction_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // In-memory list for Web or fallback when sqflite native driver is unavailable
  final List<TransactionItem> _inMemoryStorage = [];
  bool _useInMemory = kIsWeb;

  Future<Database?> get database async {
    if (_useInMemory) return null;
    if (_database != null) return _database!;

    try {
      _database = await _initDB('receipt_manager.db');
      return _database;
    } catch (e) {
      debugPrint('Sqflite init failed (fallback to in-memory): $e');
      _useInMemory = true;
      return null;
    }
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        merchant TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        category TEXT NOT NULL,
        note TEXT,
        imagePath TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // Seed sample initial transactions for demonstration
    final now = DateTime.now();
    final sampleItems = [
      TransactionItem(
        merchant: 'Siêu thị WinMart',
        amount: 150000,
        date: now.subtract(const Duration(days: 0)),
        category: ReceiptCategory.food,
        note: 'Mua nhu yếu phẩm hàng tuần, mì gói & sữa',
      ),
      TransactionItem(
        merchant: 'Nhà sách Fahasa',
        amount: 125000,
        date: now.subtract(const Duration(days: 1)),
        category: ReceiptCategory.study,
        note: 'Sách giáo trình & bút viết',
      ),
      TransactionItem(
        merchant: 'Chuyến xe GrabBike',
        amount: 35000,
        date: now.subtract(const Duration(days: 2)),
        category: ReceiptCategory.travel,
        note: 'Đi học từ ký túc xá đến trường',
      ),
      TransactionItem(
        merchant: 'Cửa hàng Phong Vũ',
        amount: 280000,
        date: now.subtract(const Duration(days: 3)),
        category: ReceiptCategory.gear,
        note: 'Chuột máy tính Logitech',
      ),
      TransactionItem(
        merchant: 'Rạp chiếu phim CGV',
        amount: 110000,
        date: now.subtract(const Duration(days: 4)),
        category: ReceiptCategory.entertainment,
        note: 'Vé xem phim cuối tuần cùng bạn',
      ),
      TransactionItem(
        merchant: 'Quán Cơm Sinh Viên',
        amount: 45000,
        date: now.subtract(const Duration(days: 5)),
        category: ReceiptCategory.food,
        note: 'Cơm sườn chả trứng',
      ),
      TransactionItem(
        merchant: 'Cây xăng Petrolimex',
        amount: 70000,
        date: now.subtract(const Duration(days: 6)),
        category: ReceiptCategory.travel,
        note: 'Đổ xăng xe máy ABL 95',
      ),
    ];

    for (var item in sampleItems) {
      await db.insert('transactions', item.toMap());
    }
  }

  // Ensure default in-memory seeds if using fallback
  void _seedInMemoryIfEmpty() {
    if (_inMemoryStorage.isNotEmpty) return;
    final now = DateTime.now();
    _inMemoryStorage.addAll([
      TransactionItem(
        id: 1,
        merchant: 'Siêu thị WinMart',
        amount: 150000,
        date: now.subtract(const Duration(days: 0)),
        category: ReceiptCategory.food,
        note: 'Mua nhu yếu phẩm hàng tuần, mì gói & sữa',
      ),
      TransactionItem(
        id: 2,
        merchant: 'Nhà sách Fahasa',
        amount: 125000,
        date: now.subtract(const Duration(days: 1)),
        category: ReceiptCategory.study,
        note: 'Sách giáo trình & bút viết',
      ),
      TransactionItem(
        id: 3,
        merchant: 'Chuyến xe GrabBike',
        amount: 35000,
        date: now.subtract(const Duration(days: 2)),
        category: ReceiptCategory.travel,
        note: 'Đi học từ ký túc xá đến trường',
      ),
      TransactionItem(
        id: 4,
        merchant: 'Cửa hàng Phong Vũ',
        amount: 280000,
        date: now.subtract(const Duration(days: 3)),
        category: ReceiptCategory.gear,
        note: 'Chuột máy tính Logitech',
      ),
      TransactionItem(
        id: 5,
        merchant: 'Rạp chiếu phim CGV',
        amount: 110000,
        date: now.subtract(const Duration(days: 4)),
        category: ReceiptCategory.entertainment,
        note: 'Vé xem phim cuối tuần cùng bạn',
      ),
      TransactionItem(
        id: 6,
        merchant: 'Quán Cơm Sinh Viên',
        amount: 45000,
        date: now.subtract(const Duration(days: 5)),
        category: ReceiptCategory.food,
        note: 'Cơm sườn chả trứng',
      ),
      TransactionItem(
        id: 7,
        merchant: 'Cây xăng Petrolimex',
        amount: 70000,
        date: now.subtract(const Duration(days: 6)),
        category: ReceiptCategory.travel,
        note: 'Đổ xăng xe máy',
      ),
    ]);
  }

  /// Create
  Future<int> insertTransaction(TransactionItem item) async {
    final db = await database;
    if (db == null) {
      _seedInMemoryIfEmpty();
      final newId = (_inMemoryStorage.map((e) => e.id ?? 0).fold(0, (max, e) => e > max ? e : max)) + 1;
      final newItem = item.copyWith(id: newId);
      _inMemoryStorage.insert(0, newItem);
      return newId;
    }
    return await db.insert('transactions', item.toMap());
  }

  /// Read All
  Future<List<TransactionItem>> getAllTransactions() async {
    final db = await database;
    if (db == null) {
      _seedInMemoryIfEmpty();
      final list = List<TransactionItem>.from(_inMemoryStorage);
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    }

    final maps = await db.query('transactions', orderBy: 'date DESC');
    return maps.map((map) => TransactionItem.fromMap(map)).toList();
  }

  /// Read One
  Future<TransactionItem?> getTransactionById(int id) async {
    final db = await database;
    if (db == null) {
      _seedInMemoryIfEmpty();
      try {
        return _inMemoryStorage.firstWhere((element) => element.id == id);
      } catch (e) {
        return null;
      }
    }

    final maps = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return TransactionItem.fromMap(maps.first);
    }
    return null;
  }

  /// Update
  Future<int> updateTransaction(TransactionItem item) async {
    final db = await database;
    if (db == null) {
      _seedInMemoryIfEmpty();
      final index = _inMemoryStorage.indexWhere((e) => e.id == item.id);
      if (index != -1) {
        _inMemoryStorage[index] = item;
        return 1;
      }
      return 0;
    }

    return await db.update(
      'transactions',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  /// Delete
  Future<int> deleteTransaction(int id) async {
    final db = await database;
    if (db == null) {
      _seedInMemoryIfEmpty();
      _inMemoryStorage.removeWhere((e) => e.id == id);
      return 1;
    }

    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get Category Spend Breakdown
  Future<Map<ReceiptCategory, double>> getCategoryTotals() async {
    final transactions = await getAllTransactions();
    final Map<ReceiptCategory, double> totals = {
      for (var category in ReceiptCategory.values) category: 0.0,
    };

    for (var tx in transactions) {
      totals[tx.category] = (totals[tx.category] ?? 0.0) + tx.amount;
    }

    return totals;
  }

  /// Get Spending per Day for Last 7 Days (Mon-Sun)
  Future<List<double>> getWeeklyDailySpend() async {
    final transactions = await getAllTransactions();
    final now = DateTime.now();
    // Monday is 1, Sunday is 7
    final currentWeekday = now.weekday;
    final mondayThisWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: currentWeekday - 1));

    List<double> dailyTotals = List.filled(7, 0.0); // Index 0 = Mon, 6 = Sun

    for (var tx in transactions) {
      final txDateOnly = DateTime(tx.date.year, tx.date.month, tx.date.day);
      final diffDays = txDateOnly.difference(mondayThisWeek).inDays;
      if (diffDays >= 0 && diffDays < 7) {
        dailyTotals[diffDays] += tx.amount;
      }
    }

    return dailyTotals;
  }
}
