import 'package:flutter/material.dart';

import 'package:do_an/data/helper/db_helper.dart';
import 'package:do_an/page/admin/admin_appointments_page.dart';
import 'package:do_an/page/admin/admin_providers_page.dart';
import 'package:do_an/page/admin/admin_services_page.dart';
import 'package:do_an/page/admin/admin_users_page.dart';

class AdminMainPage extends StatefulWidget {
  final int userId;

  const AdminMainPage({
    super.key,
    required this.userId,
  });

  @override
  State<AdminMainPage> createState() => _AdminMainPageState();
}

class _AdminMainPageState extends State<AdminMainPage> {
  int _selectedIndex = 0;
  int _appointmentsReloadKey = 0;

  static const List<String> _pageTitles = [
    'Tổng quan',
    'Quản lý dịch vụ',
    'Quản lý nhân viên',
    'Quản lý lịch hẹn',
    'Quản lý tài khoản',
  ];

  List<Widget> get _adminPages {
    return [
      const AdminDashboardPage(),
      const AdminServicesPage(),
      const AdminProvidersPage(),
      AdminAppointmentsPage(
        key: ValueKey<int>(_appointmentsReloadKey),
      ),
      AdminUsersPage(
        currentAdminId: widget.userId,
      ),
    ];
  }

  void _changePage(int index) {
    if (index < 0 || index >= _adminPages.length) {
      return;
    }

    setState(() {
      _selectedIndex = index;

      // Mỗi lần mở trang Lịch hẹn, tạo lại widget để tải dữ liệu mới.
      if (index == 3) {
        _appointmentsReloadKey++;
      }
    });
  }

  void _changePageFromDrawer(int index) {
    _changePage(index);
    Navigator.pop(context);
  }

  Future<void> _confirmLogout() async {
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.logout_rounded,
                color: Colors.red,
              ),
              SizedBox(width: 10),
              Text('Xác nhận đăng xuất'),
            ],
          ),
          content: const Text(
            'Bạn có chắc chắn muốn đăng xuất khỏi trang quản trị không?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Hủy'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.logout),
              label: const Text('Đăng xuất'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true || !mounted) {
      return;
    }

    Navigator.of(context).pushNamedAndRemoveUntil(
      '/login',
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isWideScreen =
        MediaQuery.sizeOf(context).width >= 1000;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        title: Text(
          _pageTitles[_selectedIndex],
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: !isWideScreen,
        backgroundColor: const Color(0xFF159447),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              tooltip: 'Đăng xuất',
              onPressed: _confirmLogout,
              icon: const Icon(Icons.logout_rounded),
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _adminPages[_selectedIndex],
      // Luôn hiển thị thanh điều hướng dưới, kể cả màn hình rộng.
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return NavigationBar(
      selectedIndex: _selectedIndex,
      indicatorColor: Colors.green.withValues(alpha: 0.15),
      onDestinationSelected: _changePage,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard_rounded),
          label: 'Tổng quan',
        ),
        NavigationDestination(
          icon: Icon(Icons.cleaning_services_outlined),
          selectedIcon: Icon(Icons.cleaning_services_rounded),
          label: 'Dịch vụ',
        ),
        NavigationDestination(
          icon: Icon(Icons.engineering_outlined),
          selectedIcon: Icon(Icons.engineering_rounded),
          label: 'Nhân viên',
        ),
        NavigationDestination(
          icon: Icon(Icons.calendar_month_outlined),
          selectedIcon: Icon(Icons.calendar_month_rounded),
          label: 'Lịch hẹn',
        ),
        NavigationDestination(
          icon: Icon(Icons.people_outline),
          selectedIcon: Icon(Icons.people_rounded),
          label: 'Tài khoản',
        ),
      ],
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      width: 292,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF159447),
                    Color(0xFF0E6E36),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.20),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.home_repair_service_rounded,
                      color: Color(0xFF159447),
                      size: 32,
                    ),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Home Services',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Bảng điều khiển quản trị',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 6, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'ĐIỀU HƯỚNG',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ),
            _buildDrawerItem(
              index: 0,
              icon: Icons.dashboard_outlined,
              selectedIcon: Icons.dashboard_rounded,
              title: 'Tổng quan',
            ),
            _buildDrawerItem(
              index: 1,
              icon: Icons.cleaning_services_outlined,
              selectedIcon: Icons.cleaning_services_rounded,
              title: 'Quản lý dịch vụ',
            ),
            _buildDrawerItem(
              index: 2,
              icon: Icons.engineering_outlined,
              selectedIcon: Icons.engineering_rounded,
              title: 'Quản lý nhân viên',
            ),
            _buildDrawerItem(
              index: 3,
              icon: Icons.calendar_month_outlined,
              selectedIcon: Icons.calendar_month_rounded,
              title: 'Quản lý lịch hẹn',
            ),
            _buildDrawerItem(
              index: 4,
              icon: Icons.people_outline,
              selectedIcon: Icons.people_rounded,
              title: 'Quản lý tài khoản',
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(12),
              child: InkWell(
                onTap: _confirmLogout,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.logout_rounded,
                        color: Colors.red,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Đăng xuất',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String title,
  }) {
    final bool isSelected = _selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 3,
      ),
      child: Material(
        color: isSelected
            ? Colors.green.withValues(alpha: 0.10)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.green.withValues(alpha: 0.14)
                  : Colors.grey.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isSelected ? selectedIcon : icon,
              color: isSelected
                  ? const Color(0xFF159447)
                  : Colors.grey.shade700,
              size: 21,
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              color: isSelected
                  ? const Color(0xFF159447)
                  : Colors.black87,
              fontWeight: isSelected
                  ? FontWeight.w700
                  : FontWeight.w500,
            ),
          ),
          trailing: isSelected
              ? const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF159447),
          )
              : null,
          onTap: () => _changePageFromDrawer(index),
        ),
      ),
    );
  }
}

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() =>
      _AdminDashboardPageState();
}

