import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'package:do_an/data/model/home_service.dart';
import 'package:do_an/data/model/user_model.dart';
import 'package:do_an/data/model/appointment_model.dart';
import 'package:do_an/data/model/service_category.dart'; 
import 'package:do_an/data/model/provider_model.dart'; // Đảm bảo import đúng model này

class DatabaseHelper {
  static final DatabaseHelper _databaseService = DatabaseHelper._internal();
  factory DatabaseHelper() => _databaseService;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'db_home_services.db');
    return await openDatabase(path, onCreate: _onCreate, onUpgrade: _onUpgrade, version: 2); // Nâng lên version 2 để cập nhật cấu trúc
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute(
      'CREATE TABLE service_category(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, desc TEXT);'
    );
    
    await db.execute(
      'CREATE TABLE home_service(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, price INTEGER, img TEXT, desc TEXT, catid INTEGER);'
    );
    
    await db.execute(
      'CREATE TABLE user(id INTEGER PRIMARY KEY AUTOINCREMENT, username TEXT UNIQUE, password TEXT, fullname TEXT, phone TEXT, role TEXT);'
    );
    
    // Thêm cột providerid vào bảng appointment để lưu vết thợ được chọn
    await db.execute(
      'CREATE TABLE appointment(id INTEGER PRIMARY KEY AUTOINCREMENT, userid INTEGER, serviceid INTEGER, providerid INTEGER, bookdate TEXT, address TEXT, note TEXT, status TEXT);'
    );

    // THÊM MỚI: Bảng lưu thông tin Nhân viên / Thợ làm dịch vụ
    await db.execute(
      'CREATE TABLE provider(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, image_url TEXT, phone TEXT, price_per_hour REAL, service_id INTEGER);'
    );

    // Chèn dữ liệu kiểm thử
    await db.execute(
      "INSERT INTO user(username, password, fullname, phone, role) VALUES('admin', 'admin123', 'Hệ Thống Admin', '0123456789', 'ADMIN')"
    );

    // Chèn thợ mẫu để Test lọc theo service_id
    await db.execute("INSERT INTO provider(name, image_url, phone, price_per_hour, service_id) VALUES('Nguyễn Văn Thợ A', '', '0911223344', 50.0, 1)");
    await db.execute("INSERT INTO provider(name, image_url, phone, price_per_hour, service_id) VALUES('Trần Thị Thợ B', '', '0922334455', 60.0, 1)");
    await db.execute("INSERT INTO provider(name, image_url, phone, price_per_hour, service_id) VALUES('Lê Hoàng Thợ C', '', '0933445566', 70.0, 2)");
  }

  // Xử lý nâng cấp nếu ứng dụng đã cài từ trước mà chưa có bảng provider
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('DROP TABLE IF EXISTS appointment;');
      await db.execute(
        'CREATE TABLE appointment(id INTEGER PRIMARY KEY AUTOINCREMENT, userid INTEGER, serviceid INTEGER, providerid INTEGER, bookdate TEXT, address TEXT, note TEXT, status TEXT);'
      );
      await db.execute('DROP TABLE IF EXISTS provider;');
      await db.execute(
        'CREATE TABLE provider(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, image_url TEXT, phone TEXT, price_per_hour REAL, service_id INTEGER);'
      );
      await db.execute("INSERT INTO provider(name, image_url, phone, price_per_hour, service_id) VALUES('Nguyễn Văn Thợ A', '', '0911223344', 50.0, 1)");
      await db.execute("INSERT INTO provider(name, image_url, phone, price_per_hour, service_id) VALUES('Trần Thị Thợ B', '', '0922334455', 60.0, 1)");
    }
  }

  // --- CÁC HÀM TRUY VẤN MỚI BỔ SUNG CHO TRANG BOOKING ---

  /// Lấy toàn bộ danh sách thợ/nhân viên có trong hệ thống
  Future<List<ProviderModel>> getAllProviders() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('provider');
    return List.generate(maps.length, (index) => ProviderModel.fromMap(maps[index]));
  }

  /// Lọc trực tiếp danh sách nhân viên theo ID dịch vụ từ câu lệnh Query SQL
  Future<List<ProviderModel>> getProvidersByService(int serviceId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'provider',
      where: 'service_id = ?',
      whereArgs: [serviceId],
    );
    return List.generate(maps.length, (index) => ProviderModel.fromMap(maps[index]));
  }

  // --- CÁC HÀM CŨ GIỮ NGUYÊN HOẶC ĐỒNG BỘ ---
  
  Future<int> registerUser(UserModel user) async {
    final db = await database;
    try { return await db.insert('user', user.toMap()); } catch (e) { return -1; }
  }

  Future<UserModel?> login(String username, String password) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('user', where: 'username = ? AND password = ?', whereArgs: [username, password]);
    if (maps.isNotEmpty) return UserModel.fromMap(maps.first);
    return null;
  }

  Future<void> updateUserProfile(UserModel user) async {
    final db = await database;
    await db.update('user', user.toMap(), where: 'id = ?', whereArgs: [user.id]);
  }

  Future<List<ServiceCategoryModel>> getAllCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('service_category');
    return List.generate(maps.length, (index) => ServiceCategoryModel.fromMap(maps[index]));
  }

  Future<List<HomeServiceModel>> getAllServices() async { return await services(); }

  Future<List<HomeServiceModel>> searchServices(String keyword) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('home_service', where: 'name LIKE ?', whereArgs: ['%$keyword%']);
    return List.generate(maps.length, (index) => HomeServiceModel.fromJson(maps[index]));
  }

  Future<void> insertAppointment(AppointmentModel appointment) async { await bookAppointment(appointment); }

  Future<void> bookAppointment(AppointmentModel appointment) async {
    final db = await database;
    await db.insert('appointment', appointment.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getUserAppointments(int userId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT a.*, s.name as service_name, s.price as service_price, s.img as service_img 
      FROM appointment a
      INNER JOIN home_service s ON a.serviceid = s.id
      WHERE a.userid = ?
      ORDER BY a.id DESC
    ''', [userId]);
  }

  Future<List<HomeServiceModel>> services() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('home_service');
    return List.generate(maps.length, (index) => HomeServiceModel.fromJson(maps[index]));
  }
}