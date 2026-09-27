import 'package:dio/dio.dart';

import '../dto/conclude_service_request_dto.dart';
import '../dto/conclude_service_response_dto.dart';

abstract interface class InspectionFormRemoteDataSource {
  Future<ConcludeServiceResponseDto> concludeService({
    required ConcludeServiceRequestDto request,
  });
}

final class InspectionFormRemoteDataSourceImpl
    implements InspectionFormRemoteDataSource {
  const InspectionFormRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<ConcludeServiceResponseDto> concludeService({
    required ConcludeServiceRequestDto request,
  }) async {
    final response = await _dio.post<dynamic>(
      'api/ConcluirServicio',
      data: request.toJson(),
    );

    final data = response.data;

    if (data is Map<String, dynamic>) {
      return ConcludeServiceResponseDto.fromJson(data);
    }

    if (data is Map) {
      return ConcludeServiceResponseDto.fromJson(
        Map<String, dynamic>.from(data),
      );
    }

    throw const FormatException(
      'La respuesta de ConcluirServicio no tiene el formato esperado.',
    );
  }
}
