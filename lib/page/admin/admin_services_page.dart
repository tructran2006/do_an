import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:do_an/core/app_validators.dart';

import 'package:do_an/data/helper/db_helper.dart';
import 'package:do_an/data/model/service_category.dart';

class AdminServicesPage extends StatefulWidget {
  const AdminServicesPage({super.key});

  @override
  State<AdminServicesPage> createState() =>
      _AdminServicesPageState();
}

class _AdminServicesPageState
    extends State<AdminServicesPage> {
  final DatabaseHelper _databaseHelper =
  DatabaseHelper();

  final TextEditingController _searchController =
  TextEditingController();

  List<Map<String, dynamic>> _services = [];
  List<Map<String, dynamic>> _filteredServices = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _searchController.addListener(
      _filterServices,
    );

    _loadServices();
  }

  @override
  void dispose() {
    _searchController.removeListener(
      _filterServices,
    );

    _searchController.dispose();

    super.dispose();
  }

  Future<void> _loadServices() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final List<Map<String, dynamic>> services =
      await _databaseHelper.getAdminServices();

      if (!mounted) {
        return;
      }

      _services =
      List<Map<String, dynamic>>.from(
        services,
      );

      _sortServicesAZ();

      setState(() {
        _isLoading = false;
      });

      _filterServices();
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
            'Không thể tải danh sách dịch vụ: $error',
          ),
        ),
      );
    }
  }

  void _sortServicesAZ() {
    _services.sort(
          (
          Map<String, dynamic> first,
          Map<String, dynamic> second,
          ) {
        final String firstName =
            first['name']
                ?.toString()
                .trim()
                .toLowerCase() ??
                '';

        final String secondName =
            second['name']
                ?.toString()
                .trim()
                .toLowerCase() ??
                '';

        return firstName.compareTo(secondName);
      },
    );
  }

  void _filterServices() {
    final String keyword =
    _searchController.text
        .trim()
        .toLowerCase();

    final List<Map<String, dynamic>> result =
    _services.where(
          (Map<String, dynamic> service) {
        final String serviceName =
            service['name']
                ?.toString()
                .trim()
                .toLowerCase() ??
                '';

        return keyword.isEmpty ||
            serviceName.startsWith(keyword);
      },
    ).toList();

    if (!mounted) {
      return;
    }

    setState(() {
      _filteredServices = result;
    });
  }

  void _clearSearch() {
    _searchController.clear();
  }

  String _formatPrice(dynamic price) {
    final int value =
        int.tryParse(price.toString()) ?? 0;

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

  Future<void> _showServiceDetails(
      Map<String, dynamic> service,
      ) async {
    final String name =
        service['name']?.toString() ??
            'Không tên';

    final String categoryName =
        service['category_name']
            ?.toString() ??
            'Chưa phân loại';

    final String description =
    service['desc']
        ?.toString()
        .trim()
        .isNotEmpty ==
        true
        ? service['desc']
        .toString()
        .trim()
        : 'Chưa có mô tả';

    final String image =
    service['img']
        ?.toString()
        .trim()
        .isNotEmpty ==
        true
        ? service['img']
        .toString()
        .trim()
        : 'Chưa có ảnh';

    await showDialog<void>(
      context: context,
      builder: (
          BuildContext dialogContext,
          ) {
        return AlertDialog(
          title: const Text(
            'Thông tin dịch vụ',
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize:
              MainAxisSize.min,
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                _buildDetailRow(
                  label: 'Tên',
                  value: name,
                ),
                _buildDetailRow(
                  label: 'Giá',
                  value: _formatPrice(
                    service['price'],
                  ),
                ),
                _buildDetailRow(
                  label: 'Danh mục',
                  value: categoryName,
                ),
                _buildDetailRow(
                  label: 'Ảnh',
                  value: image,
                ),
                _buildDetailRow(
                  label: 'Mô tả',
                  value: description,
                ),
              ],
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
        bottom: 10,
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
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

  Future<void> _openServiceForm({
    Map<String, dynamic>? service,
  }) async {
    try {
      final List<ServiceCategoryModel>
      categories =
      await _databaseHelper
          .getAllCategories();

      if (!mounted) {
        return;
      }

      final bool? saved =
      await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (
            BuildContext dialogContext,
            ) {
          return ServiceFormDialog(
            databaseHelper:
            _databaseHelper,
            categories: categories,
            service: service,
          );
        },
      );

      if (saved == true && mounted) {
        await _loadServices();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Không thể mở biểu mẫu: $error',
          ),
        ),
      );
    }
  }

  Future<void> _deleteService(
      Map<String, dynamic> service,
      ) async {
    final bool? confirmed =
    await showDialog<bool>(
      context: context,
      builder: (
          BuildContext dialogContext,
          ) {
        return AlertDialog(
          title:
          const Text('Xác nhận xóa'),
          content: Text(
            'Bạn có chắc muốn xóa dịch vụ '
                '"${service['name']}" không?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                Colors.red,
                foregroundColor:
                Colors.white,
              ),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _databaseHelper
          .deleteService(
        service['id'] as int,
      );

      await _loadServices();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Đã xóa dịch vụ.',
          ),
          backgroundColor:
          Colors.green,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Không thể xóa dịch vụ: $error',
          ),
        ),
      );
    }
  }

  Widget _buildSearchBar() {
    return Padding(
      padding:
      const EdgeInsets.all(16),
      child: TextField(
        controller:
        _searchController,
        decoration: InputDecoration(
          hintText:
          'Tìm kiếm theo tên dịch vụ...',
          prefixIcon:
          const Icon(Icons.search),
          suffixIcon:
          _searchController
              .text
              .isEmpty
              ? null
              : IconButton(
            onPressed:
            _clearSearch,
            icon: const Icon(
              Icons.clear,
            ),
          ),
          border:
          const OutlineInputBorder(),
        ),
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
            ? 'Không tìm thấy dịch vụ phù hợp'
            : 'Chưa có dịch vụ nào',
      ),
    );
  }

  Widget _buildServiceItem(
      Map<String, dynamic> service,
      ) {
    final String name =
        service['name']?.toString() ??
            'Không tên';

    final String categoryName =
        service['category_name']
            ?.toString() ??
            'Chưa phân loại';

    return Card(
      margin:
      const EdgeInsets.fromLTRB(
        16,
        0,
        16,
        10,
      ),
      child: ListTile(
        leading: _AdminServiceImage(
          imageUrl: service['img']?.toString() ?? '',
          fallbackText: name,
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontWeight:
            FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Text(
              'Giá: ${_formatPrice(service['price'])}',
            ),
            Text(
              'Danh mục: $categoryName',
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Xem thông tin',
              onPressed: () {
                _showServiceDetails(
                  service,
                );
              },
              icon: const Icon(
                Icons.visibility,
                color: Colors.blue,
              ),
            ),
            IconButton(
              tooltip: 'Sửa',
              onPressed: () {
                _openServiceForm(
                  service: service,
                );
              },
              icon: const Icon(
                Icons.edit,
                color: Colors.orange,
              ),
            ),
            IconButton(
              tooltip: 'Xóa',
              onPressed: () {
                _deleteService(
                  service,
                );
              },
              icon: const Icon(
                Icons.delete,
                color: Colors.red,
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
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? const Center(
              child:
              CircularProgressIndicator(),
            )
                : _filteredServices
                .isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
              onRefresh:
              _loadServices,
              child:
              ListView.builder(
                padding:
                const EdgeInsets
                    .only(
                  bottom: 90,
                ),
                itemCount:
                _filteredServices
                    .length,
                itemBuilder: (
                    BuildContext context,
                    int index,
                    ) {
                  final Map<String,
                      dynamic>
                  service =
                  _filteredServices[
                  index];

                  return _buildServiceItem(
                    service,
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton:
      FloatingActionButton(
        heroTag:
        'admin_services_add_fab',
        onPressed: () {
          _openServiceForm();
        },
        child: const Icon(
          Icons.add,
        ),
      ),
    );
  }
}

class ServiceFormDialog
    extends StatefulWidget {
  final DatabaseHelper databaseHelper;
  final List<ServiceCategoryModel>
  categories;
  final Map<String, dynamic>? service;

  const ServiceFormDialog({
    super.key,
    required this.databaseHelper,
    required this.categories,
    this.service,
  });

  @override
  State<ServiceFormDialog>
  createState() =>
      _ServiceFormDialogState();
}

class _ServiceFormDialogState
    extends State<ServiceFormDialog> {
  late final TextEditingController
  _nameController;

  late final TextEditingController
  _priceController;

  late final TextEditingController
  _imageController;

  late final TextEditingController
  _descriptionController;

  int? _selectedCategoryId;
  bool _isSaving = false;

  bool get _isEditing =>
      widget.service != null;

  @override
  void initState() {
    super.initState();

    _nameController =
        TextEditingController(
          text: widget.service?['name']
              ?.toString() ??
              '',
        );

    _priceController =
        TextEditingController(
          text: widget.service?['price']
              ?.toString() ??
              '',
        );

    _imageController =
        TextEditingController(
          text: widget.service?['img']
              ?.toString() ??
              '',
        );

    _descriptionController =
        TextEditingController(
          text: widget.service?['desc']
              ?.toString() ??
              '',
        );

    _selectedCategoryId =
    widget.service?['catid']
    as int?;

    final bool categoryExists =
        _selectedCategoryId == null ||
            widget.categories.any(
                  (
                  ServiceCategoryModel
                  category,
                  ) {
                return category.id ==
                    _selectedCategoryId;
              },
            );

    if (!categoryExists) {
      _selectedCategoryId = null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _imageController.dispose();
    _descriptionController.dispose();

    super.dispose();
  }

  Future<void> _save() async {
    final String name =
    _nameController.text.trim();

    final int? price =
    int.tryParse(
      _priceController.text.trim(),
    );

    final nameError = AppValidators.simpleName(name, field: 'tên dịch vụ');
    if (nameError != null) { _showError(nameError); return; }
    if (price == null || price <= 0) { _showError('Giá dịch vụ phải là số nguyên lớn hơn 0.'); return; }
    if (_selectedCategoryId == null) { _showError('Vui lòng chọn danh mục dịch vụ.'); return; }
    final imageError = AppValidators.imageUrl(_imageController.text);
    if (imageError != null) { _showError(imageError); return; }
    if (_descriptionController.text.trim().length > 500) { _showError('Mô tả không được vượt quá 500 ký tự.'); return; }
    final duplicated = await widget.databaseHelper.serviceNameExists(
      name, excludeId: _isEditing ? widget.service!['id'] as int : null,
    );
    if (!mounted) return;
    if (duplicated) { _showError('Tên dịch vụ đã tồn tại. Vui lòng nhập tên khác.'); return; }

    setState(() {
      _isSaving = true;
    });

    try {
      if (_isEditing) {
        await widget.databaseHelper
            .updateService(
          id: widget.service!['id']
          as int,
          name: name,
          price: price,
          image: _imageController
              .text
              .trim(),
          description:
          _descriptionController
              .text
              .trim(),
          categoryId:
          _selectedCategoryId,
        );
      } else {
        await widget.databaseHelper
            .addService(
          name: name,
          price: price,
          image: _imageController
              .text
              .trim(),
          description:
          _descriptionController
              .text
              .trim(),
          categoryId:
          _selectedCategoryId,
        );
      }

      if (!mounted) {
        return;
      }

      Navigator.pop(
        context,
        true,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Không thể lưu dịch vụ: $error',
          ),
        ),
      );
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    return AlertDialog(
      title: Text(
        _isEditing
            ? 'Sửa dịch vụ'
            : 'Thêm dịch vụ',
      ),
      content: SizedBox(
        width: 450,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize:
            MainAxisSize.min,
            children: [
              TextField(
                controller:
                _nameController,
                inputFormatters: [LengthLimitingTextInputFormatter(80)],
                enabled: !_isSaving,
                decoration:
                const InputDecoration(
                  labelText:
                  'Tên dịch vụ *',
                  border:
                  OutlineInputBorder(),
                ),
              ),
              const SizedBox(
                height: 12,
              ),
              TextField(
                controller:
                _priceController,
                enabled: !_isSaving,
                keyboardType:
                TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(9)],
                decoration:
                const InputDecoration(
                  labelText: 'Giá *',
                  border:
                  OutlineInputBorder(),
                ),
              ),
              const SizedBox(
                height: 12,
              ),
              DropdownButtonFormField<
                  int>(
                initialValue:
                _selectedCategoryId,
                isExpanded: true,
                decoration:
                const InputDecoration(
                  labelText: 'Danh mục',
                  border:
                  OutlineInputBorder(),
                ),
                items:
                widget.categories.map(
                      (
                      ServiceCategoryModel
                      category,
                      ) {
                    return DropdownMenuItem<
                        int>(
                      value: category.id,
                      child: Text(
                        category.name,
                      ),
                    );
                  },
                ).toList(),
                onChanged: _isSaving
                    ? null
                    : (
                    int? value,
                    ) {
                  setState(() {
                    _selectedCategoryId =
                        value;
                  });
                },
              ),
              const SizedBox(
                height: 12,
              ),
              TextField(
                controller:
                _imageController,
                enabled: !_isSaving,
                decoration:
                const InputDecoration(
                  labelText:
                  'Đường dẫn ảnh',
                  border:
                  OutlineInputBorder(),
                ),
              ),
              const SizedBox(
                height: 12,
              ),
              TextField(
                controller:
                _descriptionController,
                enabled: !_isSaving,
                maxLines: 3,
                maxLength: 500,
                decoration:
                const InputDecoration(
                  labelText: 'Mô tả',
                  border:
                  OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving
              ? null
              : () {
            Navigator.pop(
              context,
              false,
            );
          },
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed:
          _isSaving ? null : _save,
          child: Text(
            _isSaving
                ? 'Đang lưu...'
                : _isEditing
                ? 'Lưu'
                : 'Thêm',
          ),
        ),
      ],
    );
  }
}


class _AdminServiceImage extends StatelessWidget {
  final String imageUrl;
  final String fallbackText;
  const _AdminServiceImage({required this.imageUrl, required this.fallbackText});

  @override
  Widget build(BuildContext context) {
    final url = imageUrl.trim();
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 52, height: 52,
        child: url.isEmpty ? _fallback() : Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fallback()),
      ),
    );
  }
  Widget _fallback() {
    final t = fallbackText.trim().isEmpty ? '?' : fallbackText.trim()[0].toUpperCase();
    return Container(color: const Color(0xFFE8F7EE), alignment: Alignment.center, child: Text(t, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF159447))));
  }
}
