class AppConfig {
  static const apiBase =
      String.fromEnvironment('API_BASE', defaultValue: 'https://api.example.com');
  static const routeId =
      String.fromEnvironment('ROUTE_ID', defaultValue: 'riga_cocktail_v1');
}
