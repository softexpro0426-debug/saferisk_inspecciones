import 'package:dio/dio.dart';

import '../../domain/repositories/en_route_repository.dart';
import '../datasources/en_route_remote_data_source.dart';
import '../dto/en_route_request_dto.dart';

final class EnRouteRepositoryImpl implements EnRouteRepository {
  const EnRouteRepositoryImpl({
    required EnRouteRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final EnRouteRemoteDataSource _remoteDataSource;

  @override
  Future<void> markEnRoute({
    required String user,
    required int insurerCode,
    required int caseNumber,
    required String coordinates,
  }) async {
    try {
      final response = await _remoteDataSource.markEnRoute(
        request: EnRouteRequestDto(
          user: user,
          insurerCode: insurerCode,
          caseNumber: caseNumber,
          coordinates: coordinates,
        ),
      );

      if (!response.success) {
        throw EnRouteException(
          response.message.isEmpty
              ? 'FlowConnect no confirmó el seguimiento.'
              : response.message,
        );
      }
    } on DioException catch (error) {
      throw EnRouteException(_resolveDioError(error));
    }
  }

  String _resolveDioError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'FlowConnect está tardando demasiado en responder.';
    }

    if (error.type == DioExceptionType.connectionError) {
      return 'No fue posible conectar con FlowConnect.';
    }

    return switch (error.response?.statusCode) {
      400 => 'FlowConnect rechazó los datos enviados.',
      401 => 'La autenticación con FlowConnect fue rechazada.',
      403 => 'No tienes autorización para registrar el seguimiento.',
      404 => 'No se encontró el servicio de seguimiento.',
      int code when code >= 500 =>
        'FlowConnect presenta un inconveniente temporal.',
      _ => 'No fue posible registrar el estado En camino.',
    };
  }
}

final class EnRouteException implements Exception {
  const EnRouteException(this.message);

  final String message;

  @override
  String toString() => message;
}
