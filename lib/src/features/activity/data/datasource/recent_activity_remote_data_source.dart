import 'package:dio/dio.dart';

import '../../domain/entities/recent_activity.dart';
import '../../../../core/config/pending_api_config.dart';

final class RecentActivityRemoteDataSource {
  const RecentActivityRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<RecentActivity>> getRecentActivity({
    required String usuario,
  }) async {
    final response = await _dio.get<dynamic>(
      'api/movil/actividad-reciente',
      queryParameters: <String, dynamic>{'usuario': usuario},
    );
    final data = response.data;
    if (data is! List) {
      throw const FormatException('La actividad reciente debe ser una lista.');
    }
    return List<RecentActivity>.unmodifiable(
      data.map((entry) {
        if (entry is! Map<String, dynamic>) {
          throw const FormatException('Registro de actividad inválido.');
        }
        final caseNumber = entry['caso'];
        final titulo = entry['titulo'];
        final estadoActual = entry['estadoActual'];
        final estadoSeguimiento = entry['estadoSeguimiento'];
        final rawDate = entry['fecha'];
        final fecha = rawDate is String ? DateTime.tryParse(rawDate) : null;
        if (caseNumber is! int ||
            caseNumber <= 0 ||
            titulo is! String ||
            estadoActual is! String ||
            estadoSeguimiento is! String ||
            fecha == null) {
          throw FormatException(
            'Actividad: campos inválidos '
            '(caso=${caseNumber.runtimeType}, titulo=${titulo.runtimeType}, '
            'estadoActual=${estadoActual.runtimeType}, '
            'estadoSeguimiento=${estadoSeguimiento.runtimeType}, '
            'fecha=${rawDate.runtimeType}, fechaValida=${fecha != null}).',
          );
        }
        final insurer = entry[PendingApiConfig.insurerField];
        if (insurer is! int || insurer <= 0) {
          throw const FormatException('Aseguradora de actividad inválida.');
        }
        return RecentActivity(
          insurerCode: insurer,
          caseNumber: caseNumber,
          titulo: titulo,
          estadoActual: estadoActual,
          estadoSeguimiento: estadoSeguimiento,
          fecha: fecha,
        );
      }),
    );
  }
}
