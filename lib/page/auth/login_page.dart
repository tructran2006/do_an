import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng Nhập Hệ Thống'),
        backgroundColor: const Color.fromARGB(255, 11, 7, 233),
      ),
      body: const Center(
        child: Text('Giao diện Đăng nhập sẽ thiết kế tại đây'),
      ),
    );
  }
}