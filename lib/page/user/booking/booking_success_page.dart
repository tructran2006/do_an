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

  String _formatPrice(double value) {
    final text = value.toInt().toString();
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      final remain = text.length - i - 1;
      if (remain > 0 && remain % 3 == 0) {
        buffer.write('.');
      }
    }

    return '${buffer.toString()} đ';
  }

  Widget _item(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value.isEmpty ? 'Không có' : value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F6F8),
      appBar: AppBar(
        title: const Text('Đặt lịch thành công'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 550),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 42,
                      backgroundColor: Color(0xffE8F5E9),
                      child: Icon(
                        Icons.check_circle,
                        size: 54,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Đặt lịch thành công!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Thông tin lịch hẹn của bạn',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const Divider(height: 32),
                    _item('Dịch vụ', serviceName),
                    _item('Giá', _formatPrice(servicePrice)),
                    _item('Nhân viên', providerName),
                    _item('SĐT', providerPhone),
                    _item('Thời gian', dateTime),
                    _item('Địa chỉ', address),
                    _item('Ghi chú', note),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        },
                        icon: const Icon(Icons.home),
                        label: const Text('Về trang chủ'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
