library;

abstract final class ApiConfig {
  /// Production BFF — never call ServiceBox from the app.
  static const String baseUrl = String.fromEnvironment(
    'YAKITLA_API_BASE',
    defaultValue: 'https://yakitla.vercel.app',
  );

  static const String supportEmail = 'support@arusoft.com';
  static const String privacyUrl = 'https://yakitla.vercel.app/privacy';
  static const String termsUrl = 'https://yakitla.vercel.app/terms';
  static const String defaultCityId = '34';
}
