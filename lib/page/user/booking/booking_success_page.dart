import 'package:flutter/material.dart';

class BookingSuccessPage extends StatelessWidget {
  final String serviceName;
  final double servicePrice;
  final String providerName;
  final String providerPhone;
  final String dateTime;
  final String address;
  final String note;

  const BookingSuccessPage({
    super.key,
    required this.serviceName,
    required this.servicePrice,
    required this.providerName,
    required this.providerPhone,
    required this.dateTime,
    required this.address,
    required this.note,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Đặt lịch thành công', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        centerTitle: true,
        automaticallyImplyLeading: false, // Ẩn nút back để user không quay lại form cũ
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Icon thành công hiệu ứng hoạt họa đơn giản
            const CircleAvatar(
              radius: 40,
              backgroundColor: Color(0xFFE8F5E9),
              child: Icon(Icons.check_circle, color: Colors.green, size: 60),
            ),
            const SizedBox(height: 16),
            const Text(
              'Cảm ơn bạn!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              'Lịch hẹn của bạn đã được ghi nhận và đang chờ duyệt.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 30),

            // Card chi tiết thông tin dịch vụ đã đặt
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Chi tiết dịch vụ đã đặt',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                  const Divider(height: 24, thickness: 1),
                  
                  _buildDetailRow(Icons.cleaning_services, 'Dịch vụ:', serviceName, isBoldText: true),
                  _buildDetailRow(Icons.person, 'Nhân viên đảm nhận:', providerName),
                  _buildDetailRow(Icons.phone, 'SĐT nhân viên:', providerPhone),
                  _buildDetailRow(Icons.calendar_month, 'Thời gian làm việc:', dateTime),
                  _buildDetailRow(Icons.location_on, 'Địa chỉ:', address),
                  
                  if (note.isNotEmpty)
                    _buildDetailRow(Icons.note, 'Ghi chú của bạn:', note),

                  const Divider(height: 24, thickness: 1),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tổng thanh toán:',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      Text(
                        '${servicePrice.toStringAsFixed(0)}.000đ',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Nút điều hướng quay lại màn hình chính
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  // Quay thẳng về màn hình đầu tiên (MainPage) và xóa các stack cũ
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Quay về trang chủ',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget phụ để hiển thị từng dòng thông tin có căn chỉnh icon đẹp mắt
  Widget _buildDetailRow(IconData icon, String label, String value, {bool isBoldText = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.3),
                children: [
                  TextSpan(text: '$label ', style: const TextStyle(color: Colors.grey)),
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      fontWeight: isBoldText ? FontWeight.bold : FontWeight.normal,
                      color: isBoldText ? Colors.green.shade700 : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}