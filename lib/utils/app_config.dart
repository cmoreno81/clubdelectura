class AppConfig {
  static const bool useLocalBackend = false;

  static String get baseUrl => useLocalBackend
      ? 'http://localhost:3000/api'
      : 'https://clubreads-backend-production.up.railway.app/api';
}
