import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/network_providers.dart';
import '../../data/inspections_providers.dart';
import '../../domain/entities/insurer.dart';

final insurersControllerProvider =
    AsyncNotifierProvider<InsurersController, List<Insurer>>(
      InsurersController.new,
    );

final class InsurersController extends AsyncNotifier<List<Insurer>> {
  @override
  Future<List<Insurer>> build() async {
    final session = await ref.read(sessionStorageProvider).readSession();

    if (session == null) {
      throw StateError('No existe una sesión activa.');
    }

    final insurers = await ref
        .read(insurersRepositoryProvider)
        .getInsurers(usuario: session.usuario);

    return [const Insurer(codigo: 0, nombre: 'Todas'), ...insurers];
  }

  Future<void> refresh() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(build);
  }
}
