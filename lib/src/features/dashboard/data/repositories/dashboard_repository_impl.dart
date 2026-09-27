import '../../domain/entities/dashboard_summary.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_remote_data_source.dart';

final class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl(this._remoteDataSource);

  final DashboardRemoteDataSource _remoteDataSource;

  @override
  Future<DashboardSummary> getDashboard({required String usuario}) async {
    final dto = await _remoteDataSource.getDashboard(usuario: usuario);

    return dto.toDomain();
  }
}
