import '../entities/inspection_case.dart';
import '../entities/inspection_filter.dart';

abstract interface class InspectionsRepository {
  Future<List<InspectionCase>> search({
    required String usuario,
    required InspectionFilter filter,
  });
}
