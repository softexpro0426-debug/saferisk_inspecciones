import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/location/location_providers.dart';
import '../../../../core/network/network_error_message.dart';
import '../../../../core/network/network_providers.dart';
import '../../../activity/presentation/controller/recent_activity_controller.dart';
import '../../../arrival/data/arrival_providers.dart';
import '../../../arrival/data/dto/confirm_arrival_request_dto.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../../inspection_form/data/inspection_form_providers.dart';
import '../../data/datasources/start_inspection_remote_data_source.dart';
import '../../data/inspections_providers.dart';
import '../../data/repositories/operational_inspection_repository.dart';
import '../../domain/entities/operational_inspection.dart';
import 'inspections_controller.dart';

final operationalInspectionRepositoryProvider =
    Provider<OperationalInspectionRepository>((ref) {
      return OperationalInspectionRepository(
        ref.watch(inspectionsRemoteDataSourceProvider),
        ref.watch(secureStorageProvider),
        ref.watch(recentActivityRemoteDataSourceProvider),
      );
    });

final operationalWorkflowProvider = AsyncNotifierProvider.autoDispose
    .family<OperationalWorkflowController, WorkflowView, WorkflowQuery>(
      OperationalWorkflowController.new,
      retry: (_, _) => null,
    );

final class OperationalWorkflowController extends AsyncNotifier<WorkflowView> {
  OperationalWorkflowController(this.query);
  final WorkflowQuery query;
  bool _busy = false;
  OperationalStatus? _confirmedFloor;

  @override
  Future<WorkflowView> build() async {
    if (query.caseNumber <= 0 || query.insurerCode < 0) {
      throw const WorkflowException('El número de caso no es válido.');
    }
    final user = await _user();
    final repository = ref.read(operationalInspectionRepositoryProvider);
    try {
      return WorkflowView(item: await repository.fetch(user, query));
    } on FormatException catch (error) {
      if (kDebugMode) {
        debugPrint('[INSPECCION] Error de formato: ${error.message}');
      }
      rethrow;
    } on DioException catch (error) {
      final offline =
          error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          (error.response?.statusCode ?? 0) >= 500;
      if (!offline) rethrow;
      final cached = await repository.readCached(user, query);
      if (cached == null) rethrow;
      return WorkflowView(
        item: cached,
        needsRefresh: true,
        message: 'Revisa tu conexión y vuelve a intentarlo para continuar.',
      );
    }
  }

  Future<String> _user() async {
    final session = await ref.read(sessionStorageProvider).readSession();
    if (session == null) {
      throw const WorkflowException('Inicia sesión nuevamente.');
    }
    return session.usuario;
  }

  String _message(Object error) =>
      error is WorkflowException ? error.message : networkErrorMessage(error);

  Future<void> refresh() async {
    if (_busy) return;
    _busy = true;
    final link = ref.keepAlive();
    final previous = state.asData?.value;
    if (previous != null) {
      state = AsyncData(
        WorkflowView(item: previous.item, busy: true, needsRefresh: true),
      );
    } else {
      state = const AsyncLoading();
    }
    try {
      final item = await ref
          .read(operationalInspectionRepositoryProvider)
          .fetch(await _user(), query, minimumStatus: _confirmedFloor);
      state = AsyncData(WorkflowView(item: item));
    } catch (error, stack) {
      state = previous == null
          ? AsyncError(error, stack)
          : AsyncData(
              WorkflowView(
                item: previous.item,
                needsRefresh: true,
                message: _message(error),
              ),
            );
    } finally {
      _busy = false;
      link.close();
    }
  }

  Future<OperationalStatus?> advance(OperationalStatus expected) async {
    final previous = state.asData?.value;
    if (_busy ||
        previous == null ||
        previous.needsRefresh ||
        previous.item.status != expected ||
        expected == OperationalStatus.completed) {
      return null;
    }
    _busy = true;
    final link = ref.keepAlive();
    var current = previous.item;
    state = AsyncData(WorkflowView(item: current, busy: true));
    try {
      final user = await _user();
      if (user != current.usuario) {
        throw const WorkflowException(
          'La sesión cambió. Vuelve a abrir el caso.',
        );
      }
      // Reconcile before every mutation, including after a confirmation dialog.
      final repository = ref.read(operationalInspectionRepositoryProvider);
      current = await repository.fetch(
        user,
        query,
        minimumStatus: _confirmedFloor,
      );
      if (current.status != expected) {
        state = AsyncData(
          WorkflowView(
            item: current,
            message: 'El estado del caso cambió. Revisa la siguiente acción.',
          ),
        );
        return current.status;
      }

      String coordinates = '';
      if (expected != OperationalStatus.started) {
        final location = ref.read(locationServiceProvider);
        coordinates = location.formatCoordinates(
          await ref.refresh(currentPositionProvider.future),
        );
      }
      bool success;
      switch (expected) {
        case OperationalStatus.assigned:
          await ref
              .read(enRouteRepositoryProvider)
              .markEnRoute(
                user: user,
                insurerCode: current.insurerCode,
                caseNumber: current.inspection.nroCaso,
                coordinates: coordinates,
              );
          success = true;
        case OperationalStatus.enRoute:
          success = await ref
              .read(arrivalRepositoryProvider)
              .confirmArrival(
                aseguradora: current.insurerCode,
                usuario: user,
                nroCaso: current.inspection.nroCaso,
                fechaHoraLlegada: DateTime.now(),
                coordenadas: coordinates,
              );
        case OperationalStatus.arrived:
          success = await StartInspectionRemoteDataSource(ref.read(dioProvider))
              .start(
                ConfirmArrivalRequestDto(
                  aseguradora: current.insurerCode,
                  usuario: user,
                  nroCaso: current.inspection.nroCaso,
                  fechaHoraLlegada: DateTime.now(),
                  coordenadas: coordinates,
                ),
              );
        case OperationalStatus.started:
          success = await ref
              .read(inspectionFormRepositoryProvider)
              .concludeService(
                aseguradora: current.insurerCode,
                usuario: user,
                nroCaso: current.inspection.nroCaso,
              );
        case OperationalStatus.completed:
          return OperationalStatus.completed;
      }
      if (!success) {
        throw const WorkflowException(
          'No pudimos guardar el avance. Vuelve a intentarlo.',
        );
      }
      current = current.withStatus(expected.following);
      _confirmedFloor = current.status;
      // Persist the confirmed step even if the following GET/POST lookup fails.
      await repository.recordConfirmed(user, query, current.status);
      ref.invalidate(inspectionsControllerProvider);
      ref.invalidate(dashboardControllerProvider);
      ref.invalidate(recentActivityControllerProvider);
      // A confirmed conclusion is terminal. A delayed activity feed or failed
      // detail refresh must not turn a successful conclusion into a retry.
      if (current.status == OperationalStatus.completed) {
        state = AsyncData(WorkflowView(item: current));
        return OperationalStatus.completed;
      }
      final refreshed = await repository.fetch(
        user,
        query,
        minimumStatus: _confirmedFloor,
      );
      state = AsyncData(WorkflowView(item: refreshed));
      return refreshed.status;
    } catch (error) {
      state = AsyncData(
        WorkflowView(
          item: current,
          needsRefresh: true,
          message: _message(error),
        ),
      );
      return null;
    } finally {
      _busy = false;
      link.close();
    }
  }
}
