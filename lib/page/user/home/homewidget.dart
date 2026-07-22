import 'dart:async';

import 'package:flutter/material.dart';

import 'package:do_an/data/helper/db_helper.dart';
import 'package:do_an/data/model/home_service.dart';
import 'package:do_an/data/model/provider_model.dart';
import 'package:do_an/data/model/service_category.dart';

class HomeWidget extends StatefulWidget {
  final ValueChanged<HomeServiceModel>? onServiceSelected;

  const HomeWidget({
    super.key,
    this.onServiceSelected,
  });

  @override
  State<HomeWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final TextEditingController _searchController =
  TextEditingController();
  final PageController _bannerController =
  PageController();

  List<ServiceCategoryModel> _categories = [];
  List<HomeServiceModel> _services = [];
  List<HomeServiceModel> _visibleServices = [];
  List<ProviderModel> _providers = [];

  int? _selectedCategoryId;
  int _currentBannerIndex = 0;
  bool _isLoading = true;
  Timer? _bannerTimer;

  static const List<String> _serviceFallbackImages = [
    'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=900',
    'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=900',
    'https://images.unsplash.com/photo-1503387762-592deb58ef4e?w=900',
  ];

  static const List<String> _providerFallbackImages = [
    'https://images.unsplash.com/photo-1560250097-0b93528c311a?w=500',
    'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=500',
    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=500',
    'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=500',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _startBannerAutoPlay();
  }

