class ApiConfig {
  const ApiConfig._();

  static const _mobileBaseUrl =
      'https://breeding-brute-antirust.ngrok-free.dev/Mobile';

  static final loginUrl = Uri.parse('$_mobileBaseUrl/MobileLogin.php');
}
