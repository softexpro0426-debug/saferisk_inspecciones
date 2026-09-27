import '../../domain/entities/inspection_case.dart';
import '../../domain/entities/inspection_filter.dart';
import '../../domain/repositories/inspections_repository.dart';
import '../datasources/inspections_remote_data_source.dart';

final class InspectionsRepositoryImpl implements InspectionsRepository {
  InspectionsRepositoryImpl(this._remoteDataSource);

  final InspectionsRemoteDataSource _remoteDataSource;

  @override
  Future<List<InspectionCase>> search({
    required String usuario,
    required InspectionFilter filter,
  }) async {
    final response = await _remoteDataSource.search(
      usuario: usuario,
      filter: filter,
    );

    return response.cases.map((dto) => dto.toDomain()).toList(growable: false);
  }
}
