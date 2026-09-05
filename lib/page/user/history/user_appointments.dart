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
  State<UserAppointments> createState() => _UserAppointmentsState();
}

class _UserAppointmentsState extends State<UserAppointments> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  List<Map<String, dynamic>> _appointments = [];

  bool _isLoading = true;
  bool _isCancelling = false;

  DateTime? _selectedDate;
  String _selectedStatus = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final appointments =
          await _databaseHelper.getUserAppointments(widget.userId);

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
        _appointments = [];
        _isLoading = false;
      });

      _showMessage(
        'Không thể tải lịch sử đặt lịch: $error',
        backgroundColor: Colors.red,
      );
    }
  }

  List<Map<String, dynamic>> get _filteredAppointments {
    final result = _appointments.where((appointment) {
      final normalizedStatus = _normalizeStatus(appointment['status']);

      final bool matchesStatus = _selectedStatus == 'ALL' ||
          normalizedStatus == _selectedStatus ||
          (_selectedStatus == 'CANCELLED' && normalizedStatus == 'CANCELED');

      if (!matchesStatus) {
        return false;
      }

      if (_selectedDate == null) {
        return true;
      }

      final appointmentDate = _tryParseDateTime(appointment['bookdate']);

      if (appointmentDate == null) {
        return false;
      }

      return DateUtils.isSameDay(appointmentDate, _selectedDate);
    }).toList();

    result.sort((first, second) {
      final firstDate = _tryParseDateTime(first['bookdate']);
      final secondDate = _tryParseDateTime(second['bookdate']);

      if (firstDate != null && secondDate != null) {
        return secondDate.compareTo(firstDate);
      }

      final firstId = (first['id'] as num?)?.toInt() ?? 0;
      final secondId = (second['id'] as num?)?.toInt() ?? 0;
      return secondId.compareTo(firstId);
    });

    return result;
  }

  DateTime? _tryParseDateTime(dynamic value) {
    final rawValue = value?.toString().trim() ?? '';

    if (rawValue.isEmpty) {
      return null;
    }

    try {
      return DateTime.parse(rawValue);
    } catch (_) {
      return null;
    }
  }

  String _formatPrice(dynamic price) {
    final numValue = num.tryParse(price?.toString() ?? '') ?? 0;
    return '${NumberFormat('#,##0', 'vi_VN').format(numValue)} đ';
  }

  String _formatDateTime(dynamic value) {
    final dateTime = _tryParseDateTime(value);

    if (dateTime == null) {
      final rawValue = value?.toString().trim() ?? '';
      return rawValue.isEmpty ? 'Chưa có thời gian' : rawValue;
    }

    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }

  String _normalizeStatus(dynamic value) {
    final status = value?.toString().trim().toUpperCase() ?? '';
    return status.isEmpty ? 'PENDING' : status;
  }

  String _statusText(dynamic value) {
    switch (_normalizeStatus(value)) {
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
        return 'Chưa cập nhật';
    }
  }

  Color _statusColor(dynamic value) {
    switch (_normalizeStatus(value)) {
      case 'PENDING':
        return Colors.orange.shade700;
      case 'CONFIRMED':
        return Colors.blue.shade700;
      case 'COMPLETED':
        return Colors.green.shade700;
      case 'CANCELLED':
      case 'CANCELED':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  IconData _statusIcon(dynamic value) {
    switch (_normalizeStatus(value)) {
      case 'PENDING':
        return Icons.schedule_rounded;
      case 'CONFIRMED':
        return Icons.event_available_rounded;
      case 'COMPLETED':
        return Icons.task_alt_rounded;
      case 'CANCELLED':
      case 'CANCELED':
        return Icons.event_busy_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  bool _canCancel(Map<String, dynamic> appointment) {
    return _normalizeStatus(appointment['status']) == 'PENDING';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();

    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 3),
      helpText: 'Chọn ngày lịch hẹn',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
    );

    if (!mounted || selected == null) {
      return;
    }

    setState(() {
      _selectedDate = selected;
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedDate = null;
      _selectedStatus = 'ALL';
    });
  }

  Future<void> _cancelAppointment(
    Map<String, dynamic> appointment,
  ) async {
    if (_isCancelling) {
      return;
    }

    if (!_canCancel(appointment)) {
      _showMessage(
        'Chỉ có thể hủy lịch hẹn đang chờ xác nhận.',
        backgroundColor: Colors.orange.shade700,
      );
      return;
    }

    final appointmentId = (appointment['id'] as num?)?.toInt();

    if (appointmentId == null || appointmentId <= 0) {
      _showMessage(
        'Không tìm thấy mã lịch hẹn hợp lệ.',
        backgroundColor: Colors.red,
      );
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.event_busy_outlined, color: Colors.red),
              SizedBox(width: 10),
              Text('Hủy lịch hẹn'),
            ],
          ),
          content: const Text(
            'Bạn có chắc muốn hủy lịch hẹn này không? Lịch đã xác nhận hoặc hoàn thành sẽ không thể hủy từ phía người dùng.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Không'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Hủy lịch'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isCancelling = true;
    });

    try {
      final affectedRows = await _databaseHelper.cancelPendingAppointment(
        appointmentId: appointmentId,
        userId: widget.userId,
      );

      if (!mounted) {
        return;
      }

      if (affectedRows <= 0) {
        await _loadAppointments();

        if (!mounted) {
          return;
        }

        _showMessage(
          'Lịch hẹn không còn ở trạng thái chờ xác nhận nên không thể hủy.',
          backgroundColor: Colors.orange.shade700,
        );
        return;
      }

      await _loadAppointments();

      if (!mounted) {
        return;
      }

      _showMessage(
        'Đã hủy lịch hẹn thành công.',
        backgroundColor: Colors.green.shade700,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Không thể hủy lịch hẹn: $error',
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCancelling = false;
        });
      }
    }
  }

  void _showMessage(
    String message, {
    Color? backgroundColor,
  }) {
    if (!mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

  Future<void> _showAppointmentDetails(
    Map<String, dynamic> appointment,
  ) async {
    final canCancel = _canCancel(appointment);
    final statusColor = _statusColor(appointment['status']);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          titlePadding: EdgeInsets.zero,
          title: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: const BoxDecoration(
              color: Color(0xFF2E7D5B),
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: const Row(
              children: [
                Icon(Icons.receipt_long_outlined, color: Colors.white),
                SizedBox(width: 10),
                Text(
                  'Chi tiết lịch hẹn',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _statusIcon(appointment['status']),
                          size: 20,
                          color: statusColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _statusText(appointment['status']),
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildDetailRow(
                    icon: Icons.home_repair_service_outlined,
                    label: 'Dịch vụ',
                    value: appointment['service_name']?.toString() ?? 'Không có',
                  ),
                  _buildDetailRow(
                    icon: Icons.payments_outlined,
                    label: 'Giá',
                    value: _formatPrice(appointment['service_price']),
                  ),
                  _buildDetailRow(
                    icon: Icons.person_outline_rounded,
                    label: 'Nhân viên',
                    value: appointment['provider_name']?.toString() ?? 'Chưa chọn',
                  ),
                  _buildDetailRow(
                    icon: Icons.phone_outlined,
                    label: 'SĐT nhân viên',
                    value: appointment['provider_phone']?.toString() ?? 'Chưa có',
                  ),
                  _buildDetailRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Thời gian',
                    value: _formatDateTime(appointment['bookdate']),
                  ),
                  _buildDetailRow(
                    icon: Icons.location_on_outlined,
                    label: 'Địa chỉ',
                    value: appointment['address']?.toString().trim().isNotEmpty == true
                        ? appointment['address'].toString()
                        : 'Chưa có',
                  ),
                  _buildDetailRow(
                    icon: Icons.notes_outlined,
                    label: 'Ghi chú',
                    value: appointment['note']?.toString().trim().isNotEmpty == true
                        ? appointment['note'].toString()
                        : 'Không có',
                  ),
                ],
              ),
            ),
          ),
          actions: [
            if (canCancel)
              TextButton.icon(
                onPressed: _isCancelling
                    ? null
                    : () {
                        Navigator.pop(dialogContext);
                        _cancelAppointment(appointment);
                      },
                icon: const Icon(Icons.close_rounded),
                label: const Text('Hủy lịch'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
              ),
            FilledButton.tonal(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5EAE7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: const Color(0xFF527463)),
          const SizedBox(width: 10),
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    final bool hasFilter = _selectedDate != null || _selectedStatus != 'ALL';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4EAE6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.filter_alt_outlined,
                size: 20,
                color: Color(0xFF2E7D5B),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Tìm và lọc lịch hẹn',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              if (hasFilter)
                TextButton(
                  onPressed: _clearFilters,
                  child: const Text('Xóa lọc'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final bool compact = constraints.maxWidth < 500;

              final dateField = _buildDateFilter();
              final statusField = _buildStatusFilter();

              if (compact) {
                return Column(
                  children: [
                    dateField,
                    const SizedBox(height: 10),
                    statusField,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: dateField),
                  const SizedBox(width: 12),
                  Expanded(child: statusField),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilter() {
    final dateLabel = _selectedDate == null
        ? 'Tất cả ngày'
        : DateFormat('dd/MM/yyyy').format(_selectedDate!);

    return InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Ngày hẹn',
          prefixIcon: Icon(Icons.calendar_month_outlined),
          suffixIcon: Icon(Icons.keyboard_arrow_down_rounded),
        ),
        child: Text(
          dateLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildStatusFilter() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedStatus,
      decoration: const InputDecoration(
        labelText: 'Trạng thái',
        prefixIcon: Icon(Icons.tune_rounded),
      ),
      items: const [
        DropdownMenuItem(value: 'ALL', child: Text('Tất cả trạng thái')),
        DropdownMenuItem(value: 'PENDING', child: Text('Chờ xác nhận')),
        DropdownMenuItem(value: 'CONFIRMED', child: Text('Đã xác nhận')),
        DropdownMenuItem(value: 'COMPLETED', child: Text('Hoàn thành')),
        DropdownMenuItem(value: 'CANCELLED', child: Text('Đã hủy')),
      ],
      onChanged: (value) {
        if (value == null) {
          return;
        }

        setState(() {
          _selectedStatus = value;
        });
      },
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    final serviceName = appointment['service_name']?.toString() ?? 'Dịch vụ';
    final providerName =
        appointment['provider_name']?.toString() ?? 'Chưa chọn nhân viên';
    final address = appointment['address']?.toString().trim() ?? '';
    final statusColor = _statusColor(appointment['status']);
    final canCancel = _canCancel(appointment);

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE4EAE6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showAppointmentDetails(appointment),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF5EF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.home_repair_service_outlined,
                      color: Color(0xFF2E7D5B),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          serviceName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _formatDateTime(appointment['bookdate']),
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.11),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _statusIcon(appointment['status']),
                          size: 14,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _statusText(appointment['status']),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildCompactInfo(
                icon: Icons.person_outline,
                text: 'Nhân viên: $providerName',
              ),
              const SizedBox(height: 7),
              _buildCompactInfo(
                icon: Icons.location_on_outlined,
                text: 'Địa chỉ: ${address.isEmpty ? 'Chưa có' : address}',
              ),
              const SizedBox(height: 13),
              const Divider(height: 1),
              const SizedBox(height: 11),
              Row(
                children: [
                  Text(
                    _formatPrice(appointment['service_price']),
                    style: const TextStyle(
                      color: Color(0xFF2E7D5B),
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const Spacer(),
                  if (canCancel) ...[
                    TextButton.icon(
                      onPressed: _isCancelling
                          ? null
                          : () => _cancelAppointment(appointment),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('Hủy lịch'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  TextButton.icon(
                    onPressed: () => _showAppointmentDetails(appointment),
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: const Text('Chi tiết'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF376F57),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactInfo({
    required IconData icon,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: Colors.grey.shade600),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.grey.shade800,
              fontSize: 13.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required bool filtered,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF5EF),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                filtered ? Icons.search_off_rounded : Icons.history_rounded,
                size: 38,
                color: const Color(0xFF4D7B65),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              filtered
                  ? 'Không tìm thấy lịch hẹn phù hợp'
                  : 'Chưa có lịch sử đặt lịch',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              filtered
                  ? 'Hãy thử chọn ngày hoặc trạng thái khác.'
                  : 'Các lịch hẹn của bạn sẽ xuất hiện tại đây.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            if (filtered) ...[
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Xóa bộ lọc'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredAppointments = _filteredAppointments;
    final hasFilter = _selectedDate != null || _selectedStatus != 'ALL';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _loadAppointments,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildFilterSection(),
                  ),
                  if (_appointments.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(filtered: false),
                    )
                  else if (filteredAppointments.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(filtered: hasFilter),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return _buildAppointmentCard(
                            filteredAppointments[index],
                          );
                        },
                        childCount: filteredAppointments.length,
                      ),
                    ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 24),
                  ),
                ],
              ),
            ),
    );
  }
}
