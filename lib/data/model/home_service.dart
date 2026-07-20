class HomeServiceModel {
  int? id;
  String? name;       // Tên dịch vụ chi tiết (Ví dụ: Thông tắc cống, Vệ sinh máy giặt)
  int? price;         // Giá tiền dịch vụ
  String? img;        // Hình ảnh minh họa dịch vụ
  String? des;        // Mô tả chi tiết dịch vụ/quy trình
  int? catId;         // ID của danh mục dịch vụ lớn

  HomeServiceModel({this.id, this.name, this.price, this.img, this.des, this.catId});

  HomeServiceModel.fromJson(Map<String, dynamic> json) {
    id = json["id"];
    name = json["name"];
    price = json["price"];
    img = json["img"];
    des = json["desc"]; 
    catId = json["catid"]; 
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data["id"] = id;
    data["name"] = name;
    data["price"] = price;
    data["img"] = img;
    data["desc"] = des; 
    data["catid"] = catId; 
    return data;
  }
}