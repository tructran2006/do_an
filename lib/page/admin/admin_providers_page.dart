import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:do_an/core/app_validators.dart';

import 'package:do_an/data/helper/db_helper.dart';

class AdminProvidersPage extends StatefulWidget {
  const AdminProvidersPage({super.key});

  @override
  State<AdminProvidersPage> createState() =>
      _AdminProvidersPageState();
}

class _AdminProvidersPageState
    extends State<AdminProvidersPage> {
  final DatabaseHelper _databaseHelper =
  DatabaseHelper();

  final TextEditingController _searchController =
  TextEditingController();

  List<Map<String, dynamic>> _providers = [];

  bool _isLoading = true;

  String _searchKeyword = '';

  @override
  void initState() {
    super.initState();
    _loadProviders();
  }

  Future<void> _loadProviders() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final providers =
      await _databaseHelper.getAdminProviders();

      if (!mounted) {
        return;
      }

      setState(() {
        _providers = providers;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Không thể tải danh sách nhân viên: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Map<String, dynamic>> get _filteredProviders {
    final keyword =
    _searchKeyword.trim().toLowerCase();

    final providers =
    List<Map<String, dynamic>>.from(
      _providers,
    );

    if (keyword.isEmpty) {
      providers.sort((a, b) {
        final nameA =
            a['name']?.toString().toLowerCase() ??
                '';

        final nameB =
            b['name']?.toString().toLowerCase() ??
                '';

        return nameA.compareTo(nameB);
      });

      return providers;
    }

    final filteredProviders =
    providers.where((provider) {
      final name =
          provider['name']
              ?.toString()
              .toLowerCase() ??
              '';

      return name.contains(keyword);
    }).toList();

    filteredProviders.sort((a, b) {
      final nameA =
          a['name']?.toString().toLowerCase() ??
              '';

      final nameB =
          b['name']?.toString().toLowerCase() ??
              '';

      final startsWithA =
      nameA.startsWith(keyword);

      final startsWithB =
      nameB.startsWith(keyword);

      if (startsWithA && !startsWithB) {
        return -1;
      }

      if (!startsWithA && startsWithB) {
        return 1;
      }

      return nameA.compareTo(nameB);
    });

    return filteredProviders;
  }

  Future<void> _showProviderDialog({
    Map<String, dynamic>? provider,
  }) async {
    final bool isEditing = provider != null;

    final nameController = TextEditingController(
      text: provider?['name']?.toString() ?? '',
    );

    final phoneController = TextEditingController(
      text: provider?['phone']?.toString() ?? '',
    );

    final priceController = TextEditingController(
      text:
      provider?['price_per_hour']?.toString() ??
          '',
    );

    final imageController = TextEditingController(
      text:
      provider?['image_url']?.toString() ?? '',
    );

    int? selectedServiceId =
    provider?['service_id'] as int?;

    try {
      final services =
      await _databaseHelper.getAdminServices();

      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (
                dialogContext,
                setDialogState,
                ) {
              return AlertDialog(
                title: Text(
                  isEditing
                      ? 'Sửa nhân viên'
                      : 'Thêm nhân viên',
                ),
                content: SizedBox(
                  width: 500,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize:
                      MainAxisSize.min,
                      children: [
                        TextField(
                          controller:
                          nameController,
                          decoration:
                          const InputDecoration(
                            labelText:
                            'Tên nhân viên *',
                            prefixIcon:
                            Icon(Icons.person),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller:
                          phoneController,
                          keyboardType:
                          TextInputType.phone,
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')), LengthLimitingTextInputFormatter(11)],
                          decoration:
                          const InputDecoration(
                            labelText:
                            'Số điện thoại *',
                            prefixIcon:
                            Icon(Icons.phone),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller:
                          priceController,
                          keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')), LengthLimitingTextInputFormatter(12)],
                          decoration:
                          const InputDecoration(
                            labelText:
                            'Giá theo giờ *',
                            prefixIcon:
                            Icon(Icons.payments),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller:
                          imageController,
                          decoration:
                          const InputDecoration(
                            labelText:
                            'Đường dẫn ảnh',
                            prefixIcon:
                            Icon(Icons.image),
                          ),
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<int>(
                          initialValue:
                          selectedServiceId,
                          decoration:
                          const InputDecoration(
                            labelText:
                            'Dịch vụ phụ trách *',
                            prefixIcon: Icon(
                              Icons.cleaning_services,
                            ),
                          ),
                          items: services.map(
                                (service) {
                              return DropdownMenuItem<
                                  int>(
                                value:
                                service['id'] as int,
                                child: Text(
                                  service['name']
                                      .toString(),
                                ),
                              );
                            },
                          ).toList(),
                          onChanged: (value) {
                            setDialogState(() {
                              selectedServiceId =
                                  value;
                            });
                          },
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
                    child: const Text('Hủy'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final name =
                      nameController.text.trim();

                      final phone =
                      phoneController.text.trim();

                      final price =
                      double.tryParse(
                        priceController.text.trim(),
                      );

                      final nameError = AppValidators.fullName(name);
                      if (nameError != null) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text(nameError), backgroundColor: Colors.red)); return;
                      }
                      final phoneError = AppValidators.phone(phone);
                      if (phoneError != null) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text(phoneError), backgroundColor: Colors.red)); return;
                      }
                      if (price == null || price <= 0) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(content: Text('Giá theo giờ phải là số lớn hơn 0.'), backgroundColor: Colors.red)); return;
                      }
                      if (selectedServiceId == null) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(content: Text('Vui lòng chọn dịch vụ phụ trách.'), backgroundColor: Colors.red)); return;
                      }
                      final imageError = AppValidators.imageUrl(imageController.text);
                      if (imageError != null) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text(imageError), backgroundColor: Colors.red)); return;
                      }
                      final currentId = isEditing ? provider['id'] as int : null;
                      if (await _databaseHelper.providerNameExists(name, excludeId: currentId)) {
                        if (!dialogContext.mounted) return;
                        ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(content: Text('Tên nhân viên đã tồn tại.'), backgroundColor: Colors.red)); return;
                      }
                      if (await _databaseHelper.providerPhoneExists(phone, excludeId: currentId)) {
                        if (!dialogContext.mounted) return;
                        ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(content: Text('Số điện thoại này đã được sử dụng cho nhân viên khác.'), backgroundColor: Colors.red)); return;
                      }

                      try {
                        if (isEditing) {
                          await _databaseHelper
                              .updateProvider(
                            id:
                            provider['id'] as int,
                            name: name,
                            imageUrl:
                            imageController.text
                                .trim(),
                            phone: phone,
                            pricePerHour: price,
                            serviceId:
                            selectedServiceId!,
                          );
                        } else {
                          await _databaseHelper
                              .addProvider(
                            name: name,
                            imageUrl:
                            imageController.text
                                .trim(),
                            phone: phone,
                            pricePerHour: price,
                            serviceId:
                            selectedServiceId!,
                          );
                        }

                        if (!dialogContext.mounted) {
                          return;
                        }

                        Navigator.pop(
                          dialogContext,
                        );

                        await _loadProviders();
                      } catch (e) {
                        if (!dialogContext.mounted) {
                          return;
                        }

                        ScaffoldMessenger.of(
                          dialogContext,
                        ).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Không thể lưu nhân viên: $e',
                            ),
                            backgroundColor:
                            Colors.red,
                          ),
                        );
                      }
                    },
                    child: Text(
                      isEditing ? 'Lưu' : 'Thêm',
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      nameController.dispose();
      phoneController.dispose();
      priceController.dispose();
      imageController.dispose();
    }
  }

  Future<void> _deleteProvider(
      Map<String, dynamic> provider,
      ) async {
    final bool? confirm =
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title:
          const Text('Xác nhận xóa'),
          content: Text(
            'Bạn có chắc muốn xóa nhân viên '
                '"${provider['name']}" không?',
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
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    try {
      await _databaseHelper.deleteProvider(
        provider['id'] as int,
      );

      await _loadProviders();
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Không thể xóa nhân viên: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredProviders =
        _filteredProviders;

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              8,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchKeyword = value;
                });
              },
              decoration: InputDecoration(
                hintText:
                'Tìm kiếm theo tên nhân viên',
                prefixIcon:
                const Icon(Icons.search),
                suffixIcon:
                _searchKeyword.isNotEmpty
                    ? IconButton(
                  tooltip:
                  'Xóa tìm kiếm',
                  onPressed: () {
                    _searchController
                        .clear();

                    setState(() {
                      _searchKeyword = '';
                    });
                  },
                  icon: const Icon(
                    Icons.close,
                  ),
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
              child:
              CircularProgressIndicator(),
            )
                : _providers.isEmpty
                ? const Center(
              child: Text(
                'Chưa có nhân viên nào',
              ),
            )
                : filteredProviders.isEmpty
                ? RefreshIndicator(
              onRefresh:
              _loadProviders,
              child: ListView(
                physics:
                const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(
                    height: 180,
                  ),
                  Center(
                    child: Text(
                      'Không tìm thấy nhân viên phù hợp',
                    ),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh:
              _loadProviders,
              child:
              ListView.builder(
                physics:
                const AlwaysScrollableScrollPhysics(),
                padding:
                const EdgeInsets
                    .fromLTRB(
                  16,
                  8,
                  16,
                  16,
                ),
                itemCount:
                filteredProviders
                    .length,
                itemBuilder: (
                    context,
                    index,
                    ) {
                  final provider =
                  filteredProviders[
                  index];

                  return Card(
                    margin:
                    const EdgeInsets
                        .only(
                      bottom: 12,
                    ),
                    child: ListTile(
                      leading: _AdminNetworkAvatar(
                        imageUrl: provider['image_url']?.toString() ?? '',
                        fallbackText: provider['name']?.toString() ?? 'NV',
                      ),
                      title: Text(
                        provider['name']
                            ?.toString() ??
                            'Không tên',
                        style:
                        const TextStyle(
                          fontWeight:
                          FontWeight
                              .bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                        children: [
                          Text(
                            'SĐT: ${provider['phone'] ?? ''}',
                          ),
                          Text(
                            'Dịch vụ: ${provider['service_name'] ?? 'Chưa gán'}',
                          ),
                          Text(
                            'Giá/giờ: ${provider['price_per_hour'] ?? 0} đ',
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize:
                        MainAxisSize
                            .min,
                        children: [
                          IconButton(
                            tooltip:
                            'Sửa nhân viên',
                            onPressed:
                                () {
                              _showProviderDialog(
                                provider:
                                provider,
                              );
                            },
                            icon:
                            const Icon(
                              Icons.edit,
                              color: Colors
                                  .blue,
                            ),
                          ),
                          IconButton(
                            tooltip:
                            'Xóa nhân viên',
                            onPressed:
                                () {
                              _deleteProvider(
                                provider,
                              );
                            },
                            icon:
                            const Icon(
                              Icons.delete,
                              color: Colors
                                  .red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton:
      FloatingActionButton.extended(
        onPressed: () {
          _showProviderDialog();
        },
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Thêm nhân viên',
        ),
      ),
    );
  }
}

class _AdminNetworkAvatar extends StatelessWidget {
  final String imageUrl;
  final String fallbackText;

  const _AdminNetworkAvatar({required this.imageUrl, required this.fallbackText});

  @override
  Widget build(BuildContext context) {
    final url = imageUrl.trim();
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 48,
        height: 48,
        child: url.isEmpty
            ? _fallback()
            : Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fallback()),
      ),
    );
  }

  Widget _fallback() {
    final text = fallbackText.trim().isEmpty ? '?' : fallbackText.trim()[0].toUpperCase();
    return Container(
      color: const Color(0xFFEAF2FF),
      alignment: Alignment.center,
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF3578E5))),
    );
  }
}
