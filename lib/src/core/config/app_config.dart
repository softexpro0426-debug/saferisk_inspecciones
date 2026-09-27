abstract final class AppConfig {
  static const String appName = 'SafeRisk Inspecciones';

  // API antigua / principal
  static const String apiBaseUrl = 'https://sistema.saferisk.ec/SW_APP/';

  // API FlowConnect
  static const String flowConnectBaseUrl =
      'https://sistema.saferisk.ec/flowconnect/';

  static const String flowConnectApiKey = String.fromEnvironment(
    'FLOWCONNECT_API_KEY',
  );

  static const Duration connectTimeout = Duration(seconds: 10);

  static const Duration receiveTimeout = Duration(seconds: 20);

  static const Duration sendTimeout = Duration(seconds: 20);
}
