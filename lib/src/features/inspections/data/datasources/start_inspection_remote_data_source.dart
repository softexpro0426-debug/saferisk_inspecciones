import 'package:dio/dio.dart';

import '../../../arrival/data/dto/confirm_arrival_request_dto.dart';
import '../../../../core/config/pending_api_config.dart';

final class StartInspectionRemoteDataSource {
  const StartInspectionRemoteDataSource(this._dio);
  final Dio _dio;

  Future<bool> start(ConfirmArrivalRequestDto request) async {
    // The confirmed start contract uses Fecha_hora_llegada too.
    final response = await _dio.post<dynamic>(
      PendingApiConfig.startInspectionPath,
      data: request.toJson(),
    );
    final data = response.data;
    if (data is! Map<String, dynamic> || data['respuesta'] is! bool) {
      throw const FormatException('Respuesta de inicio inválida.');
    }
    return data['respuesta'] == true;
  }
}
