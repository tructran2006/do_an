import 'package:flutter/material.dart';
import 'package:do_an/data/model/user_model.dart';

class AdminProfile extends StatelessWidget {
  final UserModel user;
  const AdminProfile({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Màn hình hồ sơ Admin')),
    );
  }
}