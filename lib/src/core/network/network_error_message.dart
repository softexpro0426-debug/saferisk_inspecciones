import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../security/device_auth_service.dart';

String networkErrorMessage(Object error) {
  if (error is SessionLockedException ||
      (error is DioException && error.error is SessionLockedException)) {
    return 'Desbloquea tu sesión para continuar.';
  }
  if (error is AppConfigurationException) {
    return 'No se pudo habilitar la conexión con SafeRisk. '
        'Contacta al administrador para revisar la configuración de la aplicación.';
  }
  if (error is FormatException) {
    return 'El servidor devolvió una respuesta que no se pudo interpretar. '
        'Inténtalo nuevamente o contacta al administrador.';
  }
  if (error is DioException) {
    if (error.response?.statusCode == 401) {
      if (error.requestOptions.baseUrl == AppConfig.flowConnectBaseUrl) {
        return 'SafeRisk no autorizó esta consulta. Contacta al administrador.';
      }
      return 'Tu sesión expiró. Inicia sesión nuevamente.';
    }
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        'La conexión está tardando demasiado. Inténtalo nuevamente.',
      DioExceptionType.connectionError =>
        'No fue posible conectar. Revisa tu conexión a internet.',
      _ => 'No fue posible completar la operación. Inténtalo nuevamente.',
    };
  }
  return 'No fue posible completar la operación. Inténtalo nuevamente.';
}
