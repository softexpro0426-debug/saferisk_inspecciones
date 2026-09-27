import 'package:dio/dio.dart';

import '../dto/confirm_arrival_request_dto.dart';
import '../dto/confirm_arrival_response_dto.dart';

abstract interface class ArrivalRemoteDataSource {
  Future<ConfirmArrivalResponseDto> confirmArrival({
    required ConfirmArrivalRequestDto request,
  });
}

final class ArrivalRemoteDataSourceImpl implements ArrivalRemoteDataSource {
  ArrivalRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<ConfirmArrivalResponseDto> confirmArrival({
    required ConfirmArrivalRequestDto request,
  }) async {
    final response = await _dio.post<dynamic>(
      'api/ConfirmaLlegada',
      data: request.toJson(),
    );

    final data = response.data;

    if (data is Map<String, dynamic>) {
      return ConfirmArrivalResponseDto.fromJson(data);
    }

    if (data is Map) {
      return ConfirmArrivalResponseDto.fromJson(
        Map<String, dynamic>.from(data),
      );
    }

    throw const FormatException(
      'La respuesta de ConfirmaLlegada no tiene el formato esperado.',
    );
  }
}
