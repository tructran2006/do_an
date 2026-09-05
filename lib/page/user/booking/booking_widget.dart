import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:do_an/data/helper/db_helper.dart';
import 'package:do_an/data/model/appointment_model.dart';
import 'package:do_an/data/model/home_service.dart';
import 'package:do_an/data/model/provider_model.dart';
import 'package:do_an/data/model/service_category.dart';
import 'package:do_an/page/user/booking/booking_success_page.dart';
import 'package:do_an/core/app_validators.dart';

class BookingWidget extends StatefulWidget {
  final HomeServiceModel service;
  final int userId;
  final String userAddress;
  final String userPhone;
  final ProviderModel? initialProvider;

  const BookingWidget({
    super.key,
    required this.service,
    required this.userId,
    this.userAddress = '',
    this.userPhone = '',
    this.initialProvider,
  });

  @override
  State<BookingWidget> createState() =>
      _BookingWidgetState();
}

class _BookingWidgetState extends State<BookingWidget> {
  final DatabaseHelper _databaseHelper =
  DatabaseHelper();

  final GlobalKey<FormState> _formKey =
  GlobalKey<FormState>();

  final TextEditingController _addressController =
  TextEditingController();

  final TextEditingController _phoneController =
  TextEditingController();

  final TextEditingController _noteController =
  TextEditingController();

  List<ServiceCategoryModel> _categories = [];
  List<HomeServiceModel> _services = [];
  List<ProviderModel> _providers = [];

