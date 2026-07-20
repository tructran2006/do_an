import 'dart:convert';

class ServiceCategoryModel {
  final int? id;
  final String name;
  final String desc; // Mô tả danh mục (ví dụ: "Các dịch vụ liên quan đến vệ sinh nhà cửa")

  ServiceCategoryModel({
    this.id,
    required this.name,
    required this.desc,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'desc': desc,
    };
  }

  factory ServiceCategoryModel.fromMap(Map<String, dynamic> map) {
    return ServiceCategoryModel(
      id: map['id']?.toInt() ?? 0,
      name: map['name'] ?? '',
      desc: map['desc'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory ServiceCategoryModel.fromJson(String source) =>
      ServiceCategoryModel.fromMap(json.decode(source));

  @override
  String toString() => 'ServiceCategory(id: $id, name: $name, desc: $desc)';
}