  @override
  @override
  void dispose() {
    _bannerTimer?.cancel();
    _searchController.dispose();
    _bannerController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final categories =
      await _databaseHelper.getAllCategories();
      final services =
      await _databaseHelper.getAllServices();
      final providers =
      await _databaseHelper.getAllProviders();

      services.sort((a, b) {
        return (a.name ?? '')
            .toLowerCase()
            .compareTo((b.name ?? '').toLowerCase());
      });

      if (!mounted) {
        return;
      }

      setState(() {
        _categories = categories;
        _services = services;
        _providers = providers;
        _isLoading = false;
      });

      _applyFilter(_searchController.text);
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
            'Không thể tải dữ liệu trang chủ: $error',
          ),
        ),
      );
    }
  }

  void _startBannerAutoPlay() {
    _bannerTimer = Timer.periodic(
      const Duration(seconds: 4),
          (_) {
        if (!_bannerController.hasClients) {
          return;
        }

        final int total = _services.isEmpty
            ? _serviceFallbackImages.length
            : _services.take(3).length;

        if (total <= 1) {
          return;
        }

        final int nextIndex =
            (_currentBannerIndex + 1) % total;

        _bannerController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
      },
    );
  }

  void _applyFilter(String value) {
    final String keyword =
    value.trim().toLowerCase();

    final List<HomeServiceModel> result =
    _services.where((service) {
      final String serviceName =
      (service.name ?? '')
          .trim()
          .toLowerCase();

      final bool matchesSearch =
          keyword.isEmpty ||
              serviceName.contains(keyword);

      final bool matchesCategory =
          _selectedCategoryId == null ||
              service.catId == _selectedCategoryId;

      return matchesSearch && matchesCategory;
    }).toList();

    setState(() {
      _visibleServices = result;
    });
  }

  void _selectCategory(
      ServiceCategoryModel category,
      ) {
    setState(() {
      if (_selectedCategoryId == category.id) {
        _selectedCategoryId = null;
      } else {
        _selectedCategoryId = category.id;
      }
    });

    _applyFilter(_searchController.text);
  }

  void _clearSearch() {
    _searchController.clear();

    setState(() {
      _selectedCategoryId = null;
    });

    _applyFilter('');
  }

  void _goToBooking(HomeServiceModel service) {
    widget.onServiceSelected?.call(service);
  }

  void _openProvider(ProviderModel provider) {
    HomeServiceModel? selectedService;

    for (final service in _services) {
      if (service.id == provider.serviceId) {
        selectedService = service;
        break;
      }
    }

    if (selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Không tìm thấy dịch vụ của nhân viên này.',
          ),
        ),
      );
      return;
    }

    _goToBooking(selectedService);
  }

  String _formatPrice(int? price) {
    final int value = price ?? 0;
    final String text = value.toString();
    final StringBuffer output = StringBuffer();

    for (int index = 0; index < text.length; index++) {
      output.write(text[index]);

      final int remain = text.length - index - 1;

      if (remain > 0 && remain % 3 == 0) {
        output.write('.');
      }
    }

    return '${output.toString()} đ';
  }

  String _serviceFallback(int index) {
    return _serviceFallbackImages[
    index % _serviceFallbackImages.length];
  }

  String _providerFallback(int index) {
    return _providerFallbackImages[
    index % _providerFallbackImages.length];
  }

  Widget _buildImage({
    required String? path,
    required String fallbackUrl,
    required double width,
    required double height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
  }) {
    final String value = path?.trim() ?? '';

    Widget image;

    if (value.startsWith('http://') ||
        value.startsWith('https://')) {
      image = Image.network(
        value,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) {
          return Image.network(
            fallbackUrl,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (_, __, ___) {
              return _buildImagePlaceholder(
                width: width,
                height: height,
              );
            },
          );
        },
      );
    } else if (value.isNotEmpty) {
      image = Image.asset(
        value,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) {
          return Image.network(
            fallbackUrl,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (_, __, ___) {
              return _buildImagePlaceholder(
                width: width,
                height: height,
              );
            },
          );
        },
      );
    } else {
      image = Image.network(
        fallbackUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) {
          return _buildImagePlaceholder(
            width: width,
            height: height,
          );
        },
      );
    }

    if (borderRadius == null) {
      return image;
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: image,
    );
  }

  Widget _buildImagePlaceholder({
    required double width,
    required double height,
  }) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: Icon(
        Icons.image_not_supported_outlined,
        color: Colors.grey.shade500,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            16,
            16,
            16,
            24,
          ),
          children: [
            _buildSearchBar(),
            const SizedBox(height: 16),
            _buildBanner(),
            const SizedBox(height: 22),
            _buildSectionTitle(
              'Danh mục dịch vụ',
            ),
            const SizedBox(height: 10),
            _buildCategories(),
            const SizedBox(height: 22),
            _buildSectionTitle(
              _selectedCategoryId == null
                  ? 'Dịch vụ'
                  : 'Dịch vụ theo danh mục',
            ),
            const SizedBox(height: 10),
            _buildServices(),
            const SizedBox(height: 22),
            _buildSectionTitle(
              'Nhân viên nổi bật',
            ),
            const SizedBox(height: 10),
            _buildProviders(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        setState(() {
// Khi tìm kiếm sẽ tìm trong toàn bộ dịch vụ.
          _selectedCategoryId = null;
        });

        _applyFilter(value);
      },
      decoration: InputDecoration(
        hintText: 'Tìm dịch vụ...',
        prefixIcon: const Icon(
          Icons.search,
        ),
        suffixIcon:
        _searchController.text.isEmpty
            ? null
            : IconButton(
          onPressed: _clearSearch,
          icon: const Icon(
            Icons.close,
          ),
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildBanner() {
    final List<HomeServiceModel> bannerServices =
    _services.take(3).toList();

    final int itemCount = bannerServices.isEmpty
        ? _serviceFallbackImages.length
        : bannerServices.length;

    return Column(
      children: [
        SizedBox(
          height: 170,
          child: PageView.builder(
            controller: _bannerController,
            itemCount: itemCount,
            onPageChanged: (index) {
              setState(() {
                _currentBannerIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final HomeServiceModel? service =
              bannerServices.isEmpty
                  ? null
                  : bannerServices[index];

              return Stack(
                fit: StackFit.expand,
                children: [
                  _buildImage(
                    path: service?.img,
                    fallbackUrl:
                    _serviceFallback(index),
                    width: double.infinity,
                    height: 170,
                    borderRadius:
                    BorderRadius.circular(12),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius:
                      BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.black.withValues(
                            alpha: 0.65,
                          ),
                          Colors.black.withValues(
                            alpha: 0.10,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: 260,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              service?.name ??
                                  'Dịch vụ gia đình',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              service == null
                                  ? 'Đặt lịch nhanh và tiện lợi.'
                                  : 'Giá từ ${_formatPrice(service.price)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            if (service != null) ...[
                              const SizedBox(height: 12),
                              FilledButton(
                                onPressed: () {
                                  _goToBooking(service);
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor:
                                  Colors.green,
                                  foregroundColor:
                                  Colors.white,
                                ),
                                child:
                                const Text('Đặt lịch'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: List.generate(
            itemCount,
                (index) {
              return Container(
                width: _currentBannerIndex == index
                    ? 18
                    : 8,
                height: 8,
                margin:
                const EdgeInsets.symmetric(
                  horizontal: 3,
                ),
                decoration: BoxDecoration(
                  color:
                  _currentBannerIndex == index
                      ? Colors.green
                      : Colors.grey.shade400,
                  borderRadius:
                  BorderRadius.circular(10),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildCategories() {
    if (_categories.isEmpty) {
      return const Text('Chưa có danh mục.');
    }

    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) =>
        const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final bool selected =
              _selectedCategoryId == category.id;

          return ChoiceChip(
            label: Text(category.name),
            selected: selected,
            selectedColor: Colors.green.shade100,
            onSelected: (_) {
              _selectCategory(category);
            },
          );
        },
      ),
    );
  }

  Widget _buildServices() {
    if (_visibleServices.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            'Không có dịch vụ phù hợp.',
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics:
      const NeverScrollableScrollPhysics(),
      itemCount: _visibleServices.length,
      separatorBuilder: (_, __) =>
      const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final service = _visibleServices[index];

        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              _goToBooking(service);
            },
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  _buildImage(
                    path: service.img,
                    fallbackUrl:
                    _serviceFallback(index),
                    width: 86,
                    height: 72,
                    borderRadius:
                    BorderRadius.circular(8),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.name ?? 'Dịch vụ',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _formatPrice(service.price),
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight:
                            FontWeight.w600,
                          ),
                        ),
                        if ((service.des ?? '')
                            .trim()
                            .isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            service.des!,
                            maxLines: 1,
                            overflow:
                            TextOverflow.ellipsis,
                            style: TextStyle(
                              color:
                              Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProviders() {
    if (_providers.isEmpty) {
      return const Text('Chưa có nhân viên.');
    }

    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _providers.length,
        separatorBuilder: (_, __) =>
        const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final provider = _providers[index];

          return Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                _openProvider(provider);
              },
              child: SizedBox(
                width: 145,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      _buildImage(
                        path: provider.imageUrl,
                        fallbackUrl:
                        _providerFallback(index),
                        width: 125,
                        height: 100,
                        borderRadius:
                        BorderRadius.circular(8),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        provider.name,
                        maxLines: 1,
                        overflow:
                        TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        provider.phone,
                        maxLines: 1,
                        overflow:
                        TextOverflow.ellipsis,
                        style: TextStyle(
                          color:
                          Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Nhấn để đặt lịch',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
