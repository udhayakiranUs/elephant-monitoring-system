class Validators {
  Validators._();

  static String? required(String? v, [String field = 'This field']) =>
      (v == null || v.trim().isEmpty) ? '$field is required' : null;

  static String? latitude(String? v) {
    final n = double.tryParse((v ?? '').trim());
    if (n == null || n < -90 || n > 90) return 'Invalid latitude';
    return null;
  }

  static String? longitude(String? v) {
    final n = double.tryParse((v ?? '').trim());
    if (n == null || n < -180 || n > 180) return 'Invalid longitude';
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 4) return 'At least 4 characters';
    return null;
  }
}
