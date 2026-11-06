import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/network_providers.dart';
import '../../domain/entities/inspection_case.dart';
import '../../domain/entities/inspection_filter.dart';
import '../../data/inspections_providers.dart';

final inspectionsControllerProvider =
    AsyncNotifierProvider<InspectionsController, List<InspectionCase>>(
      InspectionsController.new,
    );

final class InspectionsController extends AsyncNotifier<List<InspectionCase>> {
  InspectionFilter _filter = const InspectionFilter();

  int _requestVersion = 0;

  InspectionFilter get filter => _filter;

  @override
  Future<List<InspectionCase>> build() {
    return _search(_filter);
  }

  Future<List<InspectionCase>> _search(InspectionFilter filter) async {
    final session = await ref.read(sessionStorageProvider).readSession();

    if (session == null) {
      throw StateError('No existe sesión activa.');
    }

    final repository = ref.read(inspectionsRepositoryProvider);

    return repository.search(usuario: session.usuario, filter: filter);
  }

  Future<void> applyFilter(InspectionFilter filter) async {
    _filter = filter;
    await refresh();
  }

  Future<void> refresh() async {
    final requestVersion = ++_requestVersion;
    final requestedFilter = _filter;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() => _search(requestedFilter));
    if (ref.mounted && requestVersion == _requestVersion) {
      state = result;
    }
  }

  Future<void> clearFilters() => applyFilter(const InspectionFilter());
}
