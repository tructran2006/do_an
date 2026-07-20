import 'package:flutter/material.dart';

class AdminAppointmentsPage extends StatelessWidget {
  const AdminAppointmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Duyệt Lịch Hẹn (Admin)')),
      body: const Center(child: Text('Giao diện danh sách lịch hẹn chờ duyệt')),
    );
  }
}