import '../../domain/repositories/arrival_repository.dart';
import '../datasources/arrival_remote_data_source.dart';
import '../dto/confirm_arrival_request_dto.dart';

final class ArrivalRepositoryImpl implements ArrivalRepository {
  ArrivalRepositoryImpl(this._remoteDataSource);

  final ArrivalRemoteDataSource _remoteDataSource;

  @override
  Future<bool> confirmArrival({
    required int aseguradora,
    required String usuario,
    required int nroCaso,
    required DateTime fechaHoraLlegada,
    required String coordenadas,
  }) async {
    final response = await _remoteDataSource.confirmArrival(
      request: ConfirmArrivalRequestDto(
        aseguradora: aseguradora,
        usuario: usuario,
        nroCaso: nroCaso,
        fechaHoraLlegada: fechaHoraLlegada,
        coordenadas: coordenadas,
      ),
    );

    return response.respuesta;
  }
}
