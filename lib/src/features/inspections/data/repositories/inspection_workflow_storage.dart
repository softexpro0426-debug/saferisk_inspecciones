import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final inspectionWorkflowStorageProvider = Provider<InspectionWorkflowStorage>(
  (ref) => InspectionWorkflowStorage(),
);

enum _WorkflowStatus { assigned, enRoute, arrived, completed }

final class InspectionWorkflowStorage {
  // Serialize read/modify/write operations to avoid regressing a case's state.
  Future<void> _pending = Future<void>.value();

  String _key(int caseNumber) => 'inspection_workflow_${caseNumber}_status';

  Future<_WorkflowStatus> _read(int caseNumber) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getString(_key(caseNumber));
    for (final status in _WorkflowStatus.values) {
      if (status.name == saved) return status;
    }
    // Preserve statuses saved by previous app versions.
    final prefix = 'inspection_workflow_$caseNumber';
    if (preferences.getBool('${prefix}_completed') == true) {
      return _WorkflowStatus.completed;
    }
    if (preferences.getBool('${prefix}_arrival') == true ||
        preferences.getBool('${prefix}_inspection_started') == true) {
      return _WorkflowStatus.arrived;
    }
    if (preferences.getBool('${prefix}_en_route') == true) {
      return _WorkflowStatus.enRoute;
    }
    return _WorkflowStatus.assigned;
  }

  Future<bool> isEnRoute(int caseNumber) async =>
      (await _read(caseNumber)).index >= _WorkflowStatus.enRoute.index;

  Future<bool> isArrivalConfirmed(int caseNumber) async =>
      (await _read(caseNumber)).index >= _WorkflowStatus.arrived.index;

  Future<bool> isCompleted(int caseNumber) async =>
      await _read(caseNumber) == _WorkflowStatus.completed;

  Future<void> markEnRoute(int caseNumber) =>
      _advance(caseNumber, _WorkflowStatus.enRoute);

  Future<void> markArrivalConfirmed(int caseNumber) =>
      _advance(caseNumber, _WorkflowStatus.arrived);

  Future<void> markCompleted(int caseNumber) =>
      _advance(caseNumber, _WorkflowStatus.completed);

  Future<void> _advance(int caseNumber, _WorkflowStatus status) {
    final operation = _pending.then((_) async {
      final current = await _read(caseNumber);
      if (current.index >= status.index) return;
      final preferences = await SharedPreferences.getInstance();
      if (!await preferences.setString(_key(caseNumber), status.name)) {
        throw StateError('No fue posible guardar el estado del caso.');
      }
    });
    _pending = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }
}
