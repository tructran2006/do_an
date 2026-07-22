import 'dart:io';
// Cần thiết để kiểm tra hệ điều hành app đang chạy

import 'package:flutter/material.dart';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
// Thêm để chạy mượt database trên Windows/macOS/Linux

// Import trang đăng nhập để làm màn hình gốc ban đầu
import 'package:do_an/page/auth/login_page.dart';

void main() {
  // 1. Đảm bảo các ràng buộc hệ thống của Flutter được khởi tạo trước
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Kích hoạt trình điều khiển database nếu chạy trên máy tính
  // Windows/macOS/Linux
  if (Platform.isWindows ||
      Platform.isLinux ||
      Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ứng Dụng Đặt Lịch Dịch Vụ',

      // Ẩn banner debug cho đẹp giao diện
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        primarySwatch: Colors.green,

        // Bật Material 3 để giao diện hiện đại hơn
        useMaterial3: true,
      ),

      // Luôn dẫn người dùng vào trang Đăng nhập trước
      // Sau khi đăng nhập thành công, hệ thống sẽ kiểm tra role:
      // ADMIN -> chuyển sang AdminMainPage
      // USER  -> chuyển sang MainPage
      initialRoute: '/login',

      // Khai báo route dùng chung để đăng xuất quay về LoginPage
      routes: {
        '/login': (context) => const LoginPage(),
      },
    );
  }
}