class _AdminDashboardPageState
    extends State<AdminDashboardPage> {
  late Future<Map<String, dynamic>> _statisticsFuture;

  @override
  void initState() {
    super.initState();
    _statisticsFuture =
        DatabaseHelper().getAdminDashboardStatistics();
  }

  Future<void> _reloadDashboard() async {
    setState(() {
      _statisticsFuture =
          DatabaseHelper().getAdminDashboardStatistics();
    });

    await _statisticsFuture;
  }

  String _formatCurrency(num value) {
    final String number = value.round().toString();
    final StringBuffer result = StringBuffer();

    for (int i = 0; i < number.length; i++) {
      result.write(number[i]);

      final int remaining = number.length - i - 1;

      if (remaining > 0 && remaining % 3 == 0) {
        result.write('.');
      }
    }

    return '${result.toString()} đ';
  }

  int _getColumnCount(double width) {
    if (width >= 1200) {
      return 5;
    }

    if (width >= 850) {
      return 3;
    }

    if (width >= 560) {
      return 2;
    }

    return 1;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _reloadDashboard,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _statisticsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return _DashboardErrorState(
              message: snapshot.error.toString(),
              onRetry: _reloadDashboard,
            );
          }

          final Map<String, dynamic> data =
              snapshot.data ?? <String, dynamic>{};

          final int serviceCount =
              (data['serviceCount'] as num?)?.toInt() ?? 0;
          final int providerCount =
              (data['providerCount'] as num?)?.toInt() ?? 0;
          final int appointmentCount =
              (data['appointmentCount'] as num?)?.toInt() ?? 0;
          final int userCount =
              (data['userCount'] as num?)?.toInt() ?? 0;
          final num revenue =
              data['revenue'] as num? ?? 0;

          return LayoutBuilder(
            builder: (context, constraints) {
              final double contentWidth =
              constraints.maxWidth > 1280
                  ? 1280
                  : constraints.maxWidth;

              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  Center(
                    child: SizedBox(
                      width: contentWidth,
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          _buildWelcomeBanner(
                            serviceCount: serviceCount,
                            appointmentCount:
                            appointmentCount,
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Thống kê hệ thống',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight:
                                        FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                  ],
                                ),
                              ),
                              FilledButton.icon(
                                onPressed: _reloadDashboard,
                                style: FilledButton.styleFrom(
                                  backgroundColor:
                                  const Color(0xFF159447),
                                  foregroundColor: Colors.white,
                                  padding:
                                  const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.refresh_rounded,
                                ),
                                label: const Text('Làm mới'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          GridView.count(
                            crossAxisCount: _getColumnCount(
                              constraints.maxWidth,
                            ),
                            shrinkWrap: true,
                            physics:
                            const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio:
                            constraints.maxWidth < 560
                                ? 2.45
                                : 1.35,
                            children: [
                              AdminStatisticCard(
                                title: 'Dịch vụ',
                                value: serviceCount.toString(),
                                imageUrl: 'https://images.unsplash.com/photo-1581578731548-c64695cc6952',
                                subtitle: 'Dịch vụ đang có',
                                backgroundColor:
                                const Color(0xFFE8F7EE),
                                iconColor:
                                const Color(0xFF159447),
                              ),
                              AdminStatisticCard(
                                title: 'Nhân viên',
                                value: providerCount.toString(),
                                imageUrl: 'https://images.unsplash.com/photo-1621905252507-b35492cc74b4',
                                subtitle: 'Nhân viên hoạt động',
                                backgroundColor:
                                const Color(0xFFEAF2FF),
                                iconColor:
                                const Color(0xFF3578E5),
                              ),
                              AdminStatisticCard(
                                title: 'Lịch hẹn',
                                value:
                                appointmentCount.toString(),
                                imageUrl: 'https://images.unsplash.com/photo-1506784983877-45594efa4cbe',
                                subtitle: 'Lịch hẹn trong hệ thống',
                                backgroundColor:
                                const Color(0xFFFFF3E4),
                                iconColor:
                                const Color(0xFFF28C28),
                              ),
                              AdminStatisticCard(
                                title: 'Người dùng',
                                value: userCount.toString(),
                                imageUrl: 'https://images.unsplash.com/photo-1521737604893-d14cc237f11d',
                                subtitle: 'Tài khoản khách hàng',
                                backgroundColor:
                                const Color(0xFFF3ECFF),
                                iconColor:
                                const Color(0xFF8E5AD7),
                              ),
                              AdminStatisticCard(
                                title: 'Doanh thu dự kiến',
                                value:
                                _formatCurrency(revenue),
                                imageUrl: 'https://images.unsplash.com/photo-1554224155-8d04cb21cd6c',
                                subtitle: 'Tổng giá trị lịch hẹn',
                                backgroundColor:
                                const Color(0xFFFFEDED),
                                iconColor:
                                const Color(0xFFE04A4A),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildWelcomeBanner({
    required int serviceCount,
    required int appointmentCount,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF159447),
            Color(0xFF0B6732),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.20),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Wrap(
        spacing: 20,
        runSpacing: 18,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const SizedBox(
            width: 520,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chào mừng đến trang quản trị',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }



  
    
  
}

class AdminStatisticCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final String imageUrl;
  final Color backgroundColor;
  final Color iconColor;

  const AdminStatisticCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.imageUrl,
    required this.backgroundColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: Colors.grey.withValues(alpha: 0.13),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool horizontal =
                constraints.maxWidth > 320;

            final Widget iconWidget = ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: SizedBox(
                width: 52,
                height: 52,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: backgroundColor,
                    alignment: Alignment.center,
                    child: Text(
                      title.isEmpty ? '?' : title[0].toUpperCase(),
                      style: TextStyle(
                        color: iconColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            );

            final Widget textWidget = Expanded(
              child: Column(
                crossAxisAlignment:
                horizontal
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 7),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: horizontal
                        ? Alignment.centerLeft
                        : Alignment.center,
                    child: Text(
                      value,
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1F2933),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );

            if (horizontal) {
              return Row(
                children: [
                  iconWidget,
                  const SizedBox(width: 14),
                  textWidget,
                ],
              );
            }

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                iconWidget,
                const SizedBox(height: 12),
                textWidget,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DashboardErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _DashboardErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 100),
        const Icon(
          Icons.error_outline_rounded,
          color: Colors.red,
          size: 58,
        ),
        const SizedBox(height: 14),
        const Text(
          'Không thể tải dữ liệu tổng quan',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Tải lại'),
          ),
        ),
      ],
    );
  }
}
