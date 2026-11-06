import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/config/pending_api_config.dart';
import '../../domain/entities/inspection_filter.dart';
import '../../domain/entities/operational_inspection.dart';
import '../datasources/inspections_remote_data_source.dart';
import '../dto/inspection_case_dto.dart';
import '../dto/operational_inspection_dto.dart';
import '../../../activity/data/datasource/recent_activity_remote_data_source.dart';
import '../../domain/entities/activity_workflow_resolver.dart';

final class OperationalInspectionRepository {
  const OperationalInspectionRepository(
    this._inspections,
    this._storage,
    this._activity,
  );
  final RecentActivityRemoteDataSource _activity;
  final InspectionsRemoteDataSource _inspections;
  final FlutterSecureStorage _storage;

  String _key(String user, WorkflowQuery query) =>
      'operational_case_v2_${Uri.encodeComponent(user)}_'
      '${query.insurerCode}_${query.caseNumber}';

  Future<OperationalInspection> fetch(
    String user,
    WorkflowQuery query, {
    OperationalStatus? minimumStatus,
  }) async {
    InspectionCaseDto? assignedDetail;
    List<InspectionCaseDto> initialMatches = const [];
    {
      final consultation = await _inspections.search(
        usuario: user,
        filter: InspectionFilter(
          aseguradora: query.insurerCode,
          nroCaso: query.caseNumber,
          tipoConsulta: 'C',
        ),
      );
      final candidates = consultation.cases
          .where(
            (item) =>
                item.nroCaso == query.caseNumber &&
                (query.insurerCode == 0 ||
                    item.insurerCode == null ||
                    item.insurerCode == query.insurerCode),
          )
          .toList();
      initialMatches = candidates;
      if (candidates.length == 1) assignedDetail = candidates.single;
      if (assignedDetail != null &&
          ActivityWorkflowResolver.knownStatus(assignedDetail.estado) ==
              OperationalStatus.assigned) {
        final insurerCode = assignedDetail.insurerCode ?? query.insurerCode;
        if (insurerCode <= 0) {
          throw const WorkflowException(
            'Selecciona la aseguradora en los filtros de Inspecciones para abrir este caso.',
          );
        }
        final cached = await readCached(user, (
          caseNumber: query.caseNumber,
          insurerCode: insurerCode,
        ));
        if ((minimumStatus?.index ?? 0) > OperationalStatus.assigned.index ||
            (cached?.status.index ?? 0) > OperationalStatus.assigned.index) {
          throw const WorkflowException(
            'No pudimos actualizar el avance. Vuelve a intentarlo para continuar.',
          );
        }
        return _saveSnapshot(
          user,
          query,
          assignedDetail,
          insurerCode,
          OperationalStatus.assigned,
        );
      }
    }
    final events = await _activity.getRecentActivity(usuario: user);
    final latest = ActivityWorkflowResolver.latest(
      events,
      query.caseNumber,
      query.insurerCode,
    );
    final status = ActivityWorkflowResolver.status(latest);
    final cached = await readCached(user, query);
    final persistedFloor = cached?.status;
    final floor = minimumStatus == null
        ? persistedFloor
        : persistedFloor != null && persistedFloor.index > minimumStatus.index
        ? persistedFloor
        : minimumStatus;
    if (floor != null && status.index < floor.index) {
      throw const WorkflowException(
        'No pudimos actualizar el avance. Vuelve a intentarlo para continuar.',
      );
    }
    final matches = <InspectionCaseDto>[];
    final sameInsurer = query.insurerCode == latest.insurerCode;
    if (sameInsurer) {
      matches.addAll(initialMatches);
    }
    // Consulta categories are independent of the inspector's operational step.
    // Use the same source and parser as Inspecciones, retaining case and insurer.
    for (final type in sameInsurer ? const ['P'] : const ['C', 'P']) {
      if (matches.isNotEmpty) break;
      final response = await _inspections.search(
        usuario: user,
        filter: InspectionFilter(
          aseguradora: latest.insurerCode,
          nroCaso: query.caseNumber,
          tipoConsulta: type,
        ),
      );
      matches.addAll(
        response.cases.where(
          (item) =>
              item.nroCaso == query.caseNumber &&
              (item.insurerCode == null ||
                  item.insurerCode == latest.insurerCode),
        ),
      );
    }
    if (matches.isEmpty) {
      throw WorkflowException(
        'La consulta no devolvió el caso ${query.caseNumber} de la '
        'aseguradora ${latest.insurerCode}. Actualiza e inténtalo nuevamente.',
      );
    }
    if (matches.length != 1) {
      throw const WorkflowException(
        'No se pudo identificar la aseguradora del caso. '
        'Ábrelo desde Inspecciones seleccionando su aseguradora.',
      );
    }
    return _saveSnapshot(
      user,
      query,
      matches.single,
      latest.insurerCode,
      status,
    );
  }

  Future<OperationalInspection> _saveSnapshot(
    String user,
    WorkflowQuery query,
    InspectionCaseDto detail,
    int insurerCode,
    OperationalStatus status,
  ) async {
    if (insurerCode <= 0 ||
        (detail.insurerCode != null && detail.insurerCode != insurerCode) ||
        (query.insurerCode > 0 && query.insurerCode != insurerCode)) {
      throw const WorkflowException(
        'No pudimos verificar la aseguradora de esta inspección. Actualiza e inténtalo de nuevo.',
      );
    }
    // Keep the snapshot format and verify the insurer before adding progress.
    final snapshot = <String, dynamic>{
      ...detail.toJson(),
      PendingApiConfig.insurerField: insurerCode,
      PendingApiConfig.workflowField: status.apiValue,
    };
    final item = OperationalInspectionDto.parse(snapshot, usuario: user);
    try {
      await _storage.write(key: _key(user, query), value: jsonEncode(snapshot));
    } catch (_) {
      // A local cache failure must not discard an authoritative server result.
    }
    return item;
  }

  Future<void> recordConfirmed(
    String user,
    WorkflowQuery query,
    OperationalStatus status,
  ) async {
    try {
      final text = await _storage.read(key: _key(user, query));
      if (text == null) return;
      final data = jsonDecode(text);
      if (data is! Map<String, dynamic>) return;
      data[PendingApiConfig.workflowField] = status.apiValue;
      await _storage.write(key: _key(user, query), value: jsonEncode(data));
    } catch (_) {
      // The server already confirmed; keep the in-memory state authoritative.
    }
  }

  Future<OperationalInspection?> readCached(
    String user,
    WorkflowQuery query,
  ) async {
    final keys = [
      _key(user, query),
      // Older openings from "Todas" used 0 in the key. Verify the stored
      // insurer before recovering that snapshot for a concrete insurer.
      if (query.insurerCode > 0)
        _key(user, (caseNumber: query.caseNumber, insurerCode: 0)),
    ];
    for (final key in keys) {
      try {
        final text = await _storage.read(key: key);
        if (text == null) continue;
        final json = jsonDecode(text);
        if (json is! Map<String, dynamic>) continue;
        final item = OperationalInspectionDto.parse(json, usuario: user);
        if (item.inspection.nroCaso != query.caseNumber ||
            (query.insurerCode != 0 && item.insurerCode != query.insurerCode)) {
          continue;
        }
        return item;
      } catch (_) {
        // Try the compatible snapshot without changing or deleting its data.
      }
    }
    return null;
  }
}
