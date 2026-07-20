class ProviderModel {
  final int? id;
  final String name;
  final String imageUrl;
  final String phone;
  final double pricePerHour;
  final int serviceId; // Liên kết với ID của HomeService

  ProviderModel({
    this.id,
    required this.name,
    required this.imageUrl,
    required this.phone,
    required this.pricePerHour,
    required this.serviceId,
  });

  // Chuyển đổi sang Map để lưu vào SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'image_url': imageUrl,
      'phone': phone,
      'price_per_hour': pricePerHour,
      'service_id': serviceId,
    };
  }

  // Chuyển từ Map (Database) ngược lại Object
  factory ProviderModel.fromMap(Map<String, dynamic> map) {
    return ProviderModel(
      id: map['id'],
      name: map['name'],
      imageUrl: map['image_url'],
      phone: map['phone'],
      pricePerHour: map['price_per_hour'],
      serviceId: map['service_id'],
    );
  }
}