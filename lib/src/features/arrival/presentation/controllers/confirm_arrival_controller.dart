import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/location/location_providers.dart';
import '../../../../core/network/network_providers.dart';
import '../../../inspections/data/repositories/inspection_workflow_storage.dart';
import '../../data/arrival_providers.dart';

final confirmArrivalControllerProvider = AsyncNotifierProvider.autoDispose
    .family<ConfirmArrivalController, bool, int>(ConfirmArrivalController.new);

final class ConfirmArrivalController extends AsyncNotifier<bool> {
  ConfirmArrivalController(this.caseNumber);

  final int caseNumber;
  bool _serverConfirmed = false;
  void Function()? _release;

  @override
  Future<bool> build() async {
    if (caseNumber <= 0) {
      return false;
    }

    return ref
        .read(inspectionWorkflowStorageProvider)
        .isArrivalConfirmed(caseNumber);
  }

  Future<bool> confirm({required int insurerCode}) async {
    if (state.isLoading) {
      return false;
    }

    final alreadyConfirmed = switch (state) {
      AsyncData(:final value) => value,
      _ => false,
    };

    if (alreadyConfirmed) {
      return true;
    }

    _release ??= ref.keepAlive().close;

    state = const AsyncLoading();

    try {
      if (!_serverConfirmed) {
        final session = await ref.read(sessionStorageProvider).readSession();

        if (session == null) {
          throw StateError('No existe una sesión activa.');
        }

        final locationService = ref.read(locationServiceProvider);

        final position = await locationService.getCurrentPosition();

        final coordinates = locationService.formatCoordinates(position);

        final result = await ref
            .read(arrivalRepositoryProvider)
            .confirmArrival(
              aseguradora: insurerCode,
              usuario: session.usuario,
              nroCaso: caseNumber,
              fechaHoraLlegada: DateTime.now(),
              coordenadas: coordinates,
            );

        if (!result) {
          state = const AsyncData(false);
          return false;
        }

        _serverConfirmed = true;
      }
      await ref
          .read(inspectionWorkflowStorageProvider)
          .markArrivalConfirmed(caseNumber);

      state = const AsyncData(true);

      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);

      return false;
    } finally {
      // Retain a server-confirmed result until its local write succeeds.
      // A retry must only retry storage, never send the mutation again.
      if (!_serverConfirmed || !state.hasError) {
        _release?.call();
        _release = null;
      }
    }
  }
}
