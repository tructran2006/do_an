import 'package:flutter/material.dart';

class AdminServicesPage extends StatelessWidget {
  const AdminServicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản Lý Dịch Vụ (Admin)')),
      body: const Center(child: Text('Giao diện Thêm/Sửa/Xóa dịch vụ')),
    );
  }
}