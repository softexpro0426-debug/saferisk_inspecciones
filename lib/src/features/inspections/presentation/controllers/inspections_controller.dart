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

  InspectionFilter get filter => _filter;

  @override
  Future<List<InspectionCase>> build() {
    return _search();
  }

  Future<List<InspectionCase>> _search() async {
    final session = await ref.read(sessionStorageProvider).readSession();

    if (session == null) {
      throw StateError('No existe sesión activa.');
    }

    final repository = ref.read(inspectionsRepositoryProvider);

    return repository.search(usuario: session.usuario, filter: _filter);
  }

  Future<void> applyFilter(InspectionFilter filter) async {
    _filter = filter;

    state = const AsyncLoading();

    state = await AsyncValue.guard(_search);
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(_search);
  }

  Future<void> clearFilters() async {
    _filter = const InspectionFilter();

    state = const AsyncLoading();

    state = await AsyncValue.guard(_search);
  }
}
