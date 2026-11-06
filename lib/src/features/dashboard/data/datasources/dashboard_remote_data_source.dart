import 'package:dio/dio.dart';

import '../dto/dashboard_dto.dart';

abstract interface class DashboardRemoteDataSource {
  Future<DashboardDto> getDashboard({required String usuario});
}

final class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  DashboardRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<DashboardDto> getDashboard({required String usuario}) async {
    final cleanUser = usuario.trim();

    if (cleanUser.isEmpty) {
      throw ArgumentError.value(
        usuario,
        'usuario',
        'El usuario es obligatorio.',
      );
    }

    final response = await _dio.get<dynamic>(
      'api/movil/dashboard',
      queryParameters: {'usuario': cleanUser},
    );

    final data = response.data;

    if (data is Map<String, dynamic>) {
      return DashboardDto.fromJson(data);
    }

    if (data is Map) {
      return DashboardDto.fromJson(Map<String, dynamic>.from(data));
    }

    throw const FormatException(
      'La respuesta del Dashboard no tiene el formato esperado.',
    );
  }
}
