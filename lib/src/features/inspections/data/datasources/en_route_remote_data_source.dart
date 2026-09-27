import 'package:dio/dio.dart';

import '../dto/en_route_request_dto.dart';
import '../dto/en_route_response_dto.dart';

abstract interface class EnRouteRemoteDataSource {
  Future<EnRouteResponseDto> markEnRoute({required EnRouteRequestDto request});
}

final class EnRouteRemoteDataSourceImpl implements EnRouteRemoteDataSource {
  const EnRouteRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<EnRouteResponseDto> markEnRoute({
    required EnRouteRequestDto request,
  }) async {
    final response = await _dio.post<dynamic>(
      'api/consulta/seguimiento',
      data: request.toJson(),
    );

    final data = response.data;

    if (data is Map<String, dynamic>) {
      return EnRouteResponseDto.fromJson(data);
    }

    if (data is Map) {
      return EnRouteResponseDto.fromJson(Map<String, dynamic>.from(data));
    }

    throw const FormatException(
      'La respuesta de seguimiento no tiene el formato esperado.',
    );
  }
}
