class AppValidator {
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName tidak boleh kosong';
    }
    return null;
  }

  static String? validateNumber(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName tidak boleh kosong';
    }
    final number = num.tryParse(value);
    if (number == null) {
      return '$fieldName harus berupa angka';
    }
    return null;
  }

  static String? validatePercentage(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName tidak boleh kosong';
    }
    final number = int.tryParse(value);
    if (number == null || number < 0 || number > 100) {
      return '$fieldName harus di antara 0 dan 100';
    }
    return null;
  }
}