  HomeServiceModel? _selectedService;
  ServiceCategoryModel? _selectedCategory;
  ProviderModel? _selectedProvider;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _addressController.text = widget.userAddress.trim();
    _phoneController.text = widget.userPhone.trim();
    _loadData();
  }

  @override
  void didUpdateWidget(
      covariant BookingWidget oldWidget,
      ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.userAddress != widget.userAddress && _addressController.text.trim().isEmpty) {
      _addressController.text = widget.userAddress.trim();
    }
    if (oldWidget.userPhone != widget.userPhone && _phoneController.text.trim().isEmpty) {
      _phoneController.text = widget.userPhone.trim();
    }

    if (oldWidget.service.id != widget.service.id ||
        oldWidget.initialProvider?.id != widget.initialProvider?.id) {
      _selectServiceFromOutside();
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final List<ServiceCategoryModel> categories =
      await _databaseHelper.getAllCategories();

      final List<HomeServiceModel> services =
      await _databaseHelper.getAllServices();

      final List<ProviderModel> providers =
      await _databaseHelper.getAllProviders();

      services.sort(
            (
            HomeServiceModel first,
            HomeServiceModel second,
            ) {
          final String firstName =
              first.name?.trim().toLowerCase() ?? '';

          final String secondName =
              second.name?.trim().toLowerCase() ?? '';

          return firstName.compareTo(secondName);
        },
      );

      providers.sort(
            (
            ProviderModel first,
            ProviderModel second,
            ) {
          return first.name
              .trim()
              .toLowerCase()
              .compareTo(
            second.name.trim().toLowerCase(),
          );
        },
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _categories = categories;
        _services = services;
        _providers = providers;
        _isLoading = false;
      });

      _selectServiceFromOutside();
    } catch (error, stackTrace) {
      debugPrint(
        'Lỗi tải dữ liệu đặt lịch: $error',
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

      _showMessage(
        'Không thể tải dữ liệu đặt lịch: $error',
      );
    }
  }

  void _selectServiceFromOutside() {
    final int? externalServiceId =
        widget.service.id;

    if (_services.isEmpty ||
        externalServiceId == null ||
        externalServiceId <= 0) {
      return;
    }

    HomeServiceModel? matchedService;

    for (final HomeServiceModel service in _services) {
      if (service.id == externalServiceId) {
        matchedService = service;
        break;
      }
    }

    if (matchedService == null || !mounted) {
      return;
    }

    setState(() {
      _selectedService = matchedService;
      _selectedCategory =
          _findCategory(matchedService!.catId);
      _selectedProvider = _findProvider(widget.initialProvider?.id, matchedService.id);
    });
  }


  ProviderModel? _findProvider(int? providerId, int? serviceId) {
    if (providerId == null || serviceId == null) return null;
    for (final provider in _providers) {
      if (provider.id == providerId && provider.serviceId == serviceId) {
        return provider;
      }
    }
    return null;
  }

  ServiceCategoryModel? _findCategory(
      int? categoryId,
      ) {
    if (categoryId == null) {
      return null;
    }

    for (final ServiceCategoryModel category
    in _categories) {
      if (category.id == categoryId) {
        return category;
      }
    }

    return null;
  }

  void _onServiceChanged(
      HomeServiceModel? service,
      ) {
    setState(() {
      _selectedService = service;
      _selectedCategory =
          _findCategory(service?.catId);
      _selectedProvider = null;
    });
  }

  List<ProviderModel> get _availableProviders {
    final int? serviceId = _selectedService?.id;

    if (serviceId == null || serviceId <= 0) {
      return [];
    }

    return _providers.where(
          (ProviderModel provider) {
        return provider.serviceId == serviceId;
      },
    ).toList();
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();

    final DateTime? pickedDate =
    await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(
        now.year,
        now.month,
        now.day,
      ),
      lastDate: now.add(
        const Duration(days: 90),
      ),
    );

    if (pickedDate == null || !mounted) {
      return;
    }

    setState(() {
      _selectedDate = pickedDate;
    });
  }

  Future<void> _pickTime() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      helpText: 'CHỌN GIỜ THỰC HIỆN',
      cancelText: 'HỦY',
      confirmText: 'CHỌN',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              hourMinuteShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              dayPeriodShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime == null || !mounted) {
      return;
    }

    setState(() {
      _selectedTime = pickedTime;
    });
  }

  DateTime? _getAppointmentDateTime() {
    final DateTime? date = _selectedDate;
    final TimeOfDay? time = _selectedTime;

    if (date == null || time == null) {
      return null;
    }

    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  String _formatPrice(int? price) {
    final int value = price ?? 0;
    final String digits = value.toString();
    final StringBuffer result = StringBuffer();

    for (int index = 0;
    index < digits.length;
    index++) {
      result.write(digits[index]);

      final int remaining =
          digits.length - index - 1;

      if (remaining > 0 &&
          remaining % 3 == 0) {
        result.write('.');
      }
    }

    return '${result.toString()} đ';
  }

  Future<void> _submitBooking() async {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState?.validate() != true) {
      return;
    }

    final HomeServiceModel? service =
        _selectedService;

    final ProviderModel? provider =
        _selectedProvider;

    final int? serviceId = service?.id;
    final int? providerId = provider?.id;

    if (service == null ||
        serviceId == null ||
        serviceId <= 0) {
      _showMessage(
        'Vui lòng chọn dịch vụ hợp lệ.',
      );
      return;
    }

    if (_selectedCategory == null) {
      _showMessage(
        'Dịch vụ chưa có danh mục hợp lệ.',
      );
      return;
    }

    if (provider == null ||
        providerId == null ||
        providerId <= 0) {
      _showMessage(
        'Vui lòng chọn nhân viên hợp lệ.',
      );
      return;
    }

    final DateTime? appointmentDateTime =
    _getAppointmentDateTime();

    if (appointmentDateTime == null) {
      _showMessage(
        'Vui lòng chọn ngày và giờ.',
      );
      return;
    }

    if (!appointmentDateTime
        .isAfter(DateTime.now())) {
      _showMessage(
        'Thời gian đặt lịch phải lớn hơn thời gian hiện tại.',
      );
      return;
    }

    final String address =
    _addressController.text.trim();

    final String phone = _phoneController.text.replaceAll(' ', '').trim();

    final String note =
    _noteController.text.trim();

    final String bookDate = DateFormat('yyyy-MM-dd HH:mm').format(appointmentDateTime);
    final bool occupied = await _databaseHelper.providerHasAppointmentAt(
      providerId: providerId,
      bookDate: bookDate,
    );
    if (!mounted) return;
    if (occupied) {
      _showMessage('Nhân viên đã có lịch vào thời gian này. Vui lòng chọn giờ khác.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final AppointmentModel appointment =
      AppointmentModel(
        userId: widget.userId,
        serviceId: serviceId,
        providerId: providerId,
        bookDate: bookDate,
        address: address,
        phone: phone,
        note: note,
        status: 'PENDING',
      );

      await _databaseHelper.insertAppointment(
        appointment,
      );

      if (!mounted) {
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (
              BuildContext context,
              ) {
            return BookingSuccessPage(
              serviceName:
              service.name ?? 'Dịch vụ',
              servicePrice:
              (service.price ?? 0).toDouble(),
              providerName: provider.name,
              providerPhone: provider.phone,
              dateTime: DateFormat(
                'dd/MM/yyyy HH:mm',
              ).format(appointmentDateTime),
              address: address,
              note: note,
            );
          },
        ),
      );

      if (!mounted) {
        return;
      }

      _resetForm();
    } catch (error, stackTrace) {
      debugPrint(
        'Lỗi đặt lịch: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Không thể đặt lịch: $error',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _resetForm() {
    _addressController.text = widget.userAddress.trim();
    _phoneController.text = widget.userPhone.trim();
    _noteController.clear();

    setState(() {
      _selectedProvider = null;
      _selectedDate = null;
      _selectedTime = null;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
      const Color(0xFFF4F6F8),
      body: Form(
        key: _formKey,
        child: ListView(
          padding:
          const EdgeInsets.all(16),
          children: [
            _buildHeader(),
            const SizedBox(height: 18),
            _buildMainCard(),
            const SizedBox(height: 18),
            _buildSubmitButton(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius:
        BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.calendar_month,
              color: Colors.green,
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'Đặt lịch dịch vụ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Chọn dịch vụ, nhân viên và thời gian phù hợp.',
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainCard() {
    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(14),
      ),
      child: Padding(
        padding:
        const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(
              icon:
              Icons.home_repair_service,
              title: 'Thông tin dịch vụ',
            ),
            const SizedBox(height: 14),
            _buildServiceDropdown(),
            const SizedBox(height: 14),
            _buildCategoryField(),
            if (_selectedService != null) ...[
              const SizedBox(height: 14),
              _buildProviderDropdown(),
            ],
            const SizedBox(height: 22),
            const Divider(),
            const SizedBox(height: 18),
            _buildSectionTitle(
              icon: Icons.schedule,
              title: 'Thời gian thực hiện',
            ),
            const SizedBox(height: 14),
            _buildDateTimeFields(),
            const SizedBox(height: 22),
            const Divider(),
            const SizedBox(height: 18),
            _buildSectionTitle(
              icon: Icons.location_on,
              title: 'Thông tin liên hệ',
            ),
            const SizedBox(height: 14),
            _buildPhoneField(),
            const SizedBox(height: 14),
            _buildAddressField(),
            const SizedBox(height: 14),
            _buildNoteField(),
            const SizedBox(height: 18),
            _buildPriceSummary(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle({
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.green,
          size: 22,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting
            ? null
            : _submitBooking,
        style:
        ElevatedButton.styleFrom(
          backgroundColor:
          Colors.green,
          foregroundColor:
          Colors.white,
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(10),
          ),
        ),
        icon: _isSubmitting
            ? const SizedBox(
          width: 20,
          height: 20,
          child:
          CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : const Icon(
          Icons.check_circle_outline,
        ),
        label: Text(
          _isSubmitting
              ? 'Đang đặt lịch...'
              : 'Xác nhận đặt lịch',
          style: const TextStyle(
            fontSize: 16,
            fontWeight:
            FontWeight.w600,
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor:
      const Color(0xFFF9FAFB),
      border: OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(10),
      ),
      enabledBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(10),
        borderSide: BorderSide(
          color: Colors.grey.shade300,
        ),
      ),
      focusedBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(10),
        borderSide:
        const BorderSide(
          color: Colors.green,
          width: 1.4,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Colors.red,
        ),
      ),
      focusedErrorBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1.4,
        ),
      ),
    );
  }

  Widget _buildServiceDropdown() {
    return DropdownButtonFormField<
        HomeServiceModel>(
      key: ValueKey<int?>(_selectedService?.id),
      initialValue: _selectedService,
      isExpanded: true,
      decoration: _inputDecoration(
        label: 'Dịch vụ *',
        icon:
        Icons.home_repair_service,
        hint: 'Chọn dịch vụ',
      ),
      items: _services.map(
            (HomeServiceModel service) {
          return DropdownMenuItem<
              HomeServiceModel>(
            value: service,
            child: Text(
              '${service.name ?? 'Dịch vụ'} - ${_formatPrice(service.price)}',
              overflow:
              TextOverflow.ellipsis,
            ),
          );
        },
      ).toList(),
      onChanged: _isSubmitting
          ? null
          : _onServiceChanged,
      validator: (_) {
        final int? id =
            _selectedService?.id;

        if (_selectedService == null ||
            id == null ||
            id <= 0) {
          return 'Vui lòng chọn dịch vụ';
        }

        return null;
      },
    );
  }

  Widget _buildCategoryField() {
    return InputDecorator(
      decoration: _inputDecoration(
        label: 'Danh mục',
        icon: Icons.category,
      ),
      child: Text(
        _selectedCategory?.name ??
            'Tự động theo dịch vụ',
        style: TextStyle(
          color: _selectedCategory == null
              ? Colors.grey
              : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildProviderDropdown() {
    final List<ProviderModel>
    providers = _availableProviders;

    return DropdownButtonFormField<
        ProviderModel>(
      key: ValueKey<String>('${_selectedService?.id}-${_selectedProvider?.id}'),
      initialValue: _selectedProvider,
      isExpanded: true,
      decoration: _inputDecoration(
        label: 'Nhân viên *',
        icon: Icons.person,
        hint: providers.isEmpty
            ? 'Dịch vụ này chưa có nhân viên'
            : 'Chọn nhân viên',
      ),
      items: providers.map(
            (ProviderModel provider) {
          return DropdownMenuItem<
              ProviderModel>(
            value: provider,
            child: Text(
              '${provider.name} - ${provider.phone}',
              overflow:
              TextOverflow.ellipsis,
            ),
          );
        },
      ).toList(),
      onChanged:
      providers.isEmpty || _isSubmitting
          ? null
          : (ProviderModel? value) {
        setState(() {
          _selectedProvider =
              value;
        });
      },
      validator: (_) {
        final int? id =
            _selectedProvider?.id;

        if (_selectedProvider == null ||
            id == null ||
            id <= 0) {
          return 'Vui lòng chọn nhân viên';
        }

        return null;
      },
    );
  }

  Widget _buildDateTimeFields() {
    return LayoutBuilder(
      builder: (
          BuildContext context,
          BoxConstraints constraints,
          ) {
        if (constraints.maxWidth < 500) {
          return Column(
            children: [
              _buildDateField(),
              const SizedBox(height: 14),
              _buildTimeField(),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _buildDateField(),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildTimeField(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: _isSubmitting
          ? null
          : _pickDate,
      borderRadius:
      BorderRadius.circular(10),
      child: InputDecorator(
        decoration: _inputDecoration(
          label: 'Ngày *',
          icon:
          Icons.calendar_today,
        ),
        child: Text(
          _selectedDate == null
              ? 'Chọn ngày'
              : DateFormat(
            'dd/MM/yyyy',
          ).format(
            _selectedDate!,
          ),
        ),
      ),
    );
  }

  Widget _buildTimeField() {
    return InkWell(
      onTap: _isSubmitting
          ? null
          : _pickTime,
      borderRadius:
      BorderRadius.circular(10),
      child: InputDecorator(
        decoration: _inputDecoration(
          label: 'Giờ *',
          icon: Icons.access_time,
        ),
        child: Text(
          _selectedTime == null
              ? 'Chọn giờ'
              : _selectedTime!
              .format(context),
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return TextFormField(
      controller: _phoneController,
      enabled: !_isSubmitting,
      keyboardType: TextInputType.phone,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')), LengthLimitingTextInputFormatter(11)],
      decoration: _inputDecoration(
        label: 'Số điện thoại *',
        icon: Icons.phone_outlined,
        hint: 'Nhập số điện thoại liên hệ',
      ),
      validator: AppValidators.phone,
    );
  }

  Widget _buildAddressField() {
    return TextFormField(
      controller: _addressController,
      enabled: !_isSubmitting,
      maxLength: 150,
      decoration: _inputDecoration(
        label: 'Địa chỉ *',
        icon: Icons.location_on,
        hint:
        'Nhập địa chỉ thực hiện dịch vụ',
      ),
      validator: AppValidators.address,
    );
  }

  Widget _buildNoteField() {
    return TextFormField(
      controller: _noteController,
      enabled: !_isSubmitting,
      maxLines: 3,
      maxLength: 300,
      validator: (value) => (value?.trim().length ?? 0) > 300
          ? 'Ghi chú không được vượt quá 300 ký tự'
          : null,
      decoration: _inputDecoration(
        label: 'Ghi chú',
        icon: Icons.note,
        hint:
        'Nhập yêu cầu thêm nếu có',
      ).copyWith(
        alignLabelWithHint: true,
      ),
    );
  }

  Widget _buildPriceSummary() {
    return Container(
      padding:
      const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:
        Colors.green.shade50,
        border: Border.all(
          color:
          Colors.green.shade200,
        ),
        borderRadius:
        BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.payments,
            color: Colors.green,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Giá dịch vụ',
              style: TextStyle(
                fontWeight:
                FontWeight.bold,
              ),
            ),
          ),
          Text(
            _formatPrice(
              _selectedService?.price,
            ),
            style: const TextStyle(
              color: Colors.green,
              fontSize: 18,
              fontWeight:
              FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
