import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/flowconnect_dio_provider.dart';
import '../../../../core/network/network_providers.dart';
import '../../data/datasource/recent_activity_remote_data_source.dart';
import '../../domain/entities/recent_activity.dart';

final recentActivityRemoteDataSourceProvider =
    Provider<RecentActivityRemoteDataSource>((ref) {
      return RecentActivityRemoteDataSource(ref.watch(flowConnectDioProvider));
    });

final recentActivityControllerProvider =
    AsyncNotifierProvider.autoDispose<
      RecentActivityController,
      List<RecentActivity>
    >(RecentActivityController.new);

final class RecentActivityController
    extends AsyncNotifier<List<RecentActivity>> {
  @override
  Future<List<RecentActivity>> build() => _load();

  Future<List<RecentActivity>> _load() async {
    final session = await ref.read(sessionStorageProvider).readSession();
    if (session == null) {
      throw StateError('No existe una sesión activa.');
    }
    return ref
        .read(recentActivityRemoteDataSourceProvider)
        .getRecentActivity(usuario: session.usuario);
  }

  Future<void> refresh() async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(_load);
    if (ref.mounted) state = result;
  }
}
