import 'package:flutter/material.dart';
import 'package:do_an/page/user/booking/booking_widget.dart'; 
import 'package:do_an/data/model/home_service.dart';
import 'package:do_an/page/user/homewidget.dart'; 
import 'package:do_an/page/user/history/user_appointments.dart'; 
import 'package:do_an/page/user/user_profile.dart'; 
import 'package:do_an/data/model/user_model.dart'; 

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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // FIX TẠI ĐÂY: Khởi tạo trực tiếp hàm callback ngay khi khai báo biến để tránh lỗi LateInitializationError
  late final Future<UserModel?> _userDataFuture = _getUserData();

  // Trả về null nếu chưa có dữ liệu thực tế
  Future<UserModel?> _getUserData() async {
    // Sau này bạn gọi DatabaseHelper ở đây, ví dụ:
    // return await DatabaseHelper.instance.getUserById(widget.userId);
    return null; 
  }

  @override
  void initState() {
    super.initState();
    // Không cần gán _userDataFuture ở đây nữa để tránh xung đột vòng đời (lifecycle)
  }

  List<BottomNavigationBarItem> _buildUserBottomItems() {
    return const [
      BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Trang chủ'),
      BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), activeIcon: Icon(Icons.calendar_month), label: 'Đặt lịch'),
      BottomNavigationBarItem(icon: Icon(Icons.history_outlined), activeIcon: Icon(Icons.history), label: 'Lịch sử'),
      BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Tài khoản'),
    ];
  }

  List<BottomNavigationBarItem> _buildAdminBottomItems() {
    return const [
      BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Tổng quan'),
      BottomNavigationBarItem(icon: Icon(Icons.cleaning_services_outlined), activeIcon: Icon(Icons.cleaning_services), label: 'Dịch vụ'),
      BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Tài khoản'),
    ];
  }

  List<Widget> _buildUserNavItems() {
    return [
      _buildDrawerTile(0, Icons.home, 'Trang chủ'),
      _buildDrawerTile(1, Icons.calendar_month, 'Đặt lịch'),
      _buildDrawerTile(2, Icons.history, 'Lịch sử'),
      _buildDrawerTile(3, Icons.person, 'Tài khoản'),
    ];
  }

  List<Widget> _buildAdminNavItems() {
    return [
      _buildDrawerTile(0, Icons.dashboard, 'Tổng quan'),
      _buildDrawerTile(1, Icons.cleaning_services, 'Dịch vụ'),
      _buildDrawerTile(2, Icons.person, 'Tài khoản'),
    ];
  }

  Widget _buildDrawerTile(int index, IconData icon, String title) {
    bool isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.green : Colors.grey),
      title: Text(
        title, 
        style: TextStyle(
          color: isSelected ? Colors.green : Colors.black87, 
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
        ),
      ),
      selected: isSelected,
      selectedTileColor: Colors.green.withValues(alpha: 0.1),
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = widget.role == 'ADMIN';

    final defaultService = HomeServiceModel(
      id: 0,
      name: 'Chọn dịch vụ',
      price: 0,
    );

    return FutureBuilder<UserModel?>(
      future: _userDataFuture,
      builder: (context, snapshot) {
        // Khởi tạo UserModel mặc định nếu snapshot trả về null hoặc đang loading
        final UserModel currentUser = snapshot.data ?? UserModel(
          id: widget.userId,
          username: 'guest_${widget.userId}',
          password: '',
          fullName: 'Người dùng',
          phone: '',
          role: widget.role,
          email: 'chua_co_email@domain.com',
          avatar: '',
        );

        final List<Widget> userScreens = [
          const HomeWidget(), 
          BookingWidget(      
            userId: widget.userId,
            service: defaultService,
          ),
          UserAppointments(userId: widget.userId), 
          UserProfile(user: currentUser),     
        ];

        final List<Widget> adminScreens = [
          const SizedBox.shrink(), 
          const SizedBox.shrink(),
          const SizedBox.shrink(),
        ];

        final List<Widget> currentScreens = isAdmin ? adminScreens : userScreens;

        return Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            title: const Text(
              'Ứng dụng dịch vụ gia đình',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
            ),
            backgroundColor: Colors.green,
            centerTitle: true,
            elevation: 2,
            leading: IconButton(
              icon: const Icon(Icons.menu, color: Colors.white, size: 28), 
              onPressed: () {
                _scaffoldKey.currentState?.openDrawer(); 
              },
            ),
          ),
          drawer: Drawer(
            child: Column(
              children: [
                UserAccountsDrawerHeader(
                  decoration: const BoxDecoration(color: Colors.green),
                  accountName: Text(
                    currentUser.fullName.isEmpty ? 'Chưa cập nhật' : currentUser.fullName, 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  accountEmail: Text(currentUser.email.isEmpty ? 'Chưa cập nhật email' : currentUser.email),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: Colors.white,
                    backgroundImage: currentUser.avatar.isNotEmpty ? NetworkImage(currentUser.avatar) : null,
                    child: currentUser.avatar.isEmpty
                        ? Icon(isAdmin ? Icons.admin_panel_settings : Icons.person, color: Colors.green, size: 35)
                        : null,
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: isAdmin ? _buildAdminNavItems() : _buildUserNavItems(),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Đăng xuất', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          body: IndexedStack(
            index: _selectedIndex,
            children: currentScreens,
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Colors.green,
            unselectedItemColor: Colors.grey,
            backgroundColor: Colors.grey.shade50,
            items: isAdmin ? _buildAdminBottomItems() : _buildUserBottomItems(),
          ),
        );
      },
    );
  }
}