import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../domain/repositories/arrival_repository.dart';
import 'datasources/arrival_remote_data_source.dart';
import 'repositories/arrival_repository_impl.dart';

final arrivalRemoteDataSourceProvider = Provider<ArrivalRemoteDataSource>((
  ref,
) {
  return ArrivalRemoteDataSourceImpl(ref.watch(dioProvider));
});

final arrivalRepositoryProvider = Provider<ArrivalRepository>((ref) {
  return ArrivalRepositoryImpl(ref.watch(arrivalRemoteDataSourceProvider));
});
