import 'package:flutter/material.dart';

import 'package:do_an/data/helper/db_helper.dart';
import 'package:do_an/data/model/user_model.dart';

class AdminUsersPage extends StatefulWidget {
  final int currentAdminId;

  const AdminUsersPage({
    super.key,
    required this.currentAdminId,
  });

  @override
  State<AdminUsersPage> createState() =>
      _AdminUsersPageState();
}

class _AdminUsersPageState
    extends State<AdminUsersPage> {
  final DatabaseHelper _databaseHelper =
  DatabaseHelper();

  final TextEditingController _searchController =
  TextEditingController();

  List<UserModel> _users = [];
  List<UserModel> _filteredUsers = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _searchController.addListener(
      _filterUsers,
    );

    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.removeListener(
      _filterUsers,
    );

    _searchController.dispose();

    super.dispose();
  }

  Future<void> _loadUsers() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final List<UserModel> users =
      await _databaseHelper.getAllUsers();

      if (!mounted) {
        return;
      }

      setState(() {
        _users = users;
        _isLoading = false;
      });

      _filterUsers();
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Không thể tải danh sách tài khoản: $error',
          ),
        ),
      );
    }
  }

  void _filterUsers() {
    final String keyword =
    _searchController.text.trim().toLowerCase();

    final List<UserModel> result =
    _users.where((UserModel user) {
      final String displayName =
      user.fullName.trim().isEmpty
          ? user.username.trim().toLowerCase()
          : user.fullName.trim().toLowerCase();

      return keyword.isEmpty ||
          displayName.startsWith(keyword);
    }).toList();

    result.sort(
          (UserModel first, UserModel second) {
        final String firstName =
        first.fullName.trim().isEmpty
            ? first.username.trim().toLowerCase()
            : first.fullName.trim().toLowerCase();

        final String secondName =
        second.fullName.trim().isEmpty
            ? second.username.trim().toLowerCase()
            : second.fullName.trim().toLowerCase();

        return firstName.compareTo(secondName);
      },
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _filteredUsers = result;
    });
  }

  void _clearSearch() {
    _searchController.clear();
  }

  Future<void> _showUserDetails(
      UserModel user,
      ) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text(
            'Thông tin tài khoản',
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                _buildDetailRow(
                  label: 'Họ tên',
                  value: user.fullName.trim().isEmpty
                      ? 'Chưa có'
                      : user.fullName,
                ),
                _buildDetailRow(
                  label: 'Tên đăng nhập',
                  value: user.username,
                ),
                _buildDetailRow(
                  label: 'Email',
                  value: user.email.trim().isEmpty
                      ? 'Chưa có'
                      : user.email,
                ),
                _buildDetailRow(
                  label: 'Số điện thoại',
                  value: user.phone.trim().isEmpty
                      ? 'Chưa có'
                      : user.phone,
                ),
                _buildDetailRow(
                  label: 'Quyền',
                  value: user.role,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 10,
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUser(
      UserModel user,
      ) async {
    if (user.id == null) {
      return;
    }

    if (user.id == widget.currentAdminId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Không thể xóa tài khoản Admin đang đăng nhập.',
          ),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    final bool? confirmed =
    await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text(
            'Xác nhận xóa',
          ),
          content: Text(
            'Bạn có chắc muốn xóa tài khoản '
                '"${user.username}" không?',
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _databaseHelper.deleteUser(
        user.id!,
      );

      await _loadUsers();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Đã xóa tài khoản thành công.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Không thể xóa tài khoản: $error',
          ),
        ),
      );
    }
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText:
          'Tìm kiếm theo tên tài khoản...',
          prefixIcon: const Icon(
            Icons.search,
          ),
          suffixIcon:
          _searchController.text.isEmpty
              ? null
              : IconButton(
            onPressed: _clearSearch,
            icon: const Icon(
              Icons.clear,
            ),
          ),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final bool isSearching =
        _searchController.text.trim().isNotEmpty;

    return Center(
      child: Text(
        isSearching
            ? 'Không tìm thấy tài khoản phù hợp'
            : 'Chưa có tài khoản nào',
      ),
    );
  }

  Widget _buildUserItem(
      UserModel user,
      ) {
    final bool isCurrentAdmin =
        user.id == widget.currentAdminId;

    final String displayName =
    user.fullName.trim().isEmpty
        ? user.username
        : user.fullName;

    return Card(
      margin: const EdgeInsets.fromLTRB(
        16,
        0,
        16,
        10,
      ),
      child: ListTile(
        leading: _AdminUserAvatar(
          imageUrl: user.avatar,
          fallbackText: displayName,
        ),
        title: Text(
          displayName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          user.username,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Xem thông tin',
              onPressed: () {
                _showUserDetails(user);
              },
              icon: const Icon(
                Icons.visibility,
                color: Colors.blue,
              ),
            ),
            IconButton(
              tooltip: 'Xóa tài khoản',
              onPressed: isCurrentAdmin
                  ? null
                  : () {
                _deleteUser(user);
              },
              icon: Icon(
                Icons.delete,
                color: isCurrentAdmin
                    ? Colors.grey
                    : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? const Center(
              child:
              CircularProgressIndicator(),
            )
                : _filteredUsers.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
              onRefresh: _loadUsers,
              child: ListView.builder(
                padding:
                const EdgeInsets.only(
                  bottom: 16,
                ),
                itemCount:
                _filteredUsers.length,
                itemBuilder: (
                    BuildContext context,
                    int index,
                    ) {
                  final UserModel user =
                  _filteredUsers[index];

                  return _buildUserItem(
                    user,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _AdminUserAvatar extends StatelessWidget {
  final String imageUrl;
  final String fallbackText;
  const _AdminUserAvatar({required this.imageUrl, required this.fallbackText});
  @override
  Widget build(BuildContext context) {
    final url = imageUrl.trim();
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(width: 48, height: 48, child: url.isEmpty ? _fallback() : Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fallback())),
    );
  }
  Widget _fallback() {
    final t = fallbackText.trim().isEmpty ? '?' : fallbackText.trim()[0].toUpperCase();
    return Container(color: const Color(0xFFF3ECFF), alignment: Alignment.center, child: Text(t, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF7B4DB5))));
  }
}
