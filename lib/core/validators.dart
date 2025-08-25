String? validateEmail(String? v) {
  final x = v?.trim() ?? '';
  if (x.isEmpty) return 'Email required';
  final ok = RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(x);
  return ok ? null : 'Enter a valid email';
}

String? validatePassword(String? v) =>
    (v == null || v.isEmpty) ? 'Password required' : null;

String? validateNonEmpty(String label, String? v) =>
    (v == null || v.trim().isEmpty) ? '$label required' : null;
