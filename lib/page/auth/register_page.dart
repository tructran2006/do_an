import 'package:flutter/material.dart';

import 'package:do_an/data/helper/db_helper.dart';
import 'package:do_an/data/model/user_model.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() =>
      _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController fullNameController =
      TextEditingController();

  final TextEditingController usernameController =
      TextEditingController();

  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController phoneController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool hidePassword = true;
  bool hideConfirmPassword = true;
  bool isLoading = false;

  @override
  void dispose() {
    fullNameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> register() async {
    final String fullName =
        fullNameController.text.trim();

    final String username =
        usernameController.text.trim();

    final String email =
        emailController.text.trim();

    final String phone =
        phoneController.text.trim();

    final String password =
        passwordController.text.trim();

    final String confirmPassword =
        confirmPasswordController.text.trim();

    // Kiểm tra các trường bắt buộc
    if (fullName.isEmpty ||
        username.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vui lòng nhập đầy đủ các thông tin bắt buộc',
          ),
          backgroundColor: Colors.orange,
        ),
      );

      return;
    }

    // Kiểm tra độ dài tên đăng nhập
    if (username.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tên đăng nhập phải có ít nhất 4 ký tự',
          ),
          backgroundColor: Colors.orange,
        ),
      );

      return;
    }

    // Kiểm tra độ dài mật khẩu
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Mật khẩu phải có ít nhất 6 ký tự',
          ),
          backgroundColor: Colors.orange,
        ),
      );

      return;
    }

    // Kiểm tra mật khẩu xác nhận
    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Mật khẩu xác nhận không trùng khớp',
          ),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    // Kiểm tra định dạng email nếu người dùng có nhập
    if (email.isNotEmpty &&
        !RegExp(
          r'^[\w\.-]+@[\w\.-]+\.\w+$',
        ).hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Email không đúng định dạng',
          ),
          backgroundColor: Colors.orange,
        ),
      );

      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final UserModel user = UserModel(
        username: username,
        password: password,
        fullName: fullName,
        phone: phone,
        role: 'USER',
        email: email,
        avatar: '',
      );

      // Lưu người dùng mới vào SQLite
      final int result =
          await DatabaseHelper().registerUser(user);

      if (!mounted) {
        return;
      }

      if (result == -1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Tên đăng nhập đã tồn tại',
            ),
            backgroundColor: Colors.red,
          ),
        );

        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Đăng ký tài khoản thành công',
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Quay về trang đăng nhập sau khi đăng ký thành công
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đăng ký thất bại: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  InputDecoration buildInputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Đăng ký tài khoản',
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.person_add_alt_1,
                  size: 70,
                  color: Colors.green,
                ),
                const SizedBox(height: 12),
                const Text(
                  'TẠO TÀI KHOẢN',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Đăng ký để sử dụng dịch vụ gia đình',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 30),

                TextField(
                  controller: fullNameController,
                  textInputAction: TextInputAction.next,
                  decoration: buildInputDecoration(
                    label: 'Họ và tên *',
                    icon: Icons.badge,
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: usernameController,
                  textInputAction: TextInputAction.next,
                  decoration: buildInputDecoration(
                    label: 'Tên đăng nhập *',
                    icon: Icons.person,
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: emailController,
                  keyboardType:
                      TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: buildInputDecoration(
                    label: 'Email',
                    icon: Icons.email,
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: buildInputDecoration(
                    label: 'Số điện thoại',
                    icon: Icons.phone,
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: passwordController,
                  obscureText: hidePassword,
                  textInputAction: TextInputAction.next,
                  decoration: buildInputDecoration(
                    label: 'Mật khẩu *',
                    icon: Icons.lock,
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          hidePassword =
                              !hidePassword;
                        });
                      },
                      icon: Icon(
                        hidePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller:
                      confirmPasswordController,
                  obscureText: hideConfirmPassword,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) {
                    if (!isLoading) {
                      register();
                    }
                  },
                  decoration: buildInputDecoration(
                    label: 'Xác nhận mật khẩu *',
                    icon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          hideConfirmPassword =
                              !hideConfirmPassword;
                        });
                      },
                      icon: Icon(
                        hideConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed:
                        isLoading ? null : register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'ĐĂNG KÝ',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 14),

                TextButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          Navigator.pop(context);
                        },
                  child: const Text(
                    'Đã có tài khoản? Quay lại đăng nhập',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}