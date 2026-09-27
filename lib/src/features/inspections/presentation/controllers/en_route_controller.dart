import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/location/location_providers.dart';
import '../../../../core/network/network_providers.dart';
import '../../data/inspections_providers.dart';

import '../../data/repositories/inspection_workflow_storage.dart';

final enRouteControllerProvider = AsyncNotifierProvider.autoDispose
    .family<EnRouteController, bool, int>(EnRouteController.new);

final class EnRouteController extends AsyncNotifier<bool> {
  EnRouteController(this.caseNumber);

  final int caseNumber;
  bool _serverConfirmed = false;
  void Function()? _release;

  @override
  Future<bool> build() async {
    if (caseNumber <= 0) {
      return false;
    }

    return ref.read(inspectionWorkflowStorageProvider).isEnRoute(caseNumber);
  }

  Future<bool> markEnRoute({required int insurerCode}) async {
    if (state.isLoading) {
      return false;
    }

    final alreadyRegistered = switch (state) {
      AsyncData(:final value) => value,
      _ => false,
    };

    if (alreadyRegistered) {
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

        await ref
            .read(enRouteRepositoryProvider)
            .markEnRoute(
              user: session.usuario,
              insurerCode: insurerCode,
              caseNumber: caseNumber,
              coordinates: coordinates,
            );

        _serverConfirmed = true;
      }
      await ref.read(inspectionWorkflowStorageProvider).markEnRoute(caseNumber);

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
