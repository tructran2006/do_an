// import 'package:flutter/material.dart';
// import 'package:do_an/data/helper/db_helper.dart';
// import 'package:do_an/data/model/home_service.dart';
// import 'package:do_an/data/model/user_model.dart';
import 'package:do_an/data/model/provider_model.dart';

// import 'package:do_an/page/user/booking/booking_widget.dart';
// import 'package:do_an/page/user/history/user_appointments.dart';
// import 'package:do_an/page/user/homewidget.dart';
// import 'package:do_an/page/user/user_profile.dart';

// class MainPage extends StatefulWidget {
//   final int userId;
//   final String role;

//   const MainPage({
//     super.key,
//     required this.userId,
//     required this.role,
//   });

//   @override
//   State<MainPage> createState() => _MainPageState();
// }

// class _MainPageState extends State<MainPage> {
//   int _selectedIndex = 0;
//   late Future<UserModel?> _userFuture;

//   @override
//   void initState() {
//     super.initState();
//     _loadUserData();
//   }

//   void _loadUserData() {
//     setState(() {
//       _userFuture = DatabaseHelper().getUserById(widget.userId);
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder<UserModel?>(
//       future: _userFuture,
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const Scaffold(
//             body: Center(child: CircularProgressIndicator(color: Colors.green)),
//           );
//         }

//         final UserModel currentUser = snapshot.data ??
//             UserModel(
//               id: widget.userId,
//               username: 'user_${widget.userId}',
//               password: '',
//               fullName: 'Người dùng',
//               phone: '',
//               role: widget.role,
//               email: '',
//               avatar: '',
//             );

//         final List<Widget> userPages = [
//           const HomeWidget(),
//           BookingWidget(
//             userId: widget.userId,
//             service: HomeServiceModel(id: 0, name: 'Chọn dịch vụ', price: 0),
//           ),
//           UserAppointments(userId: widget.userId),
//           UserProfilePage(
//             user: currentUser,
//             onProfileUpdated: _loadUserData,
//           ),
//         ];

//         return Scaffold(
//           body: IndexedStack(
//             index: _selectedIndex,
//             children: userPages,
//           ),
//           bottomNavigationBar: BottomNavigationBar(
//             currentIndex: _selectedIndex,
//             type: BottomNavigationBarType.fixed,
//             selectedItemColor: Colors.green,
//             unselectedItemColor: Colors.grey,
//             onTap: (index) {
//               setState(() {
//                 _selectedIndex = index;
//               });
//             },
//             items: const [
//               BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
//               BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Đặt lịch'),
//               BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Lịch sử'),
//               BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Tài khoản'),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }
//--------
import 'package:flutter/material.dart';

import 'package:do_an/data/helper/db_helper.dart';
import 'package:do_an/data/model/home_service.dart';
import 'package:do_an/data/model/user_model.dart';

import 'package:do_an/page/user/booking/booking_widget.dart';
import 'package:do_an/page/user/history/user_appointments.dart';
import 'package:do_an/page/user/home/homewidget.dart';
import 'package:do_an/page/user/account/user_profile.dart';

class MainPage extends StatefulWidget {
  final int userId;
  final String role;

  const MainPage({
    super.key,
    required this.userId,
    required this.role,
  });

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  int _historyReloadKey = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late Future<UserModel?> _userFuture;

  // Biến lưu trữ dịch vụ vừa được chọn từ Trang chủ
  HomeServiceModel? _selectedService;
  ProviderModel? _selectedProvider;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Tải lại thông tin người dùng từ CSDL SQLite
  void _loadUserData() {
    setState(() {
      _userFuture = DatabaseHelper().getUserById(widget.userId);
    });
  }

  // Hộp thoại xác nhận đăng xuất
  Future<void> _confirmLogout() async {
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Xác nhận đăng xuất'),
          content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Đăng xuất'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true || !mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
  }

  // Widget tạo từng mục trong Drawer
  Widget _buildDrawerItem({
    required int index,
    required IconData icon,
    required String title,
  }) {
    final bool isSelected = _selectedIndex == index;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Colors.green : Colors.grey[700],
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.green : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Colors.green.withValues(alpha: 0.1),
      onTap: () {
        setState(() {
          _selectedIndex = index;

          // Tạo lại trang Lịch sử mỗi lần người dùng mở tab.
          if (index == 2) {
            _historyReloadKey++;
          }
        });

        Navigator.pop(context); // Đóng Drawer
      },
    );
  }

  // Widget hiển thị Menu Drawer bên trái
  Widget _buildDrawer(UserModel currentUser) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.green,
              ),
              accountName: Text(
                currentUser.fullName.isEmpty ? 'Người dùng' : currentUser.fullName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              accountEmail: Text(
                currentUser.email.isEmpty ? currentUser.username : currentUser.email,
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage: currentUser.avatar.isNotEmpty
                    ? NetworkImage(currentUser.avatar)
                    : null,
                child: currentUser.avatar.isEmpty
                    ? const Icon(
                        Icons.person,
                        color: Colors.green,
                        size: 38,
                      )
                    : null,
              ),
            ),
            _buildDrawerItem(
              index: 0,
              icon: Icons.home,
              title: 'Trang chủ',
            ),
            _buildDrawerItem(
              index: 1,
              icon: Icons.calendar_month,
              title: 'Đặt lịch',
            ),
            _buildDrawerItem(
              index: 2,
              icon: Icons.history,
              title: 'Lịch sử',
            ),
            _buildDrawerItem(
              index: 3,
              icon: Icons.person,
              title: 'Tài khoản',
            ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(
                Icons.logout,
                color: Colors.red,
              ),
              title: const Text(
                'Đăng xuất',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: _confirmLogout,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  List<BottomNavigationBarItem> _buildBottomNavigationItems() {
    return const [
      BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home),
        label: 'Trang chủ',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.calendar_month_outlined),
        activeIcon: Icon(Icons.calendar_month),
        label: 'Đặt lịch',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.history_outlined),
        activeIcon: Icon(Icons.history),
        label: 'Lịch sử',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person),
        label: 'Tài khoản',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final HomeServiceModel defaultService = HomeServiceModel(
      id: 0,
      name: 'Chọn dịch vụ',
      price: 0,
    );

    return FutureBuilder<UserModel?>(
      future: _userFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Colors.green),
            ),
          );
        }

        final UserModel currentUser = snapshot.data ??
            UserModel(
              id: widget.userId,
              username: 'user_${widget.userId}',
              password: '',
              fullName: 'Người dùng',
              phone: '',
              role: widget.role,
              email: '',
              avatar: '',
              address: '',
            );

        // Danh sách màn hình trong ứng dụng
        final List<Widget> userPages = [
          // 1. Trang chủ: Nhận sự kiện chọn dịch vụ để nhảy sang tab Đặt lịch
          HomeWidget(
            onServiceSelected: (service) {
              setState(() {
                _selectedService = service;
                _selectedProvider = null;
                _selectedIndex = 1; // Đổi sang tab Đặt lịch (index = 1)
              });
            },
          onProviderSelected: (service, provider) {
            setState(() {
              _selectedService = service;
              _selectedProvider = provider;
              _selectedIndex = 1;
            });
          },
          ),

          // 2. Trang Đặt lịch: Hiển thị dịch vụ vừa được chọn từ Trang chủ
          BookingWidget(
            userId: widget.userId,
            service: _selectedService ?? defaultService,
            initialProvider: _selectedProvider,
            userAddress: currentUser.address,
            userPhone: currentUser.phone,
          ),

          // 3. Trang Lịch sử cuộc hẹn
          UserAppointments(
            key: ValueKey<int>(_historyReloadKey),
            userId: widget.userId,
          ),

          // 4. Trang Hồ sơ cá nhân
          UserProfilePage(
            user: currentUser,
            onProfileUpdated: _loadUserData,
          ),
        ];

        return Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            title: const Text(
              'Ứng Dụng Dịch Vụ Gia Đình',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.green,
            elevation: 2,
            leading: IconButton(
              icon: const Icon(
                Icons.menu,
                color: Colors.white,
                size: 28,
              ),
              onPressed: () {
                _scaffoldKey.currentState?.openDrawer();
              },
            ),
          ),
          drawer: _buildDrawer(currentUser),
          body: IndexedStack(
            index: _selectedIndex,
            children: userPages,
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Colors.green,
            unselectedItemColor: Colors.grey,
            backgroundColor: Colors.grey.shade50,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;

                // IndexedStack giữ widget cũ, vì vậy tăng key để
                // trang Lịch sử gọi lại initState và tải dữ liệu mới.
                if (index == 2) {
                  _historyReloadKey++;
                }
              });
            },
            items: _buildBottomNavigationItems(),
          ),
        );
      },
    );
  }
}