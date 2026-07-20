class AppointmentModel {
  int? id;
  int userId;        // ID người đặt
  int serviceId;     // ID dịch vụ được đặt
  String bookDate;   // Ngày giờ làm việc (định dạng String để dễ lưu trữ)
  String address;    // Địa chỉ làm việc
  String note;       // Ghi chú thêm
  String status;     // Trạng thái: "PENDING" (Chờ), "CONFIRMED" (Đã duyệt), "CANCELLED" (Hủy)

  AppointmentModel({
    this.id,
    required this.userId,
    required this.serviceId,
    required this.bookDate,
    required this.address,
    required this.note,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userid': userId,
      'serviceid': serviceId,
      'bookdate': bookDate,
      'address': address,
      'note': note,
      'status': status,
    };
  }

  factory AppointmentModel.fromMap(Map<String, dynamic> map) {
    return AppointmentModel(
      id: map['id'],
      userId: map['userid'] ?? 0,
      serviceId: map['serviceid'] ?? 0,
      bookDate: map['bookdate'] ?? '',
      address: map['address'] ?? '',
      note: map['note'] ?? '',
      status: map['status'] ?? 'PENDING',
    );
  }
}