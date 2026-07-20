// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:sqflite_common_ffi/sqflite_ffi.dart';
// // Import trang đăng nhập để làm màn hình gốc ban đầu
// import 'package:do_an/page/auth/login_page.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   // Cấu hình FFI để chạy giả lập database mượt mà trên môi trường Desktop (Windows/macOS)
//   if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
//     sqfliteFfiInit();
//     databaseFactory = databaseFactoryFfi;
//   }

//   runApp(const MainApp());
// }

// class MainApp extends StatelessWidget {
//   const MainApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'Quản Lý Dịch Vụ Gia Đình',
//       // Luôn dẫn người dùng vào trang Đăng nhập trước khi vào Trang chủ phân quyền
//       home: LoginPage(), 
//     );
//   }
// }



import 'dart:io'; // Cần thiết để kiểm tra hệ điều hành app đang chạy
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // Thêm để chạy mượt database

// Thay thế bằng đường dẫn thực tế đến file mainpage.dart trong dự án của bạn
import 'package:do_an/mainpage.dart'; 

void main() {
  // 1. Đảm bảo các ràng buộc hệ thống của Flutter được khởi tạo trước
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Kích hoạt trình điều khiển database nếu chạy trên máy tính (Windows/macOS/Linux)
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
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
      debugShowCheckedModeBanner: false, // Ẩn banner debug cho đẹp giao diện
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true, // Bật Material 3 để giao diện hiện đại hơn
      ),
      
      // VÀO THẲNG TRANG CHỦ ĐỂ TEST TẠI ĐÂY:
      // Giả lập userId là 1 và quyền role là 'USER' để test giao diện của Khách hàng.
      // Bạn có thể đổi 'USER' thành 'ADMIN' để test giao diện quản trị.
      home: const MainPage(
        userId: 1, 
        role: 'USER', 
      ),
    );
  }
}