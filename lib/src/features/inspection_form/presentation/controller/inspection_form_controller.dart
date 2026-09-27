import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/network_providers.dart';
import '../../../inspections/data/repositories/inspection_workflow_storage.dart';
import '../../data/inspection_form_providers.dart';

final inspectionFormControllerProvider = AsyncNotifierProvider.autoDispose
    .family<InspectionFormController, bool, int>(InspectionFormController.new);

final class InspectionFormController extends AsyncNotifier<bool> {
  InspectionFormController(this.caseNumber);

  final int caseNumber;
  bool _serverConfirmed = false;
  void Function()? _release;

  @override
  Future<bool> build() {
    return ref.read(inspectionWorkflowStorageProvider).isCompleted(caseNumber);
  }

  Future<bool> conclude({required int insurerCode}) async {
    if (state.isLoading) return false;
    if (state.asData?.value == true) return true;
    if (insurerCode <= 0 || caseNumber <= 0) return false;

    _release ??= ref.keepAlive().close;
    final storage = ref.read(inspectionWorkflowStorageProvider);
    final repository = ref.read(inspectionFormRepositoryProvider);
    final sessions = ref.read(sessionStorageProvider);
    state = const AsyncLoading();

    try {
      if (!_serverConfirmed) {
        final session = await sessions.readSession();
        if (session == null) {
          throw StateError('No existe una sesión activa.');
        }
        if (!await storage.isArrivalConfirmed(caseNumber)) {
          throw StateError('Confirma la llegada antes de finalizar.');
        }
        final success = await repository.concludeService(
          aseguradora: insurerCode,
          usuario: session.usuario,
          nroCaso: caseNumber,
        );
        if (!success) {
          throw StateError('El servidor no confirmó la finalización.');
        }

        _serverConfirmed = true;
      }
      await storage.markCompleted(caseNumber);
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
