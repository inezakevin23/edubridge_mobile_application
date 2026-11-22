class Validators {
  Validators._();

  static String? email(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return 'Email is required.';
    final pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!pattern.hasMatch(input)) return 'Enter a valid email address.';
    return null;
  }

  static String? password(String? value) {
    final input = value ?? '';
    if (input.isEmpty) return 'Password is required.';
    if (input.length < 8) return 'Use at least 8 characters.';
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Please confirm your password.';
    if (value != password) return 'Passwords do not match.';
    return null;
  }

  static String? requiredText(String? value, {String label = 'This field'}) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return '$label is required.';
    if (input.length < 2) return '$label must contain at least 2 characters.';
    return null;
  }

  static String? website(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return null;
    final uri = Uri.tryParse(
      input.startsWith('http') ? input : 'https://$input',
    );
    if (uri == null || uri.host.isEmpty || !uri.host.contains('.')) {
      return 'Enter a valid website, for example example.com.';
    }
    return null;
  }
}
