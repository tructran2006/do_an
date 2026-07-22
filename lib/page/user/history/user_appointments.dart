import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:do_an/data/helper/db_helper.dart';

class UserAppointments extends StatefulWidget {
  final int userId;

  const UserAppointments({
    super.key,
    required this.userId,
  });

  @override
  State<UserAppointments> createState() =>
      _UserAppointmentsState();
}

class _UserAppointmentsState
    extends State<UserAppointments> {
  final DatabaseHelper _databaseHelper =
  DatabaseHelper();

  List<Map<String, dynamic>> _appointments = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final List<Map<String, dynamic>> appointments =
      await _databaseHelper.getUserAppointments(
        widget.userId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _appointments = appointments;
        _isLoading = false;
      });
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
            'Không thể tải lịch sử đặt lịch: $error',
          ),
        ),
      );
    }
  }

  String _formatPrice(dynamic price) {
    final int value =
        int.tryParse(price.toString()) ?? 0;

    final String text = value.toString();
    final StringBuffer result = StringBuffer();

    for (int index = 0;
    index < text.length;
    index++) {
      result.write(text[index]);

      final int remaining =
          text.length - index - 1;

      if (remaining > 0 &&
          remaining % 3 == 0) {
        result.write('.');
      }
    }

    return '${result.toString()} đ';
  }

  String _formatDateTime(dynamic value) {
    final String rawValue =
        value?.toString() ?? '';

    if (rawValue.isEmpty) {
      return 'Chưa có thời gian';
    }

    try {
      final DateTime dateTime =
      DateTime.parse(rawValue);

      return DateFormat(
        'dd/MM/yyyy HH:mm',
      ).format(dateTime);
    } catch (_) {
      return rawValue;
    }
  }

  String _statusText(dynamic value) {
    final String status =
        value?.toString().trim().toUpperCase() ??
            '';

    switch (status) {
      case 'PENDING':
        return 'Chờ xác nhận';

      case 'CONFIRMED':
        return 'Đã xác nhận';

      case 'COMPLETED':
        return 'Hoàn thành';

      case 'CANCELLED':
      case 'CANCELED':
        return 'Đã hủy';

      default:
        return status.isEmpty
            ? 'Chưa cập nhật'
            : status;
    }
  }

  Color _statusColor(dynamic value) {
    final String status =
        value?.toString().trim().toUpperCase() ??
            '';

    switch (status) {
      case 'PENDING':
        return Colors.orange;

      case 'CONFIRMED':
        return Colors.blue;

      case 'COMPLETED':
        return Colors.green;

      case 'CANCELLED':
      case 'CANCELED':
        return Colors.red;

      default:
        return Colors.grey;
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
            width: 430,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize:
                MainAxisSize.min,
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(
                    label: 'Dịch vụ',
                    value: appointment[
                    'service_name']
                        ?.toString() ??
                        'Không có',
                  ),
                  _buildDetailRow(
                    label: 'Giá',
                    value: _formatPrice(
                      appointment[
                      'service_price'],
                    ),
                  ),
                  _buildDetailRow(
                    label: 'Nhân viên',
                    value: appointment[
                    'provider_name']
                        ?.toString() ??
                        'Chưa chọn',
                  ),
                  _buildDetailRow(
                    label: 'SĐT nhân viên',
                    value: appointment[
                    'provider_phone']
                        ?.toString() ??
                        'Chưa có',
                  ),
                  _buildDetailRow(
                    label: 'Thời gian',
                    value: _formatDateTime(
                      appointment['bookdate'],
                    ),
                  ),
                  _buildDetailRow(
                    label: 'Địa chỉ',
                    value: appointment['address']
                        ?.toString()
                        .trim()
                        .isNotEmpty ==
                        true
                        ? appointment['address']
                        .toString()
                        : 'Chưa có',
                  ),
                  _buildDetailRow(
                    label: 'Ghi chú',
                    value: appointment['note']
                        ?.toString()
                        .trim()
                        .isNotEmpty ==
                        true
                        ? appointment['note']
                        .toString()
                        : 'Không có',
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

  Widget _buildDetailRow({
    required String label,
    required String value,
  }) {
    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 12,
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
                fontWeight:
                FontWeight.bold,
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

  Widget _buildAppointmentCard(
      Map<String, dynamic> appointment,
      ) {
    final String serviceName =
        appointment['service_name']
            ?.toString() ??
            'Dịch vụ';

    final String providerName =
        appointment['provider_name']
            ?.toString() ??
            'Chưa chọn nhân viên';

    final Color statusColor =
    _statusColor(
      appointment['status'],
    );

    return Card(
      margin:
      const EdgeInsets.fromLTRB(
        16,
        0,
        16,
        12,
      ),
      elevation: 1,
      child: InkWell(
        onTap: () {
          _showAppointmentDetails(
            appointment,
          );
        },
        child: Padding(
          padding:
          const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor:
                    Color(0xFFE8F5E9),
                    child: Icon(
                      Icons
                          .home_repair_service,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      serviceName,
                      style:
                      const TextStyle(
                        fontSize: 16,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                    const EdgeInsets
                        .symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration:
                    BoxDecoration(
                      color: statusColor
                          .withValues(
                        alpha: 0.12,
                      ),
                      borderRadius:
                      BorderRadius
                          .circular(8),
                    ),
                    child: Text(
                      _statusText(
                        appointment['status'],
                      ),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Nhân viên: $providerName',
              ),
              const SizedBox(height: 5),
              Text(
                'Thời gian: ${_formatDateTime(appointment['bookdate'])}',
              ),
              const SizedBox(height: 5),
              Text(
                'Địa chỉ: ${appointment['address']?.toString() ?? 'Chưa có'}',
                maxLines: 2,
                overflow:
                TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    _formatPrice(
                      appointment[
                      'service_price'],
                    ),
                    style:
                    const TextStyle(
                      color: Colors.green,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Xem chi tiết',
                    style: TextStyle(
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: Colors.blue,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding:
        const EdgeInsets.all(24),
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color:
              Colors.grey.shade400,
            ),
            const SizedBox(height: 14),
            const Text(
              'Chưa có lịch sử đặt lịch',
              style: TextStyle(
                fontSize: 18,
                fontWeight:
                FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Các lịch hẹn của bạn sẽ xuất hiện tại đây.',
              textAlign:
              TextAlign.center,
              style: TextStyle(
                color:
                Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F6F8),
      body: _isLoading
          ? const Center(
        child:
        CircularProgressIndicator(),
      )
          : _appointments.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
        onRefresh:
        _loadAppointments,
        child:
        ListView.builder(
          padding:
          const EdgeInsets
              .only(
            top: 16,
            bottom: 24,
          ),
          itemCount:
          _appointments.length,
          itemBuilder: (
              BuildContext context,
              int index,
              ) {
            return _buildAppointmentCard(
              _appointments[index],
            );
          },
        ),
      ),
    );
  }
}
