import 'package:flutter/material.dart';

import 'package:do_an/data/helper/db_helper.dart';
import 'package:do_an/data/model/user_model.dart';

class UserProfilePage extends StatefulWidget {
  final UserModel? user;
  final VoidCallback? onProfileUpdated;

  const UserProfilePage({
    super.key,
    this.user,
    this.onProfileUpdated,
  });

  @override
  State<UserProfilePage> createState() =>
      _UserProfilePageState();
}

class _UserProfilePageState
    extends State<UserProfilePage> {
  final GlobalKey<FormState> _formKey =
  GlobalKey<FormState>();

  final DatabaseHelper _dbHelper =
  DatabaseHelper();

  late final TextEditingController
  _nameController;

  late final TextEditingController
  _phoneController;

  late final TextEditingController
  _emailController;

  late final TextEditingController
  _avatarController;

  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _nameController =
        TextEditingController();

    _phoneController =
        TextEditingController();

    _emailController =
        TextEditingController();

    _avatarController =
        TextEditingController();

    _setUserData();
  }

  @override
  void didUpdateWidget(
      covariant UserProfilePage oldWidget,
      ) {
    super.didUpdateWidget(oldWidget);

    final oldUser = oldWidget.user;
    final newUser = widget.user;

    final bool userChanged =
        oldUser?.id != newUser?.id ||
            oldUser?.fullName !=
                newUser?.fullName ||
            oldUser?.phone != newUser?.phone ||
            oldUser?.email != newUser?.email ||
            oldUser?.avatar != newUser?.avatar ||
            oldUser?.role != newUser?.role;

    if (userChanged) {
      _setUserData();
      _isEditing = false;
    }
  }

  void _setUserData() {
    final user = widget.user;

    _nameController.text =
        user?.fullName ?? '';

    _phoneController.text =
        user?.phone ?? '';

    _emailController.text =
        user?.email ?? '';

    _avatarController.text =
        user?.avatar ?? '';
  }

  UserModel _createUpdatedUser({
    String? avatar,
  }) {
    final user = widget.user!;

    return UserModel(
      id: user.id,
      username: user.username,
      password: user.password,
      fullName:
      _nameController.text.trim(),
      phone:
      _phoneController.text.trim(),
      email:
      _emailController.text.trim(),
      avatar: avatar ??
          _avatarController.text.trim(),
      role: user.role,
    );
  }

  Future<void> _saveProfile() async {
    if (_isLoading) {
      return;
    }

    final user = widget.user;

    if (user == null || user.id == null) {
      _showMessage(
        'Không thể cập nhật thông tin tài khoản',
        Colors.red,
      );

      return;
    }

    final formState =
        _formKey.currentState;

    if (formState == null ||
        !formState.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedUser =
      _createUpdatedUser();

      await _dbHelper.updateUserProfile(
        updatedUser,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isEditing = false;
      });

      _showMessage(
        'Cập nhật thông tin thành công',
        Colors.green,
      );

      widget.onProfileUpdated?.call();
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Cập nhật thất bại: $e',
        Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void>
  _showAvatarDialog() async {
    final user = widget.user;

    if (user == null || user.id == null) {
      _showMessage(
        'Không thể cập nhật avatar',
        Colors.red,
      );

      return;
    }

    String avatarValue =
    _avatarController.text.trim();

    final String? result =
    await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title:
          const Text('Cập nhật avatar'),
          content: TextFormField(
            initialValue: avatarValue,
            autofocus: true,
            keyboardType:
            TextInputType.url,
            onChanged: (value) {
              avatarValue = value.trim();
            },
            decoration:
            const InputDecoration(
              labelText:
              'Đường dẫn ảnh avatar',
              hintText:
              'https://example.com/avatar.jpg',
              prefixIcon:
              Icon(Icons.image_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext)
                    .pop();
              },
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext)
                    .pop('');
              },
              child:
              const Text('Xóa ảnh'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext)
                    .pop(avatarValue);
              },
              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                Colors.green,
                foregroundColor:
                Colors.white,
              ),
              child:
              const Text('Cập nhật'),
            ),
          ],
        );
      },
    );

    if (!mounted || result == null) {
      return;
    }

    await _updateAvatar(result);
  }

  Future<void> _updateAvatar(
      String avatarUrl,
      ) async {
    if (_isLoading) {
      return;
    }

    final user = widget.user;

    if (user == null || user.id == null) {
      return;
    }

    final String oldAvatar =
        _avatarController.text;

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedUser =
      _createUpdatedUser(
        avatar: avatarUrl,
      );

      await _dbHelper.updateUserProfile(
        updatedUser,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _avatarController.text =
            avatarUrl;
      });

      _showMessage(
        avatarUrl.isEmpty
            ? 'Đã xóa ảnh đại diện'
            : 'Cập nhật avatar thành công',
        Colors.green,
      );

      widget.onProfileUpdated?.call();
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _avatarController.text =
            oldAvatar;
      });

      _showMessage(
        'Không thể cập nhật avatar: $e',
        Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _confirmLogout() async {
    if (_isLoading) {
      return;
    }

    final bool? shouldLogout =
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Xác nhận đăng xuất',
          ),
          content: const Text(
            'Bạn có chắc chắn muốn đăng xuất không?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                Colors.red,
                foregroundColor:
                Colors.white,
              ),
              child:
              const Text('Đăng xuất'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true ||
        !mounted) {
      return;
    }

    Navigator.of(context)
        .pushNamedAndRemoveUntil(
      '/login',
          (route) => false,
    );
  }

  void _cancelEditing() {
    if (_isLoading) {
      return;
    }

    setState(() {
      _isEditing = false;
      _setUserData();
    });
  }

  void _showMessage(
      String message,
      Color color,
      ) {
    if (!mounted) {
      return;
    }

    final messenger =
    ScaffoldMessenger.of(context);

    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _avatarController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(user),
                const SizedBox(height: 16),
                Padding(
                  padding:
                  const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildInformationCard(
                          user,
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        _buildAvatarButton(),
                        const SizedBox(
                          height: 12,
                        ),
                        _buildLogoutButton(),
                        if (_isEditing) ...[
                          const SizedBox(
                            height: 12,
                          ),
                          _buildCancelButton(),
                        ],
                        const SizedBox(
                          height: 24,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black
                    .withOpacity(0.15),
                child: const Center(
                  child:
                  CircularProgressIndicator(
                    color: Colors.green,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(
      UserModel? user,
      ) {
    final String avatarUrl =
    _avatarController.text.trim();

    final String displayName =
    user?.fullName.trim().isNotEmpty ==
        true
        ? user!.fullName.trim()
        : user?.username.trim().isNotEmpty ==
        true
        ? user!.username.trim()
        : 'Người dùng';

    final bool isAdmin =
        user?.role.trim().toUpperCase() ==
            'ADMIN';

    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.symmetric(
        vertical: 30,
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.shade700,
            Colors.green.shade400,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius:
        const BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withOpacity(0.15),
                      blurRadius: 10,
                      offset:
                      const Offset(0, 5),
                    ),
                  ],
                ),
                child: _buildAvatar(
                  avatarUrl,
                ),
              ),
              if (user != null)
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Material(
                    color: Colors.white,
                    shape:
                    const CircleBorder(),
                    elevation: 2,
                    child: InkWell(
                      onTap: _isLoading
                          ? null
                          : _showAvatarDialog,
                      customBorder:
                      const CircleBorder(),
                      child: const Padding(
                        padding:
                        EdgeInsets.all(8),
                        child: Icon(
                          Icons.camera_alt,
                          color: Colors.green,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            displayName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight:
              FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isAdmin
                ? 'Quản trị viên'
                : 'Khách hàng',
            style: TextStyle(
              color: Colors.white
                  .withOpacity(0.85),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(
      String avatarUrl,
      ) {
    if (avatarUrl.isEmpty) {
      return const CircleAvatar(
        radius: 50,
        backgroundColor: Colors.white,
        child: Icon(
          Icons.person,
          size: 60,
          color: Colors.green,
        ),
      );
    }

    return ClipOval(
      child: Image.network(
        avatarUrl,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        errorBuilder: (
            context,
            error,
            stackTrace,
            ) {
          return const SizedBox(
            width: 100,
            height: 100,
            child: ColoredBox(
              color: Colors.white,
              child: Icon(
                Icons.person,
                size: 60,
                color: Colors.green,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInformationCard(
      UserModel? user,
      ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(16),
      ),
      child: Padding(
        padding:
        const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Thông tin cá nhân',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed:
                  user == null || _isLoading
                      ? null
                      : () {
                    if (_isEditing) {
                      _saveProfile();
                    } else {
                      setState(() {
                        _isEditing =
                        true;
                      });
                    }
                  },
                  icon: Icon(
                    _isEditing
                        ? Icons.save
                        : Icons.edit,
                    color: Colors.green,
                    size: 20,
                  ),
                  label: Text(
                    _isEditing
                        ? 'Lưu'
                        : 'Sửa',
                    style:
                    const TextStyle(
                      color: Colors.green,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildDisabledField(
              label: 'Tên đăng nhập',
              value:
              user?.username ?? 'Chưa có',
              icon: Icons
                  .account_circle_outlined,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller:
              _nameController,
              label: 'Họ và tên',
              icon:
              Icons.person_outline,
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Vui lòng nhập họ và tên';
                }

                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller:
              _phoneController,
              label: 'Số điện thoại',
              icon:
              Icons.phone_outlined,
              keyboardType:
              TextInputType.phone,
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Vui lòng nhập số điện thoại';
                }

                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller:
              _emailController,
              label: 'Email',
              icon:
              Icons.email_outlined,
              keyboardType:
              TextInputType
                  .emailAddress,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: widget.user == null ||
            _isLoading
            ? null
            : _showAvatarDialog,
        style:
        OutlinedButton.styleFrom(
          foregroundColor:
          Colors.green,
          side: const BorderSide(
            color: Colors.green,
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(
          Icons.camera_alt_outlined,
        ),
        label: const Text(
          'Cập nhật avatar',
          style: TextStyle(
            fontSize: 16,
            fontWeight:
            FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: _isLoading
            ? null
            : _confirmLogout,
        style:
        ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
          Colors.red.shade200,
          shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.logout),
        label: const Text(
          'Đăng xuất',
          style: TextStyle(
            fontSize: 16,
            fontWeight:
            FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCancelButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: _isLoading
            ? null
            : _cancelEditing,
        style:
        OutlinedButton.styleFrom(
          foregroundColor: Colors.grey,
          side: const BorderSide(
            color: Colors.grey,
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Hủy bỏ',
          style: TextStyle(
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController
    controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType =
        TextInputType.text,
    String? Function(String?)?
    validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled:
      _isEditing && !_isLoading,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: _isEditing
              ? Colors.green
              : Colors.grey,
        ),
        filled: !_isEditing,
        fillColor: _isEditing
            ? Colors.transparent
            : Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(12),
        ),
        enabledBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(12),
          borderSide: BorderSide(
            color:
            Colors.grey.shade300,
          ),
        ),
        focusedBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(12),
          borderSide:
          const BorderSide(
            color: Colors.green,
            width: 2,
          ),
        ),
        disabledBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(12),
          borderSide: BorderSide(
            color:
            Colors.grey.shade300,
          ),
        ),
      ),
    );
  }

  Widget _buildDisabledField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return TextFormField(
      key: ValueKey(
        '$label-$value',
      ),
      initialValue: value,
      enabled: false,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: Colors.grey,
        ),
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        disabledBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}