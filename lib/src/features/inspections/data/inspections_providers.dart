import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saferisk_inspecciones/src/core/network/flowconnect_dio_provider.dart'
    show flowConnectDioProvider;

import '../../../core/network/network_providers.dart';
import '../domain/repositories/inspections_repository.dart';
import 'datasources/inspections_remote_data_source.dart';
import '../data/repositories/inspections_repository_impl.dart';
import '../domain/repositories/insurers_repository.dart';
import 'datasources/insurers_remote_data_source.dart';
import 'repositories/insurers_repository_impl.dart';
import '../domain/repositories/en_route_repository.dart';
import 'datasources/en_route_remote_data_source.dart';
import 'repositories/en_route_repository_impl.dart';

final inspectionsRemoteDataSourceProvider =
    Provider<InspectionsRemoteDataSource>((ref) {
      return InspectionsRemoteDataSourceImpl(ref.watch(dioProvider));
    });

final inspectionsRepositoryProvider = Provider<InspectionsRepository>((ref) {
  return InspectionsRepositoryImpl(
    ref.watch(inspectionsRemoteDataSourceProvider),
  );
});
final insurersRemoteDataSourceProvider = Provider<InsurersRemoteDataSource>((
  ref,
) {
  return InsurersRemoteDataSourceImpl(ref.watch(dioProvider));
});

final insurersRepositoryProvider = Provider<InsurersRepository>((ref) {
  return InsurersRepositoryImpl(ref.watch(insurersRemoteDataSourceProvider));
});

final enRouteRemoteDataSourceProvider = Provider<EnRouteRemoteDataSource>((
  ref,
) {
  return EnRouteRemoteDataSourceImpl(ref.watch(flowConnectDioProvider));
});

final enRouteRepositoryProvider = Provider<EnRouteRepository>((ref) {
  return EnRouteRepositoryImpl(
    remoteDataSource: ref.watch(enRouteRemoteDataSourceProvider),
  );
});
