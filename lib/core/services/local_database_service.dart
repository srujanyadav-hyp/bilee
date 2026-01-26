import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Local Database Service - SQLite database for offline storage
class LocalDatabaseService {
  static LocalDatabaseService? _instance;
  static Database? _database;

  LocalDatabaseService._();

  factory LocalDatabaseService() {
    _instance ??= LocalDatabaseService._();
    return _instance!;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'bilee_offline.db');

    return await openDatabase(
      path,
      version: 2, // Incremented for inventory management
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Sessions table - for offline billing
    await db.execute('''
      CREATE TABLE sessions (
        id TEXT PRIMARY KEY,
        merchantId TEXT NOT NULL,
        staffId TEXT,
        items TEXT NOT NULL,
        totalAmount REAL NOT NULL,
        discount REAL DEFAULT 0,
        tax REAL DEFAULT 0,
        paymentMethod TEXT,
        paymentStatus TEXT NOT NULL,
        createdAt INTEGER NOT NULL,
        isSynced INTEGER DEFAULT 0
      )
    ''');

    // Items cache table - for offline item library
    await db.execute('''
      CREATE TABLE items_cache (
        id TEXT PRIMARY KEY,
        merchantId TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        price REAL NOT NULL,
        category TEXT,
        hsnCode TEXT,
        lastUpdated INTEGER NOT NULL
      )
    ''');

    // Sync queue table - for pending operations
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        operationType TEXT NOT NULL,
        entityType TEXT NOT NULL,
        entityId TEXT NOT NULL,
        data TEXT NOT NULL,
        createdAt INTEGER NOT NULL,
        retryCount INTEGER DEFAULT 0,
        lastError TEXT
      )
    ''');

    // Staff activity logs table
    await db.execute('''
      CREATE TABLE staff_activity_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        staffId TEXT NOT NULL,
        merchantId TEXT NOT NULL,
        activityType TEXT NOT NULL,
        description TEXT,
        entityType TEXT,
        entityId TEXT,
        createdAt INTEGER NOT NULL,
        isSynced INTEGER DEFAULT 0
      )
    ''');

    // Create indexes for better query performance
    await db.execute(
      'CREATE INDEX idx_sessions_merchant ON sessions(merchantId)',
    );
    await db.execute('CREATE INDEX idx_sessions_synced ON sessions(isSynced)');
    await db.execute(
      'CREATE INDEX idx_items_merchant ON items_cache(merchantId)',
    );
    await db.execute(
      'CREATE INDEX idx_sync_queue_entity ON sync_queue(entityType, entityId)',
    );
    await db.execute(
      'CREATE INDEX idx_staff_logs_staff ON staff_activity_logs(staffId)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Version 1 → 2: Add inventory management support
    if (oldVersion < 2) {
      // Add inventory columns to items_cache table
      await db.execute(
        'ALTER TABLE items_cache ADD COLUMN inventoryEnabled INTEGER DEFAULT 0',
      );
      await db.execute('ALTER TABLE items_cache ADD COLUMN currentStock REAL');
      await db.execute(
        'ALTER TABLE items_cache ADD COLUMN lowStockThreshold REAL',
      );
      await db.execute('ALTER TABLE items_cache ADD COLUMN stockUnit TEXT');
      await db.execute(
        'ALTER TABLE items_cache ADD COLUMN lastStockUpdate INTEGER',
      );

      // Create inventory_transactions table
      await db.execute('''
        CREATE TABLE inventory_transactions (
          id TEXT PRIMARY KEY,
          itemId TEXT NOT NULL,
          merchantId TEXT NOT NULL,
          quantityChange REAL NOT NULL,
          stockAfter REAL NOT NULL,
          type TEXT NOT NULL,
          sessionId TEXT,
          notes TEXT,
          timestamp INTEGER NOT NULL,
          isSynced INTEGER DEFAULT 0,
          FOREIGN KEY (itemId) REFERENCES items_cache(id)
        )
      ''');

      // Create indexes for inventory_transactions
      await db.execute(
        'CREATE INDEX idx_inventory_item ON inventory_transactions(itemId)',
      );
      await db.execute(
        'CREATE INDEX idx_inventory_merchant ON inventory_transactions(merchantId)',
      );
      await db.execute(
        'CREATE INDEX idx_inventory_synced ON inventory_transactions(isSynced)',
      );
    }
  }

  // ==================== SESSION OPERATIONS ====================

  Future<void> insertSession(Map<String, dynamic> session) async {
    final db = await database;
    await db.insert(
      'sessions',
      session,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getUnsyncedSessions() async {
    final db = await database;
    return await db.query(
      'sessions',
      where: 'isSynced = ?',
      whereArgs: [0],
      orderBy: 'createdAt ASC',
    );
  }

  Future<void> markSessionAsSynced(String sessionId) async {
    final db = await database;
    await db.update(
      'sessions',
      {'isSynced': 1},
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  // ==================== ITEMS CACHE OPERATIONS ====================

  Future<void> cacheItems(List<Map<String, dynamic>> items) async {
    final db = await database;
    final batch = db.batch();

    for (final item in items) {
      batch.insert(
        'items_cache',
        item,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getCachedItems(String merchantId) async {
    final db = await database;
    return await db.query(
      'items_cache',
      where: 'merchantId = ?',
      whereArgs: [merchantId],
      orderBy: 'name ASC',
    );
  }

  Future<void> clearItemsCache(String merchantId) async {
    final db = await database;
    await db.delete(
      'items_cache',
      where: 'merchantId = ?',
      whereArgs: [merchantId],
    );
  }

  // ==================== SYNC QUEUE OPERATIONS ====================

  Future<int> addToSyncQueue({
    required String operationType,
    required String entityType,
    required String entityId,
    required String data,
  }) async {
    final db = await database;
    return await db.insert('sync_queue', {
      'operationType': operationType,
      'entityType': entityType,
      'entityId': entityId,
      'data': data,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'retryCount': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getSyncQueue() async {
    final db = await database;
    return await db.query(
      'sync_queue',
      orderBy: 'createdAt ASC',
      limit: 50, // Process in batches
    );
  }

  Future<void> removeSyncQueueItem(int id) async {
    final db = await database;
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateSyncQueueRetry(int id, String error) async {
    final db = await database;
    await db.execute(
      '''
      UPDATE sync_queue 
      SET retryCount = retryCount + 1, lastError = ?
      WHERE id = ?
    ''',
      [error, id],
    );
  }

  // ==================== STAFF ACTIVITY LOGS ====================

  Future<void> logStaffActivity({
    required String staffId,
    required String merchantId,
    required String activityType,
    String? description,
    String? entityType,
    String? entityId,
  }) async {
    final db = await database;
    await db.insert('staff_activity_logs', {
      'staffId': staffId,
      'merchantId': merchantId,
      'activityType': activityType,
      'description': description,
      'entityType': entityType,
      'entityId': entityId,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'isSynced': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getUnsyncedLogs() async {
    final db = await database;
    return await db.query(
      'staff_activity_logs',
      where: 'isSynced = ?',
      whereArgs: [0],
      orderBy: 'createdAt ASC',
    );
  }

  Future<void> markLogsAsSynced(List<int> ids) async {
    final db = await database;
    final batch = db.batch();

    for (final id in ids) {
      batch.update(
        'staff_activity_logs',
        {'isSynced': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    }

    await batch.commit(noResult: true);
  }

  // ==================== UTILITY OPERATIONS ====================

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('sessions');
    await db.delete('items_cache');
    await db.delete('sync_queue');
    await db.delete('staff_activity_logs');
  }

  Future<Map<String, int>> getDatabaseStats() async {
    final db = await database;

    final sessionsCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM sessions'),
        ) ??
        0;

    final itemsCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM items_cache'),
        ) ??
        0;

    final syncQueueCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM sync_queue'),
        ) ??
        0;

    final logsCount =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM staff_activity_logs WHERE isSynced = 0',
          ),
        ) ??
        0;

    return {
      'sessions': sessionsCount,
      'items': itemsCount,
      'syncQueue': syncQueueCount,
      'unsyncedLogs': logsCount,
    };
  }

  // ==================== INVENTORY OPERATIONS ====================

  /// Insert inventory transaction
  Future<void> insertInventoryTransaction(
    Map<String, dynamic> transaction,
  ) async {
    final db = await database;
    await db.insert(
      'inventory_transactions',
      transaction,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get unsynced inventory transactions
  Future<List<Map<String, dynamic>>> getUnsyncedInventoryTransactions() async {
    final db = await database;
    return await db.query(
      'inventory_transactions',
      where: 'isSynced = ?',
      whereArgs: [0],
      orderBy: 'timestamp ASC',
    );
  }

  /// Mark inventory transaction as synced
  Future<void> markInventoryTransactionAsSynced(String transactionId) async {
    final db = await database;
    await db.update(
      'inventory_transactions',
      {'isSynced': 1},
      where: 'id = ?',
      whereArgs: [transactionId],
    );
  }

  /// Get inventory transaction history for an item
  Future<List<Map<String, dynamic>>> getInventoryHistory(String itemId) async {
    final db = await database;
    return await db.query(
      'inventory_transactions',
      where: 'itemId = ?',
      whereArgs: [itemId],
      orderBy: 'timestamp DESC',
      limit: 50, // Last 50 transactions
    );
  }

  /// Update item stock in cache
  Future<void> updateItemStock({
    required String itemId,
    required double newStock,
    required int timestamp,
  }) async {
    final db = await database;
    await db.update(
      'items_cache',
      {'currentStock': newStock, 'lastStockUpdate': timestamp},
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  /// Get low stock items
  Future<List<Map<String, dynamic>>> getLowStockItems(String merchantId) async {
    final db = await database;
    return await db.rawQuery(
      '''
      SELECT * FROM items_cache
      WHERE merchantId = ?
        AND inventoryEnabled = 1
        AND currentStock IS NOT NULL
        AND lowStockThreshold IS NOT NULL
        AND currentStock <= lowStockThreshold
      ORDER BY currentStock ASC
    ''',
      [merchantId],
    );
  }

  /// Get out of stock items
  Future<List<Map<String, dynamic>>> getOutOfStockItems(
    String merchantId,
  ) async {
    final db = await database;
    return await db.rawQuery(
      '''
      SELECT * FROM items_cache
      WHERE merchantId = ?
        AND inventoryEnabled = 1
        AND currentStock IS NOT NULL
        AND currentStock <= 0
    ''',
      [merchantId],
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
