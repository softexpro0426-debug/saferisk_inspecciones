import 'dart:convert';

import 'package:dio/dio.dart';

import '../dto/ingreso_request_dto.dart';
import '../dto/ingreso_response_dto.dart';

abstract interface class AuthRemoteDataSource {
  Future<IngresoResponseDto> login({
    required String usuario,
    required String clave,
  });
}

final class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<IngresoResponseDto> login({
    required String usuario,
    required String clave,
  }) async {
    final request = IngresoRequestDto.login(usuario: usuario, clave: clave);

    final response = await _dio.post<dynamic>(
      'api/Ingreso',
      data: request.toJson(),
      options: Options(
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,
        headers: const {'Accept': 'application/json'},
      ),
    );
    return IngresoResponseDto.fromJson(_normalizeResponse(response.data));
  }

  Map<String, dynamic> _normalizeResponse(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    if (data is String) {
      final decoded = jsonDecode(data);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    }

    throw FormatException(
      'Formato inesperado recibido de SafeRisk: ${data.runtimeType}',
    );
  }
}
