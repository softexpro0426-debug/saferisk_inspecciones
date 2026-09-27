import 'package:dio/dio.dart';

String networkErrorMessage(Object error) {
  if (error is DioException) {
    if (error.response?.statusCode == 401) {
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
