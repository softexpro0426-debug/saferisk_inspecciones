import 'package:dio/dio.dart';

import '../dto/insurer_dto.dart';

abstract interface class InsurersRemoteDataSource {
  Future<List<InsurerDto>> getInsurers({required String usuario});
}

final class InsurersRemoteDataSourceImpl implements InsurersRemoteDataSource {
  InsurersRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<InsurerDto>> getInsurers({required String usuario}) async {
    final response = await _dio.post<dynamic>(
      'api/Aseguradoras',
      data: {'usuario': usuario.trim()},
    );

    final data = response.data;

    if (data is! Map) {
      throw const FormatException(
        'La respuesta de Aseguradoras no tiene el formato esperado.',
      );
    }

    final map = Map<String, dynamic>.from(data);
    final rawInsurers = map['Aseguradora'];

    if (rawInsurers is! List) {
      return const [];
    }

    return rawInsurers
        .whereType<Map>()
        .map((item) => InsurerDto.fromJson(Map<String, dynamic>.from(item)))
        .where((item) => item.codigo > 0 && item.nombre.isNotEmpty)
        .toList(growable: false);
  }
}
