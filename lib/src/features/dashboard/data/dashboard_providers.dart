import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/flowconnect_dio_provider.dart';
import '../domain/repositories/dashboard_repository.dart';
import 'datasources/dashboard_remote_data_source.dart';
import 'repositories/dashboard_repository_impl.dart';

final dashboardRemoteDataSourceProvider = Provider<DashboardRemoteDataSource>((
  ref,
) {
  return DashboardRemoteDataSourceImpl(ref.watch(flowConnectDioProvider));
});

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepositoryImpl(ref.watch(dashboardRemoteDataSourceProvider));
});
