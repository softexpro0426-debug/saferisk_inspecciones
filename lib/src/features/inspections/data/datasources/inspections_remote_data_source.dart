import 'package:dio/dio.dart';

import '../../domain/entities/inspection_filter.dart';
import '../dto/consultation_request_dto.dart';
import '../dto/consultation_response_dto.dart';

abstract interface class InspectionsRemoteDataSource {
  Future<ConsultationResponseDto> search({
    required String usuario,
    required InspectionFilter filter,
  });
}

final class InspectionsRemoteDataSourceImpl
    implements InspectionsRemoteDataSource {
  InspectionsRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<ConsultationResponseDto> search({
    required String usuario,
    required InspectionFilter filter,
  }) async {
    final request = ConsultationRequestDto.fromFilter(
      filter: filter,
      usuario: usuario,
    );

    final response = await _dio.post<dynamic>(
      'api/movil/consulta',
      data: request.toJson(),
    );

    final data = response.data;

    if (data is Map<String, dynamic>) {
      return ConsultationResponseDto.fromJson(data);
    }

    if (data is Map) {
      return ConsultationResponseDto.fromJson(Map<String, dynamic>.from(data));
    }

    throw const FormatException(
      'La respuesta de Consulta no tiene el formato esperado.',
    );
  }
}
