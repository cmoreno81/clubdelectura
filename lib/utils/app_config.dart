class AppConfig {
  static const String baseUrl = String.fromEnvironment(
    'CLUBREADS_API_BASE_URL',
    defaultValue: 'https://clubreads-backend-production.up.railway.app/api',
  );
}
