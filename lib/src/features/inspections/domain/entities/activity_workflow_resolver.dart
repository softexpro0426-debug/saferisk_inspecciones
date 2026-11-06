import '../../../activity/domain/entities/recent_activity.dart';
import 'operational_inspection.dart';

/// Inspector progress is monotonic and ends only with INSPECCIÓN FINALIZADA.
/// Business events do not reset an already confirmed operational step.
abstract final class ActivityWorkflowResolver {
  static OperationalStatus? knownStatus(String value) {
    return switch (value.trim().toUpperCase()) {
      'ASIGNADO' => OperationalStatus.assigned,
      'INSPECTOR EN CAMINO' => OperationalStatus.enRoute,
      'INSPECTOR EN SITIO DE INSPECCIÓN' => OperationalStatus.arrived,
      'INSPECCIÓN INICIADA' => OperationalStatus.started,
      'INSPECCIÓN FINALIZADA' => OperationalStatus.completed,
      _ => null,
    };
  }

  static RecentActivity latest(
    List<RecentActivity> events,
    int caseNumber,
    int insurerCode,
  ) {
    final matches = events
        .where(
          (event) =>
              event.caseNumber == caseNumber &&
              (insurerCode == 0 || event.insurerCode == insurerCode),
        )
        .toList();
    if (matches.isEmpty) {
      throw const WorkflowException(
        'No pudimos cargar el avance de esta inspección. Vuelve a intentarlo.',
      );
    }
    if (matches.map((event) => event.insurerCode).toSet().length != 1) {
      throw const WorkflowException(
        'Selecciona la aseguradora para identificar el caso.',
      );
    }
    matches.sort((a, b) => b.fecha.compareTo(a.fecha));
    // Prefer the current case state over the historical movement of a row.
    if (knownStatus(matches.first.estadoActual) != null) {
      return matches.first;
    }
    final operational = matches
        .where((event) => knownStatus(event.estadoSeguimiento) != null)
        .toList();
    if (operational.isEmpty) {
      throw const WorkflowException(
        'No pudimos cargar el avance de esta inspección. Vuelve a intentarlo.',
      );
    }
    operational.sort((a, b) {
      final progress = knownStatus(
        b.estadoSeguimiento,
      )!.index.compareTo(knownStatus(a.estadoSeguimiento)!.index);
      return progress != 0 ? progress : b.fecha.compareTo(a.fecha);
    });
    return operational.first;
  }

  static OperationalStatus status(RecentActivity event) =>
      knownStatus(event.estadoActual) ??
      knownStatus(event.estadoSeguimiento) ??
      (throw const WorkflowException(
        'No se pudo determinar el avance del caso.',
      ));
}
