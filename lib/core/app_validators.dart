class AppValidators {
  AppValidators._();

  static String? requiredText(String? value, {String field = 'Thông tin'}) {
    if (value == null || value.trim().isEmpty) return 'Vui lòng nhập $field';
    return null;
  }

  static String? fullName(String? value) {
    final required = requiredText(value, field: 'họ và tên');
    if (required != null) return required;
    if (value!.trim().length < 2) return 'Họ và tên phải có ít nhất 2 ký tự';
    if (!RegExp(r"^[a-zA-ZÀ-ỹ\s.'-]+$").hasMatch(value.trim())) {
      return 'Họ và tên chứa ký tự không hợp lệ';
    }
    return null;
  }

  static String? phone(String? value, {bool required = true}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return required ? 'Vui lòng nhập số điện thoại' : null;
    if (!RegExp(r'^(0|\+84)[0-9]{9,10}$').hasMatch(text.replaceAll(' ', ''))) {
      return 'Số điện thoại không hợp lệ';
    }
    return null;
  }

  static String? email(String? value, {bool required = false}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return required ? 'Vui lòng nhập email' : null;
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text)) {
      return 'Email không hợp lệ';
    }
    return null;
  }

  static String? username(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Vui lòng nhập tên đăng nhập';
    if (text.length < 4) return 'Tên đăng nhập phải có ít nhất 4 ký tự';
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(text)) {
      return 'Chỉ dùng chữ, số và dấu gạch dưới';
    }
    return null;
  }

  static String? password(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Vui lòng nhập mật khẩu';
    if (text.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự';
    return null;
  }

  static String? address(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Vui lòng nhập địa chỉ';
    if (text.length < 8) return 'Địa chỉ cần cụ thể hơn';
    if (text.length > 200) return 'Địa chỉ không được vượt quá 200 ký tự';
    return null;
  }

  static String? positiveNumber(String? value, {String field = 'giá trị'}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Vui lòng nhập $field';
    final number = num.tryParse(text.replaceAll(',', '.'));
    if (number == null || number <= 0) return '$field phải lớn hơn 0';
    return null;
  }
}
