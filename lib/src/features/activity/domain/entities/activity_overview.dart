import '../../../inspections/domain/entities/activity_workflow_resolver.dart';
import '../../../inspections/domain/entities/operational_inspection.dart';
import 'recent_activity.dart';

/// History stays intact; only the newest row per insurer/case controls access.
final class ActivityOverview {
  ActivityOverview(List<RecentActivity> events) {
    final ordered = [...events]..sort((a, b) => b.fecha.compareTo(a.fecha));
    history = List.unmodifiable(ordered);
    final latest = <(int, int), RecentActivity>{};
    for (final event in ordered) {
      latest.putIfAbsent((event.insurerCode, event.caseNumber), () => event);
    }
    inProgress = List.unmodifiable(
      latest.values.where((event) {
        final status = ActivityWorkflowResolver.knownStatus(event.estadoActual);
        return status == OperationalStatus.enRoute ||
            status == OperationalStatus.arrived ||
            status == OperationalStatus.started;
      }),
    );
  }

  late final List<RecentActivity> history;
  late final List<RecentActivity> inProgress;
}
