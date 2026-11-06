import 'inspection_case.dart';

enum OperationalStatus {
  assigned('ASIGNADO', 'Asignado', 'En camino'),
  enRoute('EN_CAMINO', 'En camino', 'Confirmar llegada'),
  arrived('LLEGADA_CONFIRMADA', 'Llegada confirmada', 'Iniciar inspección'),
  started('INICIADO', 'Inspección iniciada', 'Finalizar inspección'),
  completed('FINALIZADO', 'Finalizado', null);

  const OperationalStatus(this.apiValue, this.label, this.nextAction);
  final String apiValue;
  final String label;
  final String? nextAction;

  static OperationalStatus parse(Object? value) {
    for (final status in values) {
      if (value == status.apiValue) return status;
    }
    throw const FormatException('Estado operativo desconocido.');
  }

  OperationalStatus get following =>
      this == completed ? completed : values[index + 1];
}

typedef WorkflowQuery = ({int caseNumber, int insurerCode});

final class OperationalInspection {
  const OperationalInspection({
    required this.inspection,
    required this.insurerCode,
    required this.status,
    required this.usuario,
  });
  final InspectionCase inspection;
  final int insurerCode;
  final OperationalStatus status;
  final String usuario;

  OperationalInspection withStatus(OperationalStatus value) =>
      OperationalInspection(
        inspection: inspection,
        insurerCode: insurerCode,
        status: value,
        usuario: usuario,
      );
}

final class WorkflowView {
  const WorkflowView({
    required this.item,
    this.needsRefresh = false,
    this.busy = false,
    this.message,
  });
  final OperationalInspection item;
  final bool needsRefresh;
  final bool busy;
  final String? message;
}

final class WorkflowException implements Exception {
  const WorkflowException(this.message);
  final String message;
}
