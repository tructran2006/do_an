import 'package:flutter/material.dart';
import 'package:do_an/data/helper/db_helper.dart';

class UserAppointments extends StatefulWidget {
  final int userId;

  const UserAppointments({super.key, required this.userId});

  @override
  State<UserAppointments> createState() => _UserAppointmentsState();
}

class _UserAppointmentsState extends State<UserAppointments> {
  late Future<List<Map<String, dynamic>>> _appointmentsFuture;

  @override
  void initState() {
    super.initState();
    _refreshAppointments();
  }

  void _refreshAppointments() {
    setState(() {
      _appointmentsFuture = DatabaseHelper().getUserAppointments(widget.userId);
    });
  }

  // Hàm helper cấu hình màu sắc và text cho từng trạng thái đơn hàng
  Map<String, dynamic> _getStatusStyle(String? status) {
    switch (status?.toUpperCase()) {
      case 'ĐANG LÀM':
        return {'text': 'Đang làm', 'color': Colors.blue, 'bgColor': Colors.blue.shade50};
      case 'HOÀN TẤT':
      case 'ĐÃ HOÀN THÀNH':
        return {'text': 'Hoàn tất', 'color': Colors.green, 'bgColor': Colors.green.shade50};
      case 'HỦY ĐƠN':
      case 'ĐÃ HỦY':
        return {'text': 'Đã hủy', 'color': Colors.red, 'bgColor': Colors.red.shade50};
      default:
        return {'text': 'Đang xử lý', 'color': Colors.orange, 'bgColor': Colors.orange.shade50};
    }
  }

  // Hiện Bottom Sheet chi tiết đơn hàng khi ấn vào thẻ
  void _showAppointmentDetails(BuildContext context, Map<String, dynamic> item) {
    final statusStyle = _getStatusStyle(item['status']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 45,
                  height: 5,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Chi tiết lịch hẹn #${item['id']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: statusStyle['bgColor'], borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      statusStyle['text'],
                      style: TextStyle(color: statusStyle['color'], fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  )
                ],
              ),
              const Divider(height: 24),
              _buildDetailRow('Dịch vụ:', item['service_name'] ?? 'Không rõ'),
              _buildDetailRow('Nhân viên phụ trách:', item['provider_name'] ?? 'Hệ thống tự động xếp'),
              _buildDetailRow('Ngày & Giờ đặt:', item['bookdate'] ?? 'Chưa xác định'),
              _buildDetailRow('Địa chỉ làm việc:', item['address'] ?? 'Không có địa chỉ'),
              _buildDetailRow('Chi phí dịch vụ:', '${item['service_price'] ?? 0} VNĐ', isPrice: true),
              _buildDetailRow('Ghi chú khách hàng:', (item['note'] == null || item['note'].toString().isEmpty) ? 'Không có ghi chú' : item['note']),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Đóng chi tiết', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isPrice = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 4, child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 14))),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isPrice ? Colors.green.shade700 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: RefreshIndicator(
        onRefresh: () async => _refreshAppointments(),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _appointmentsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.green));
            }
            if (snapshot.hasError) {
              return Center(child: Text('Đã có lỗi xảy ra: ${snapshot.error}'));
            }
            final list = snapshot.data ?? [];
            if (list.isEmpty) {
              return ListView(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                  const Center(
                    child: Text('Bạn chưa có lịch sử đặt đơn nào.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  ),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final item = list[index];
                final statusStyle = _getStatusStyle(item['status']);

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  elevation: 1.5,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text(
                      item['service_name'] ?? 'Dịch vụ gia đình',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text('Lịch hẹn: ${item['bookdate'] ?? ''}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${item['service_price'] ?? 0} đ',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 14),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: statusStyle['bgColor'], borderRadius: BorderRadius.circular(6)),
                          child: Text(
                            statusStyle['text'],
                            style: TextStyle(color: statusStyle['color'], fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    onTap: () => _showAppointmentDetails(context, item), // Bấm vào để mở thông tin
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}