import '../../domain/repositories/inspection_form_repository.dart';
import '../datasources/inspection_form_remote_data_source.dart';
import '../dto/conclude_service_request_dto.dart';

final class InspectionFormRepositoryImpl implements InspectionFormRepository {
  const InspectionFormRepositoryImpl(this._remoteDataSource);

  final InspectionFormRemoteDataSource _remoteDataSource;

  @override
  Future<bool> concludeService({
    required int aseguradora,
    required String usuario,
    required int nroCaso,
  }) async {
    final response = await _remoteDataSource.concludeService(
      request: ConcludeServiceRequestDto(
        aseguradora: aseguradora,
        usuario: usuario,
        nroCaso: nroCaso,
      ),
    );

    return response.respuesta;
  }
}
