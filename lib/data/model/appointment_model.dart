class AppointmentModel {
  int? id;
  int userId;
  int serviceId;
  int? providerId;
  String bookDate;
  String address;
  String phone;
  String note;
  String status;

  AppointmentModel({
    this.id,
    required this.userId,
    required this.serviceId,
    this.providerId,
    required this.bookDate,
    required this.address,
    this.phone = '',
    required this.note,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userid': userId,
      'serviceid': serviceId,
      'providerid': providerId,
      'bookdate': bookDate,
      'address': address,
      'phone': phone,
      'note': note,
      'status': status,
    };
  }

  factory AppointmentModel.fromMap(
      Map<String, dynamic> map,
      ) {
    return AppointmentModel(
      id: map['id'] as int?,
      userId:
      (map['userid'] as num?)?.toInt() ?? 0,
      serviceId:
      (map['serviceid'] as num?)?.toInt() ?? 0,
      providerId:
      (map['providerid'] as num?)?.toInt(),
      bookDate:
      map['bookdate']?.toString() ?? '',
      address:
      map['address']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      note: map['note']?.toString() ?? '',
      status:
      map['status']?.toString() ?? 'PENDING',
    );
  }
}
