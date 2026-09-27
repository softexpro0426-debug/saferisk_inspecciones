import '../../domain/entities/insurer.dart';
import '../../domain/repositories/insurers_repository.dart';
import '../datasources/insurers_remote_data_source.dart';

final class InsurersRepositoryImpl implements InsurersRepository {
  InsurersRepositoryImpl(this._remoteDataSource);

  final InsurersRemoteDataSource _remoteDataSource;

  @override
  Future<List<Insurer>> getInsurers({required String usuario}) async {
    final result = await _remoteDataSource.getInsurers(usuario: usuario);

    return result.map((item) => item.toDomain()).toList(growable: false);
  }
}
