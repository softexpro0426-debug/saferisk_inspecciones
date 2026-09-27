import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/network_providers.dart';
import "../../domain/entities/dashboard_summary.dart";
import "../../data/dashboard_providers.dart";

final dashboardControllerProvider =
    AsyncNotifierProvider<DashboardController, DashboardSummary>(
      DashboardController.new,
    );

final class DashboardController extends AsyncNotifier<DashboardSummary> {
  @override
  Future<DashboardSummary> build() async {
    return _load();
  }

  Future<DashboardSummary> _load() async {
    final sessionStorage = ref.read(sessionStorageProvider);

    final session = await sessionStorage.readSession();

    if (session == null) {
      throw StateError('No existe una sesión activa.');
    }

    return ref
        .read(dashboardRepositoryProvider)
        .getDashboard(usuario: session.usuario);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(_load);
  }
}
