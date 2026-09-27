import 'package:dio/dio.dart';

import '../../domain/entities/recent_activity.dart';

final class RecentActivityRemoteDataSource {
  const RecentActivityRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<RecentActivity>> getRecentActivity({
    required String usuario,
  }) async {
    final response = await _dio.get<dynamic>(
      'api/consulta/actividad-reciente',
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
        final id = entry['id'];
        final titulo = entry['titulo'];
        final estado = entry['estado'];
        final rawDate = entry['fecha'];
        final fecha = rawDate is String ? DateTime.tryParse(rawDate) : null;
        if (id is! int ||
            titulo is! String ||
            estado is! String ||
            fecha == null) {
          throw const FormatException('Campos de actividad inválidos.');
        }
        return RecentActivity(
          id: id,
          titulo: titulo,
          estado: estado,
          fecha: fecha,
        );
      }),
    );
  }
}
