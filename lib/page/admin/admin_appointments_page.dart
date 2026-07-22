import 'package:flutter/material.dart';

import 'package:do_an/data/helper/db_helper.dart';

class AdminAppointmentsPage extends StatefulWidget {
  const AdminAppointmentsPage({
    super.key,
  });

  @override
  State<AdminAppointmentsPage> createState() =>
      _AdminAppointmentsPageState();
}

class _AdminAppointmentsPageState
    extends State<AdminAppointmentsPage> {
  final DatabaseHelper _databaseHelper =
  DatabaseHelper();

  final TextEditingController _searchController =
  TextEditingController();

  List<Map<String, dynamic>> _appointments = [];
  List<Map<String, dynamic>> _filteredAppointments = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _searchController.addListener(
      _filterAppointments,
    );

    _loadAppointments();
  }

  @override
  void dispose() {
    _searchController.removeListener(
      _filterAppointments,
    );

    _searchController.dispose();

    super.dispose();
  }

  Future<void> _loadAppointments() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final List<Map<String, dynamic>> data =
      await _databaseHelper
          .getAdminAppointments();

      if (!mounted) {
        return;
      }

      setState(() {
        _appointments =
        List<Map<String, dynamic>>.from(
          data,
        );

        _isLoading = false;
      });

      _filterAppointments();
    } catch (error, stackTrace) {
      debugPrint(
        'Lỗi tải lịch hẹn Admin: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Không thể tải danh sách lịch hẹn: $error',
          ),
        ),
      );
    }
  }

  void _filterAppointments() {
    final String keyword =
    _searchController.text
        .trim()
        .toLowerCase();

    final List<Map<String, dynamic>> result =
    _appointments.where(
          (Map<String, dynamic> appointment) {
        final String customerName =
            appointment['user_name']
                ?.toString()
                .trim()
                .toLowerCase() ??
                '';

        return keyword.isEmpty ||
            customerName.contains(keyword);
      },
    ).toList();

    // Lịch mới nhất hiển thị trên đầu.
    result.sort(
          (
          Map<String, dynamic> first,
          Map<String, dynamic> second,
          ) {
        final int firstId =
            (first['id'] as num?)?.toInt() ?? 0;

        final int secondId =
            (second['id'] as num?)?.toInt() ?? 0;

        return secondId.compareTo(firstId);
      },
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _filteredAppointments = result;
    });
  }

  void _clearSearch() {
    _searchController.clear();
  }

  String _normalizeStatus(dynamic value) {
    final String status =
        value?.toString().trim().toUpperCase() ??
            '';

    if (status.isEmpty) {
      return 'PENDING';
    }

    return status;
  }

  String _statusText(dynamic value) {
    switch (_normalizeStatus(value)) {
      case 'CONFIRMED':
        return 'Đã xác nhận';

      case 'COMPLETED':
        return 'Hoàn thành';

      case 'CANCELLED':
      case 'CANCELED':
        return 'Đã hủy';

      case 'PENDING':
      default:
        return 'Chờ xác nhận';
    }
  }

  Color _statusColor(dynamic value) {
    switch (_normalizeStatus(value)) {
      case 'CONFIRMED':
        return Colors.blue;

      case 'COMPLETED':
        return Colors.green;

      case 'CANCELLED':
      case 'CANCELED':
        return Colors.red;

      case 'PENDING':
      default:
        return Colors.orange;
    }
  }

  Future<void> _updateStatus({
    required Map<String, dynamic> appointment,
    required String status,
  }) async {
    final int? appointmentId =
    (appointment['id'] as num?)?.toInt();

    if (appointmentId == null ||
        appointmentId <= 0) {
      _showMessage(
        'Không tìm thấy mã lịch hẹn.',
      );

      return;
    }

    try {
      await _databaseHelper
          .updateAppointmentStatus(
        appointmentId: appointmentId,
        status: status,
      );

      await _loadAppointments();

      if (!mounted) {
        return;
      }

      _showMessage(
        'Cập nhật trạng thái thành công.',
        backgroundColor: Colors.green,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Không thể cập nhật trạng thái: $error',
      );
    }
  }

  Future<void> _showAppointmentDetails(
      Map<String, dynamic> appointment,
      ) async {
    await showDialog<void>(
      context: context,
      builder: (
          BuildContext dialogContext,
          ) {
        return AlertDialog(
          title: const Text(
            'Chi tiết lịch hẹn',
          ),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize:
                MainAxisSize.min,
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(
                    label: 'Khách hàng',
                    value: _textOrDefault(
                      appointment['user_name'],
                      'Không rõ',
                    ),
                  ),
                  _buildDetailRow(
                    label: 'Số điện thoại',
                    value: _textOrDefault(
                      appointment['user_phone'],
                      'Chưa có',
                    ),
                  ),
                  _buildDetailRow(
                    label: 'Dịch vụ',
                    value: _textOrDefault(
                      appointment['service_name'],
                      'Không rõ',
                    ),
                  ),
                  _buildDetailRow(
                    label: 'Nhân viên',
                    value: _textOrDefault(
                      appointment['provider_name'],
                      'Chưa phân công',
                    ),
                  ),
                  _buildDetailRow(
                    label: 'SĐT nhân viên',
                    value: _textOrDefault(
                      appointment['provider_phone'],
                      'Chưa có',
                    ),
                  ),
                  _buildDetailRow(
                    label: 'Ngày giờ',
                    value: _textOrDefault(
                      appointment['bookdate'],
                      'Chưa có',
                    ),
                  ),
                  _buildDetailRow(
                    label: 'Địa chỉ',
                    value: _textOrDefault(
                      appointment['address'],
                      'Chưa có',
                    ),
                  ),
                  _buildDetailRow(
                    label: 'Ghi chú',
                    value: _textOrDefault(
                      appointment['note'],
                      'Không có',
                    ),
                  ),
                  _buildDetailRow(
                    label: 'Trạng thái',
                    value: _statusText(
                      appointment['status'],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  String _textOrDefault(
      dynamic value,
      String defaultValue,
      ) {
    final String text =
        value?.toString().trim() ?? '';

    return text.isEmpty ? defaultValue : text;
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
  }) {
    return Padding(
      padding:
      const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
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

  void _showMessage(
      String message, {
        Color? backgroundColor,
      }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding:
      const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller:
              _searchController,
              decoration:
              InputDecoration(
                hintText:
                'Tìm theo tên khách hàng...',
                prefixIcon:
                const Icon(Icons.search),
                suffixIcon:
                _searchController
                    .text
                    .isEmpty
                    ? null
                    : IconButton(
                  tooltip:
                  'Xóa tìm kiếm',
                  onPressed:
                  _clearSearch,
                  icon:
                  const Icon(
                    Icons.clear,
                  ),
                ),
                border:
                const OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Làm mới dữ liệu',
            onPressed: _loadAppointments,
            icon: const Icon(
              Icons.refresh,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final bool isSearching =
        _searchController.text
            .trim()
            .isNotEmpty;

    return Center(
      child: Text(
        isSearching
            ? 'Không tìm thấy lịch hẹn phù hợp'
            : 'Chưa có lịch hẹn nào',
      ),
    );
  }

  Widget _buildAppointmentCard(
      Map<String, dynamic> appointment,
      ) {
    final Color statusColor =
    _statusColor(
      appointment['status'],
    );

    final String customerName =
    _textOrDefault(
      appointment['user_name'],
      'Không rõ khách hàng',
    );

    final String serviceName =
    _textOrDefault(
      appointment['service_name'],
      'Không rõ dịch vụ',
    );

    final String providerName =
    _textOrDefault(
      appointment['provider_name'],
      'Chưa phân công',
    );

    final String bookDate =
    _textOrDefault(
      appointment['bookdate'],
      'Chưa có',
    );

    final String address =
    _textOrDefault(
      appointment['address'],
      'Chưa có',
    );

    return Card(
      margin:
      const EdgeInsets.fromLTRB(
        16,
        0,
        16,
        10,
      ),
      child: InkWell(
        onTap: () {
          _showAppointmentDetails(
            appointment,
          );
        },
        child: Padding(
          padding:
          const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                backgroundColor:
                Color(0xFFE8F5E9),
                child: Icon(
                  Icons.calendar_month,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      customerName,
                      style:
                      const TextStyle(
                        fontSize: 16,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'Dịch vụ: $serviceName',
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Nhân viên: $providerName',
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Ngày: $bookDate',
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Địa chỉ: $address',
                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                tooltip:
                'Cập nhật trạng thái',
                onSelected:
                    (String status) {
                  _updateStatus(
                    appointment:
                    appointment,
                    status: status,
                  );
                },
                itemBuilder:
                    (BuildContext context) {
                  return const [
                    PopupMenuItem<String>(
                      value: 'PENDING',
                      child:
                      Text('Chờ xác nhận'),
                    ),
                    PopupMenuItem<String>(
                      value: 'CONFIRMED',
                      child:
                      Text('Đã xác nhận'),
                    ),
                    PopupMenuItem<String>(
                      value: 'COMPLETED',
                      child:
                      Text('Hoàn thành'),
                    ),
                    PopupMenuItem<String>(
                      value: 'CANCELLED',
                      child:
                      Text('Đã hủy'),
                    ),
                  ];
                },
                child: Chip(
                  backgroundColor:
                  statusColor.withValues(
                    alpha: 0.14,
                  ),
                  label: Text(
                    _statusText(
                      appointment['status'],
                    ),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(
      BuildContext context,
      ) {
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
                : _filteredAppointments.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
              onRefresh:
              _loadAppointments,
              child:
              ListView.builder(
                physics:
                const AlwaysScrollableScrollPhysics(),
                padding:
                const EdgeInsets.only(
                  bottom: 20,
                ),
                itemCount:
                _filteredAppointments.length,
                itemBuilder: (
                    BuildContext context,
                    int index,
                    ) {
                  return _buildAppointmentCard(
                    _filteredAppointments[
                    index],
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
