class Validators {
  static bool isValidEmail(String value) {
    final email = value.trim();
    return email.contains('@') && email.contains('.');
  }

  static bool isValidPassword(String value) {
    return value.trim().length >= 6;
  }
}
