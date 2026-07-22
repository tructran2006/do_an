import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'package:do_an/data/model/appointment_model.dart';
import 'package:do_an/data/model/home_service.dart';
import 'package:do_an/data/model/provider_model.dart';
import 'package:do_an/data/model/service_category.dart';
import 'package:do_an/data/model/user_model.dart';

class DatabaseHelper {
  DatabaseHelper._internal();

  static final DatabaseHelper _instance =
  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  static Database? _database;

  static const String _databaseName =
      'db_home_services.db';

  static const int _databaseVersion = 5;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final String databaseDirectory =
    await getDatabasesPath();

    final String path = join(
      databaseDirectory,
      _databaseName,
    );

    return openDatabase(
      path,
      version: _databaseVersion,
      onConfigure: (Database db) async {
        await db.execute(
          'PRAGMA foreign_keys = ON',
        );
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(
      Database db,
      int version,
      ) async {
    await _createTables(db);
    await _seedInitialData(db);
  }

  Future<void> _onUpgrade(
      Database db,
      int oldVersion,
      int newVersion,
      ) async {
    await _createMissingTables(db);

    await _addColumnIfNotExists(
      db: db,
      tableName: 'user',
      columnName: 'email',
      columnDefinition: 'TEXT',
    );

    await _addColumnIfNotExists(
      db: db,
      tableName: 'user',
      columnName: 'avatar',
      columnDefinition: 'TEXT',
    );

    await _addColumnIfNotExists(
      db: db,
      tableName: 'appointment',
      columnName: 'providerid',
      columnDefinition: 'INTEGER',
    );

    await _addColumnIfNotExists(
      db: db,
      tableName: 'appointment',
      columnName: 'status',
      columnDefinition:
      "TEXT NOT NULL DEFAULT 'PENDING'",
    );

    await _seedInitialData(db);
  }

  Future<void> _createTables(
      Database db,
      ) async {
    await db.execute('''
      CREATE TABLE service_category(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        desc TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE home_service(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price INTEGER NOT NULL DEFAULT 0,
        img TEXT,
        desc TEXT,
        catid INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE user(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        fullname TEXT,
        phone TEXT,
        role TEXT NOT NULL DEFAULT 'USER',
        email TEXT,
        avatar TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE provider(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        image_url TEXT,
        phone TEXT,
        price_per_hour REAL NOT NULL DEFAULT 0,
        service_id INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE appointment(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userid INTEGER,
        serviceid INTEGER,
        providerid INTEGER,
        bookdate TEXT,
        address TEXT,
        note TEXT,
        status TEXT NOT NULL DEFAULT 'PENDING'
      )
    ''');
  }

  Future<void> _createMissingTables(
      Database db,
      ) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS service_category(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        desc TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS home_service(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price INTEGER NOT NULL DEFAULT 0,
        img TEXT,
        desc TEXT,
        catid INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS user(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        fullname TEXT,
        phone TEXT,
        role TEXT NOT NULL DEFAULT 'USER',
        email TEXT,
        avatar TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS provider(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        image_url TEXT,
        phone TEXT,
        price_per_hour REAL NOT NULL DEFAULT 0,
        service_id INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS appointment(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userid INTEGER,
        serviceid INTEGER,
        providerid INTEGER,
        bookdate TEXT,
        address TEXT,
        note TEXT,
        status TEXT NOT NULL DEFAULT 'PENDING'
      )
    ''');
  }

  Future<void> _addColumnIfNotExists({
    required Database db,
    required String tableName,
    required String columnName,
    required String columnDefinition,
  }) async {
    final List<Map<String, dynamic>> columns =
    await db.rawQuery(
      'PRAGMA table_info($tableName)',
    );

    final bool exists = columns.any(
          (Map<String, dynamic> column) {
        return column['name'] == columnName;
      },
    );

    if (!exists) {
      await db.execute(
        'ALTER TABLE $tableName '
            'ADD COLUMN $columnName '
            '$columnDefinition',
      );
    }
  }

  // =====================================================
  // RESET DATABASE
  // =====================================================

  Future<void> resetDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }

    final String databaseDirectory =
    await getDatabasesPath();

    final String path = join(
      databaseDirectory,
      _databaseName,
    );

    await deleteDatabase(path);

    _database = await _initDatabase();
  }

  // =====================================================
  // DỮ LIỆU MẪU
  // =====================================================

  Future<void> _seedInitialData(
      Database db,
      ) async {
    await db.transaction(
          (Transaction transaction) async {
        await _insertAdminIfMissing(
          transaction,
        );

        final int cleaningCategoryId =
        await _insertCategoryIfMissing(
          transaction,
          name: 'Vệ sinh nhà cửa',
          description:
          'Dọn dẹp, giặt và vệ sinh nhà ở.',
        );

        final int coolingCategoryId =
        await _insertCategoryIfMissing(
          transaction,
          name: 'Điện lạnh',
          description:
          'Vệ sinh và sửa chữa thiết bị điện lạnh.',
        );

        final int repairCategoryId =
        await _insertCategoryIfMissing(
          transaction,
          name: 'Điện nước và sửa chữa',
          description:
          'Sửa điện, nước và thiết bị gia đình.',
        );

        final int interiorCategoryId =
        await _insertCategoryIfMissing(
          transaction,
          name: 'Nội thất và nhà ở',
          description:
          'Sơn sửa và lắp đặt nội thất.',
        );

        final int movingCategoryId =
        await _insertCategoryIfMissing(
          transaction,
          name: 'Chuyển nhà',
          description:
          'Đóng gói và vận chuyển đồ đạc.',
        );

        final int gardenCategoryId =
        await _insertCategoryIfMissing(
          transaction,
          name: 'Sân vườn và côn trùng',
          description:
          'Chăm sóc sân vườn và diệt côn trùng.',
        );

        final List<Map<String, dynamic>>
        services = [
          {
            'name': 'Vệ sinh nhà ở',
            'price': 250000,
            'img':
            'https://images.unsplash.com/photo-1581578731548-c64695cc6952',
            'desc':
            'Dọn phòng khách, phòng ngủ, nhà bếp và lau sàn.',
            'catid': cleaningCategoryId,
          },
          {
            'name': 'Giặt sofa tại nhà',
            'price': 350000,
            'img':
            'https://images.unsplash.com/photo-1555041469-a586c61ea9bc',
            'desc':
            'Giặt sofa, khử mùi và làm sạch sâu.',
            'catid': cleaningCategoryId,
          },
          {
            'name': 'Giặt nệm tại nhà',
            'price': 300000,
            'img':
            'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85',
            'desc':
            'Hút bụi, giặt và khử khuẩn nệm.',
            'catid': cleaningCategoryId,
          },
          {
            'name': 'Vệ sinh máy lạnh',
            'price': 180000,
            'img':
            'https://images.unsplash.com/photo-1621905252507-b35492cc74b4',
            'desc':
            'Vệ sinh dàn nóng, dàn lạnh và kiểm tra hoạt động.',
            'catid': coolingCategoryId,
          },
          {
            'name': 'Sửa máy lạnh',
            'price': 280000,
            'img':
            'https://images.unsplash.com/photo-1621905251918-48416bd8575a',
            'desc':
            'Kiểm tra và sửa lỗi máy lạnh.',
            'catid': coolingCategoryId,
          },
          {
            'name': 'Sửa điện nước',
            'price': 220000,
            'img':
            'https://images.unsplash.com/photo-1503387762-592deb58ef4e',
            'desc':
            'Sửa ổ điện, vòi nước và đường ống.',
            'catid': repairCategoryId,
          },
          {
            'name': 'Thông cống nghẹt',
            'price': 350000,
            'img':
            'https://images.unsplash.com/photo-1607472586893-edb57bdc0e39',
            'desc':
            'Xử lý đường thoát nước bị tắc.',
            'catid': repairCategoryId,
          },
          {
            'name': 'Sửa khóa cửa',
            'price': 150000,
            'img':
            'https://images.unsplash.com/photo-1558002038-1055907df827',
            'desc':
            'Mở khóa, sửa khóa và thay ổ khóa.',
            'catid': repairCategoryId,
          },
          {
            'name': 'Sơn nhà',
            'price': 500000,
            'img':
            'https://images.unsplash.com/photo-1562259949-e8e7689d7828',
            'desc':
            'Sơn mới hoặc sơn lại tường và trần.',
            'catid': interiorCategoryId,
          },
          {
            'name': 'Lắp đặt nội thất',
            'price': 280000,
            'img':
            'https://images.unsplash.com/photo-1586023492125-27b2c045efd7',
            'desc':
            'Lắp bàn, ghế, giường và tủ.',
            'catid': interiorCategoryId,
          },
          {
            'name': 'Chuyển nhà trọn gói',
            'price': 700000,
            'img':
            'https://images.unsplash.com/photo-1600518464441-9154a4dea21b',
            'desc':
            'Đóng gói và vận chuyển đồ đạc.',
            'catid': movingCategoryId,
          },
          {
            'name': 'Chăm sóc sân vườn',
            'price': 300000,
            'img':
            'https://images.unsplash.com/photo-1416879595882-3373a0480b5b',
            'desc':
            'Cắt cỏ, tỉa cây và vệ sinh sân vườn.',
            'catid': gardenCategoryId,
          },
          {
            'name': 'Diệt côn trùng',
            'price': 450000,
            'img':
            'https://images.unsplash.com/photo-1586282391129-76a6df230234',
            'desc':
            'Xử lý kiến, gián và muỗi trong nhà.',
            'catid': gardenCategoryId,
          },
        ];

        final Map<String, int> serviceIds =
        <String, int>{};

        for (final Map<String, dynamic>
        service in services) {
          final int id =
          await _insertServiceIfMissing(
            transaction,
            name: service['name'] as String,
            price: service['price'] as int,
            image: service['img'] as String,
            description:
            service['desc'] as String,
            categoryId:
            service['catid'] as int,
          );

          serviceIds[
          service['name'] as String] = id;
        }

        final List<Map<String, dynamic>>
        providers = [
          {
            'name': 'Nguyễn Văn An',
            'image':
            'https://images.unsplash.com/photo-1560250097-0b93528c311a',
            'phone': '0911223344',
            'price': 120000.0,
            'service': 'Vệ sinh nhà ở',
          },
          {
            'name': 'Trần Thị Bình',
            'image':
            'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2',
            'phone': '0922334455',
            'price': 140000.0,
            'service': 'Giặt sofa tại nhà',
          },
          {
            'name': 'Lê Hoàng Cường',
            'image':
            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e',
            'phone': '0933445566',
            'price': 130000.0,
            'service': 'Giặt nệm tại nhà',
          },
          {
            'name': 'Phạm Minh Đức',
            'image':
            'https://images.unsplash.com/photo-1568602471122-7832951cc4c5',
            'phone': '0944556677',
            'price': 150000.0,
            'service': 'Vệ sinh máy lạnh',
          },
          {
            'name': 'Võ Quốc Huy',
            'image':
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d',
            'phone': '0955667788',
            'price': 180000.0,
            'service': 'Sửa máy lạnh',
          },
          {
            'name': 'Đặng Văn Khang',
            'image':
            'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e',
            'phone': '0966778899',
            'price': 160000.0,
            'service': 'Sửa điện nước',
          },
          {
            'name': 'Bùi Thanh Long',
            'image':
            'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7',
            'phone': '0977889900',
            'price': 170000.0,
            'service': 'Thông cống nghẹt',
          },
          {
            'name': 'Ngô Gia Minh',
            'image':
            'https://images.unsplash.com/photo-1531123897727-8f129e1688ce',
            'phone': '0988990011',
            'price': 120000.0,
            'service': 'Sửa khóa cửa',
          },
          {
            'name': 'Đỗ Anh Nam',
            'image':
            'https://images.unsplash.com/photo-1519345182560-3f2917c472ef',
            'phone': '0909001122',
            'price': 200000.0,
            'service': 'Sơn nhà',
          },
          {
            'name': 'Hoàng Tuấn Phong',
            'image':
            'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d',
            'phone': '0908112233',
            'price': 170000.0,
            'service': 'Lắp đặt nội thất',
          },
          {
            'name': 'Trương Hải Quân',
            'image':
            'https://images.unsplash.com/photo-1501196354995-cbb51c65aaea',
            'phone': '0907223344',
            'price': 220000.0,
            'service': 'Chuyển nhà trọn gói',
          },
          {
            'name': 'Mai Văn Sơn',
            'image':
            'https://images.unsplash.com/photo-1531427186611-ecfd6d936c79',
            'phone': '0906334455',
            'price': 150000.0,
            'service': 'Chăm sóc sân vườn',
          },
          {
            'name': 'Lý Thành Tâm',
            'image':
            'https://images.unsplash.com/photo-1521119989659-a83eee488004',
            'phone': '0905445566',
            'price': 190000.0,
            'service': 'Diệt côn trùng',
          },
        ];

        for (final Map<String, dynamic>
        provider in providers) {
          final int? serviceId =
          serviceIds[
          provider['service'] as String];

          if (serviceId == null) {
            continue;
          }

          await _insertProviderIfMissing(
            transaction,
            name: provider['name'] as String,
            imageUrl:
            provider['image'] as String,
            phone:
            provider['phone'] as String,
            pricePerHour:
            provider['price'] as double,
            serviceId: serviceId,
          );
        }
      },
    );
  }

  Future<void> _insertAdminIfMissing(
      Transaction transaction,
      ) async {
    final List<Map<String, dynamic>> existing =
    await transaction.query(
      'user',
      columns: ['id'],
      where: 'username = ?',
      whereArgs: ['admin'],
      limit: 1,
    );

    if (existing.isEmpty) {
      await transaction.insert(
        'user',
        {
          'username': 'admin',
          'password': 'admin123',
          'fullname': 'Hệ Thống Admin',
          'phone': '0123456789',
          'role': 'ADMIN',
          'email': 'admin@gmail.com',
          'avatar': '',
        },
      );
    }
  }

  Future<int> _insertCategoryIfMissing(
      Transaction transaction, {
        required String name,
        required String description,
      }) async {
    final List<Map<String, dynamic>> existing =
    await transaction.query(
      'service_category',
      columns: ['id'],
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      return (existing.first['id'] as num)
          .toInt();
    }

    return transaction.insert(
      'service_category',
      {
        'name': name,
        'desc': description,
      },
    );
  }

  Future<int> _insertServiceIfMissing(
      Transaction transaction, {
        required String name,
        required int price,
        required String image,
        required String description,
        required int categoryId,
      }) async {
    final List<Map<String, dynamic>> existing =
    await transaction.query(
      'home_service',
      columns: ['id'],
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      final int id =
      (existing.first['id'] as num).toInt();

      await transaction.update(
        'home_service',
        {
          'price': price,
          'img': image,
          'desc': description,
          'catid': categoryId,
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      return id;
    }

    return transaction.insert(
      'home_service',
      {
        'name': name,
        'price': price,
        'img': image,
        'desc': description,
        'catid': categoryId,
      },
    );
  }

  Future<void> _insertProviderIfMissing(
      Transaction transaction, {
        required String name,
        required String imageUrl,
        required String phone,
        required double pricePerHour,
        required int serviceId,
      }) async {
    final List<Map<String, dynamic>> existing =
    await transaction.query(
      'provider',
      columns: ['id'],
      where: 'name = ? AND phone = ?',
      whereArgs: [name, phone],
      limit: 1,
    );

    if (existing.isEmpty) {
      await transaction.insert(
        'provider',
        {
          'name': name,
          'image_url': imageUrl,
          'phone': phone,
          'price_per_hour': pricePerHour,
          'service_id': serviceId,
        },
      );
    } else {
      await transaction.update(
        'provider',
        {
          'image_url': imageUrl,
          'price_per_hour': pricePerHour,
          'service_id': serviceId,
        },
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    }
  }

  // =====================================================
  // USER / AUTH
  // =====================================================

  Future<int> registerUser(
      UserModel user,
      ) async {
    final Database db = await database;

    try {
      return await db.insert(
        'user',
        user.toMap(),
        conflictAlgorithm:
        ConflictAlgorithm.abort,
      );
    } catch (_) {
      return -1;
    }
  }

  Future<UserModel?> login(
      String username,
      String password,
      ) async {
    final Database db = await database;

    final List<Map<String, dynamic>> result =
    await db.query(
      'user',
      where:
      'username = ? AND password = ?',
      whereArgs: [
        username.trim(),
        password,
      ],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return UserModel.fromMap(
      result.first,
    );
  }

  Future<UserModel?> getUserById(
      int userId,
      ) async {
    final Database db = await database;

    final List<Map<String, dynamic>> result =
    await db.query(
      'user',
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return UserModel.fromMap(
      result.first,
    );
  }

  Future<List<UserModel>> getAllUsers() async {
    final Database db = await database;

    final List<Map<String, dynamic>> result =
    await db.query(
      'user',
      orderBy: 'fullname COLLATE NOCASE ASC',
    );

    return result
        .map(UserModel.fromMap)
        .toList();
  }

  Future<int> updateUserProfile(
      UserModel user,
      ) async {
    if (user.id == null) {
      throw Exception(
        'ID người dùng đang null.',
      );
    }

    final Database db = await database;

    return db.update(
      'user',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> updateUserRole({
    required int userId,
    required String role,
  }) async {
    final Database db = await database;

    return db.update(
      'user',
      {
        'role': role.toUpperCase(),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<int> deleteUser(
      int userId,
      ) async {
    final Database db = await database;

    return db.transaction(
          (Transaction transaction) async {
        await transaction.delete(
          'appointment',
          where: 'userid = ?',
          whereArgs: [userId],
        );

        return transaction.delete(
          'user',
          where: 'id = ?',
          whereArgs: [userId],
        );
      },
    );
  }

  // =====================================================
  // CATEGORY
  // =====================================================

  Future<List<ServiceCategoryModel>>
  getAllCategories() async {
    final Database db = await database;

    final List<Map<String, dynamic>> result =
    await db.query(
      'service_category',
      orderBy: 'name COLLATE NOCASE ASC',
    );

    return result
        .map(ServiceCategoryModel.fromMap)
        .toList();
  }

  // =====================================================
  // SERVICE - USER
  // =====================================================

  Future<List<HomeServiceModel>>
  getAllServices() async {
    final Database db = await database;

    final List<Map<String, dynamic>> result =
    await db.query(
      'home_service',
      orderBy: 'name COLLATE NOCASE ASC',
    );

    return result
        .map(HomeServiceModel.fromJson)
        .toList();
  }

  Future<List<HomeServiceModel>> services() async {
    return getAllServices();
  }

  Future<List<HomeServiceModel>> searchServices(
      String keyword,
      ) async {
    final Database db = await database;

    final List<Map<String, dynamic>> result =
    await db.query(
      'home_service',
      where: 'name LIKE ?',
      whereArgs: ['%${keyword.trim()}%'],
      orderBy: 'name COLLATE NOCASE ASC',
    );

    return result
        .map(HomeServiceModel.fromJson)
        .toList();
  }

  // =====================================================
  // SERVICE - ADMIN
  // =====================================================

  Future<List<Map<String, dynamic>>>
  getAdminServices() async {
    final Database db = await database;

    return db.rawQuery('''
      SELECT
        s.id,
        s.name,
        s.price,
        s.img,
        s.desc,
        s.catid,
        c.name AS category_name
      FROM home_service s
      LEFT JOIN service_category c
        ON s.catid = c.id
      ORDER BY s.name COLLATE NOCASE ASC
    ''');
  }

  Future<int> addService({
    required String name,
    required int price,
    required String image,
    required String description,
    int? categoryId,
  }) async {
    final Database db = await database;

    return db.insert(
      'home_service',
      {
        'name': name.trim(),
        'price': price,
        'img': image.trim(),
        'desc': description.trim(),
        'catid': categoryId,
      },
    );
  }

  Future<int> updateService({
    required int id,
    required String name,
    required int price,
    required String image,
    required String description,
    int? categoryId,
  }) async {
    final Database db = await database;

    return db.update(
      'home_service',
      {
        'name': name.trim(),
        'price': price,
        'img': image.trim(),
        'desc': description.trim(),
        'catid': categoryId,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteService(
      int serviceId,
      ) async {
    final Database db = await database;

    return db.transaction(
          (Transaction transaction) async {
        await transaction.delete(
          'appointment',
          where: 'serviceid = ?',
          whereArgs: [serviceId],
        );

        await transaction.delete(
          'provider',
          where: 'service_id = ?',
          whereArgs: [serviceId],
        );

        return transaction.delete(
          'home_service',
          where: 'id = ?',
          whereArgs: [serviceId],
        );
      },
    );
  }

  // =====================================================
  // PROVIDER - USER
  // =====================================================

  Future<List<ProviderModel>>
  getAllProviders() async {
    final Database db = await database;

    final List<Map<String, dynamic>> result =
    await db.query(
      'provider',
      orderBy: 'name COLLATE NOCASE ASC',
    );

    return result
        .map(ProviderModel.fromMap)
        .toList();
  }

  Future<List<ProviderModel>>
  getProvidersByService(
      int serviceId,
      ) async {
    final Database db = await database;

    final List<Map<String, dynamic>> result =
    await db.query(
      'provider',
      where: 'service_id = ?',
      whereArgs: [serviceId],
      orderBy: 'name COLLATE NOCASE ASC',
    );

    return result
        .map(ProviderModel.fromMap)
        .toList();
  }

  // =====================================================
  // PROVIDER - ADMIN
  // =====================================================

  Future<List<Map<String, dynamic>>>
  getAdminProviders() async {
    final Database db = await database;

    return db.rawQuery('''
      SELECT
        p.id,
        p.name,
        p.image_url,
        p.phone,
        p.price_per_hour,
        p.service_id,
        s.name AS service_name
      FROM provider p
      LEFT JOIN home_service s
        ON p.service_id = s.id
      ORDER BY p.name COLLATE NOCASE ASC
    ''');
  }

  Future<int> addProvider({
    required String name,
    required String imageUrl,
    required String phone,
    required double pricePerHour,
    required int serviceId,
  }) async {
    final Database db = await database;

    return db.insert(
      'provider',
      {
        'name': name.trim(),
        'image_url': imageUrl.trim(),
        'phone': phone.trim(),
        'price_per_hour': pricePerHour,
        'service_id': serviceId,
      },
    );
  }

  Future<int> updateProvider({
    required int id,
    required String name,
    required String imageUrl,
    required String phone,
    required double pricePerHour,
    required int serviceId,
  }) async {
    final Database db = await database;

    return db.update(
      'provider',
      {
        'name': name.trim(),
        'image_url': imageUrl.trim(),
        'phone': phone.trim(),
        'price_per_hour': pricePerHour,
        'service_id': serviceId,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteProvider(
      int providerId,
      ) async {
    final Database db = await database;

    return db.transaction(
          (Transaction transaction) async {
        await transaction.update(
          'appointment',
          {
            'providerid': null,
          },
          where: 'providerid = ?',
          whereArgs: [providerId],
        );

        return transaction.delete(
          'provider',
          where: 'id = ?',
          whereArgs: [providerId],
        );
      },
    );
  }

  // =====================================================
  // APPOINTMENT
  // =====================================================

  Future<int> insertAppointment(
      AppointmentModel appointment,
      ) async {
    final Database db = await database;

    return db.insert(
      'appointment',
      appointment.toMap(),
    );
  }

  Future<int> bookAppointment(
      AppointmentModel appointment,
      ) async {
    return insertAppointment(
      appointment,
    );
  }

  Future<List<Map<String, dynamic>>>
  getUserAppointments(
      int userId,
      ) async {
    final Database db = await database;

    return db.rawQuery(
      '''
      SELECT
        a.id,
        a.userid,
        a.serviceid,
        a.providerid,
        a.bookdate,
        a.address,
        a.note,
        a.status,

        s.name AS service_name,
        s.price AS service_price,
        s.img AS service_img,

        p.name AS provider_name,
        p.phone AS provider_phone,
        p.image_url AS provider_image,
        p.price_per_hour AS provider_price_per_hour

      FROM appointment a

      LEFT JOIN home_service s
        ON a.serviceid = s.id

      LEFT JOIN provider p
        ON a.providerid = p.id

      WHERE a.userid = ?

      ORDER BY a.id DESC
      ''',
      [userId],
    );
  }

  Future<List<Map<String, dynamic>>>
  getAdminAppointments() async {
    final Database db = await database;

    return db.rawQuery('''
      SELECT
        a.id,
        a.userid,
        a.serviceid,
        a.providerid,
        a.bookdate,
        a.address,
        a.note,
        a.status,

        u.fullname AS user_name,
        u.phone AS user_phone,

        s.name AS service_name,
        s.price AS service_price,

        p.name AS provider_name,
        p.phone AS provider_phone

      FROM appointment a

      LEFT JOIN user u
        ON a.userid = u.id

      LEFT JOIN home_service s
        ON a.serviceid = s.id

      LEFT JOIN provider p
        ON a.providerid = p.id

      ORDER BY a.id DESC
    ''');
  }

  Future<int> updateAppointmentStatus({
    required int appointmentId,
    required String status,
  }) async {
    final Database db = await database;

    return db.update(
      'appointment',
      {
        'status': status.toUpperCase(),
      },
      where: 'id = ?',
      whereArgs: [appointmentId],
    );
  }

  Future<int> deleteAppointment(
      int appointmentId,
      ) async {
    final Database db = await database;

    return db.delete(
      'appointment',
      where: 'id = ?',
      whereArgs: [appointmentId],
    );
  }

  // =====================================================
  // DASHBOARD ADMIN
  // =====================================================

  Future<Map<String, dynamic>>
  getAdminDashboardStatistics() async {
    final Database db = await database;

    final List<Map<String, dynamic>>
    serviceResult = await db.rawQuery(
      'SELECT COUNT(*) AS total '
          'FROM home_service',
    );

    final List<Map<String, dynamic>>
    providerResult = await db.rawQuery(
      'SELECT COUNT(*) AS total '
          'FROM provider',
    );

    final List<Map<String, dynamic>>
    appointmentResult = await db.rawQuery(
      'SELECT COUNT(*) AS total '
          'FROM appointment',
    );

    final List<Map<String, dynamic>>
    userResult = await db.rawQuery(
      "SELECT COUNT(*) AS total "
          "FROM user "
          "WHERE UPPER(role) != 'ADMIN'",
    );

    final List<Map<String, dynamic>>
    revenueResult = await db.rawQuery('''
      SELECT
        COALESCE(SUM(s.price), 0) AS total
      FROM appointment a
      INNER JOIN home_service s
        ON a.serviceid = s.id
      WHERE UPPER(
        COALESCE(a.status, 'PENDING')
      ) != 'CANCELLED'
    ''');

    return {
      'serviceCount':
      serviceResult.first['total'] ?? 0,
      'providerCount':
      providerResult.first['total'] ?? 0,
      'appointmentCount':
      appointmentResult.first['total'] ?? 0,
      'userCount':
      userResult.first['total'] ?? 0,
      'revenue':
      revenueResult.first['total'] ?? 0,
    };
  }
}
