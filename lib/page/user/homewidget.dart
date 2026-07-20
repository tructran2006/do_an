import 'package:flutter/material.dart';

class HomeWidget extends StatelessWidget {
  const HomeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner chào mừng
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Xin chào! 👋',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                  ),
                  const SizedBox(height: 5),
                  const Text('Hôm nay bạn cần trợ giúp dịch vụ gì nào?'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Tiêu đề mục dịch vụ phổ biến
            const Text(
              'Dịch vụ phổ biến',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Lưới danh sách dịch vụ (Khung sườn)
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildServiceCard(Icons.cleaning_services, 'Dọn dẹp nhà'),
                _buildServiceCard(Icons.electrical_services, 'Sửa điện nước'),
                _buildServiceCard(Icons.format_paint, 'Sơn sửa nhà'),
                _buildServiceCard(Icons.local_laundry_service, 'Giặt ủi quần áo'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(IconData icon, String title) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Xử lý khi nhấn vào dịch vụ (nếu cần)
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.green),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}