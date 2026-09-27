import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../domain/repositories/inspection_form_repository.dart';

import 'datasources/inspection_form_remote_data_source.dart';
import 'repositories/inspection_form_repository_impl.dart';

final inspectionFormRemoteDataSourceProvider =
    Provider<InspectionFormRemoteDataSource>((ref) {
      return InspectionFormRemoteDataSourceImpl(ref.watch(dioProvider));
    });

final inspectionFormRepositoryProvider = Provider<InspectionFormRepository>((
  ref,
) {
  return InspectionFormRepositoryImpl(
    ref.watch(inspectionFormRemoteDataSourceProvider),
  );
});
