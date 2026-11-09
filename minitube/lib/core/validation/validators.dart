class Validators {
  static String? requiredText(String? value, {int min = 1, int max = 120}) {
    final text = (value ?? '').trim();
    if (text.length < min || text.length > max) {
      return 'Enter $min–$max characters.';
    }
    return null;
  }

  static String? email(String? value) {
    final text = (value ?? '').trim();
    return text.length <= 254 &&
            RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text)
        ? null
        : 'Enter a valid email address.';
  }

  static String? password(String? value) {
    final text = value ?? '';
    return text.length >= 8 &&
            text.length <= 64 &&
            RegExp('[A-Za-z]').hasMatch(text) &&
            RegExp('[0-9]').hasMatch(text)
        ? null
        : 'Use 8–64 characters with letters and numbers.';
  }

  static String? httpsUrl(String? value, {bool required = false}) {
    final text = (value ?? '').trim();
    if (text.isEmpty && !required) return null;
    final uri = Uri.tryParse(text);
    return text.length <= 2048 &&
            uri != null &&
            uri.scheme == 'https' &&
            uri.host.isNotEmpty &&
            uri.userInfo.isEmpty
        ? null
        : 'Enter a valid HTTPS URL (up to 2,048 characters).';
  }
}
