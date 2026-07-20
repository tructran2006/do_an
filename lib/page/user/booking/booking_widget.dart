import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:do_an/data/helper/db_helper.dart';
import 'package:do_an/data/model/appointment_model.dart';
import 'package:do_an/data/model/home_service.dart'; 
import 'package:do_an/data/model/provider_model.dart'; 
import 'package:do_an/page/user/booking/booking_success_page.dart';

class BookingWidget extends StatefulWidget {
  final HomeServiceModel service; 
  final int userId;

  const BookingWidget({
    super.key,
    required this.service,
    required this.userId,
  });

  @override
  State<BookingWidget> createState() => _BookingWidgetState();
}

class _BookingWidgetState extends State<BookingWidget> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  
  int _selectedDayIndex = 0;
  int? _selectedTimeIndex; 
  bool _isLoading = true;

  // Khởi tạo các mảng dữ liệu lấy từ DB
  List<HomeServiceModel> _services = [];
  List<ProviderModel> _allProviders = [];
  
  // Đối tượng lưu trữ trạng thái người dùng chọn trên UI
  HomeServiceModel? _selectedService;
  ProviderModel? _selectedProvider;

  final List<String> _timeSlots = [
    "08:00 - 10:00",
    "10:00 - 12:00",
    "14:00 - 16:00",
    "16:00 - 18:00",
  ];

  @override
  void initState() {
    super.initState();
    _loadDatabaseData();
  }

  // Thực hiện đọc dữ liệu bất đồng bộ từ các câu lệnh SQL cục bộ
  Future<void> _loadDatabaseData() async {
    try {
      final db = DatabaseHelper();
      final servicesData = await db.getAllServices(); 
      final providersData = await db.getAllProviders();

      setState(() {
        _services = servicesData;
        _allProviders = providersData;
        
        // Tìm và liên kết đúng thực thể dịch vụ truyền vào từ màn hình trước
        if (_services.isNotEmpty) {
          _selectedService = _services.firstWhere(
            (s) => s.id == widget.service.id,
            orElse: () => widget.service,
          );
        } else {
          _selectedService = widget.service;
        }
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải cơ sở dữ liệu: $e')),
        );
      }
    }
  }

  // Kỹ thuật xử lý tập hợp: Tự động lọc danh sách nhân viên theo ID của dịch vụ hiện tại
  List<ProviderModel> get _filteredProviders {
    if (_selectedService == null) return [];
    return _allProviders.where((p) => p.serviceId == _selectedService!.id).toList();
  }

  // Tính tổng tiền động dựa vào thuộc tính price của Dịch vụ được chọn
  double _calculateTotalAmount() {
    if (_selectedService == null) return 0.0;
    return ((_selectedService!.price ?? 0) * 2).toDouble();
  }

  Future<void> _submitBooking(List<DateTime> days, double totalAmount) async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn một dịch vụ!')),
      );
      return;
    }

    if (_selectedProvider == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng lựa chọn nhân viên thực hiện!')),
      );
      return;
    }

    if (_selectedTimeIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn khung giờ làm việc!')),
      );
      return;
    }

    DateTime chosenDate = days[_selectedDayIndex];
    String chosenTime = _timeSlots[_selectedTimeIndex!];
    String appointmentDateTime = "${DateFormat('yyyy-MM-dd').format(chosenDate)} $chosenTime";

    // Khởi tạo Object cấu trúc chuẩn Map để đẩy xuống hàm insertAppointment
    AppointmentModel newAppointment = AppointmentModel(
      userId: widget.userId,
      serviceId: _selectedService!.id ?? 0, 
      bookDate: appointmentDateTime,
      status: 'PENDING',
      address: _addressController.text.trim(),
      note: "${_noteController.text.trim()} (Thợ: ${_selectedProvider!.name} - ${_selectedProvider!.phone})",
    );

    try {
      final db = DatabaseHelper();
      await db.insertAppointment(newAppointment);

      if (mounted) {
        // CẬP NHẬT: Truyền toàn bộ thông tin chi tiết dịch vụ và thợ sang trang Success
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BookingSuccessPage(
              serviceName: _selectedService!.name ?? 'Dịch vụ',
              servicePrice: totalAmount,
              providerName: _selectedProvider!.name,
              providerPhone: _selectedProvider!.phone,
              dateTime: appointmentDateTime,
              address: _addressController.text.trim(),
              note: _noteController.text.trim(),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi lưu lịch đặt: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double totalAmount = _calculateTotalAmount();
    List<DateTime> days = List.generate(7, (i) => DateTime.now().add(Duration(days: i)));

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.green)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Xác nhận đặt lịch', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeading('1. Lựa chọn dịch vụ thực hiện'),
              _buildServiceDropdownSelector(),
              const SizedBox(height: 20),
              
              _buildSectionHeading('2. Lựa chọn nhân viên đảm nhận'),
              _buildProviderSelector(),
              const SizedBox(height: 20),

              _buildSectionHeading('Chọn ngày làm việc'),
              _buildDateSelector(days),
              const SizedBox(height: 20),
              
              _buildSectionHeading('Chọn khung giờ'),
              _buildTimeSelector(),
              const SizedBox(height: 20),
              
              _buildSectionHeading('Địa chỉ thực hiện'),
              _buildAddressInput(),
              const SizedBox(height: 20),
              
              _buildSectionHeading('Ghi chú chi tiết yêu cầu'),
              _buildNoteInput(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomAction(totalAmount, days),
    );
  }

  Widget _buildSectionHeading(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16, 
          fontWeight: FontWeight.bold, 
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildServiceDropdownSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<HomeServiceModel>(
          value: _selectedService,
          isExpanded: true,
          hint: const Text('Chọn dịch vụ cụ thể...'),
          items: _services.map((service) {
            return DropdownMenuItem<HomeServiceModel>(
              value: service,
              child: Text("${service.name ?? 'Dịch vụ'} (${service.price}k/giờ)"),
            );
          }).toList(),
          onChanged: (newService) {
            setState(() {
              _selectedService = newService;
              _selectedProvider = null; // Reset thợ khi dịch vụ thay đổi
            });
          },
        ),
      ),
    );
  }

  Widget _buildProviderSelector() {
    if (_selectedService == null) {
      return const Text(
        'Vui lòng chọn dịch vụ để tìm kiếm thợ.', 
        style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
      );
    }

    final filtered = _filteredProviders;

    if (filtered.isEmpty) {
      return const Text(
        'Không tìm thấy nhân viên nào trống lịch cho dịch vụ này.', 
        style: TextStyle(color: Colors.redAccent, fontStyle: FontStyle.italic),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final provider = filtered[index];
        bool isSelected = _selectedProvider?.id == provider.id;

        return Card(
          color: isSelected ? Colors.green.withValues(alpha: 0.05) : Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: isSelected ? Colors.green : Colors.grey.shade300, 
              width: isSelected ? 2 : 1,
            ),
          ),
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey.shade200,
              backgroundImage: provider.imageUrl.isNotEmpty ? NetworkImage(provider.imageUrl) : null,
              child: provider.imageUrl.isEmpty ? const Icon(Icons.person, color: Colors.green) : null,
            ),
            title: Text(provider.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('SĐT: ${provider.phone} | Phụ phí: ${provider.pricePerHour.toStringAsFixed(0)}k/h'),
            trailing: Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_off,
              color: isSelected ? Colors.green : Colors.grey,
            ),
            onTap: () {
              setState(() {
                _selectedProvider = provider;
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildDateSelector(List<DateTime> days) {
    return SizedBox(
      height: 75,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        itemBuilder: (context, i) {
          bool isSelected = _selectedDayIndex == i;
          return GestureDetector(
            onTap: () => setState(() => _selectedDayIndex = i),
            child: Container(
              width: 65,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: isSelected ? Colors.green : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isSelected ? Colors.green : Colors.grey.shade300),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E').format(days[i]),
                    style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${days[i].day}",
                    style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeSelector() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 3,
      ),
      itemCount: _timeSlots.length,
      itemBuilder: (context, i) {
        bool isSelected = _selectedTimeIndex == i;
        return InkWell(
          onTap: () => setState(() => _selectedTimeIndex = i),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? Colors.green.withValues(alpha: 0.1) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isSelected ? Colors.green : Colors.grey.shade300, width: isSelected ? 2 : 1),
            ),
            child: Center(
              child: Text(
                _timeSlots[i],
                style: TextStyle(color: isSelected ? Colors.green : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddressInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextFormField(
        controller: _addressController,
        maxLines: 2,
        decoration: const InputDecoration(
          hintText: 'Vui lòng nhập địa chỉ cụ thể...',
          contentPadding: EdgeInsets.all(12),
          border: InputBorder.none,
          prefixIcon: Icon(Icons.location_on, color: Colors.green),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Không được bỏ trống địa chỉ thực hiện';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildNoteInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextFormField(
        controller: _noteController,
        maxLines: 3,
        decoration: const InputDecoration(
          hintText: 'Nhập các mô tả yêu cầu công việc chi tiết (nếu có)...',
          contentPadding: EdgeInsets.all(12),
          border: InputBorder.none,
          prefixIcon: Icon(Icons.description, color: Colors.green),
        ),
      ),
    );
  }

  Widget _buildBottomAction(double totalAmount, List<DateTime> days) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05), 
            blurRadius: 5, 
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tổng thanh toán', style: TextStyle(color: Colors.grey, fontSize: 13)),
                Text('${totalAmount.toStringAsFixed(0)}.000đ', style: const TextStyle(color: Colors.green, fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            ElevatedButton(
              onPressed: () => _submitBooking(days, totalAmount),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Đặt lịch ngay', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}