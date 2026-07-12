class Validators {
  static final RegExp _emailRegExp = RegExp(
    r"^[A-Za-z0-9.!#\$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)*$",
  );

  static bool isValidEmail(String value) {
    final email = value.trim();
    return email.isNotEmpty && _emailRegExp.hasMatch(email);
  }
}
