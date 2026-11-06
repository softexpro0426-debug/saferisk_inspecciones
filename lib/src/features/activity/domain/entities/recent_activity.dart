final class RecentActivity {
  const RecentActivity({
    required this.caseNumber,
    required this.titulo,
    required this.estadoActual,
    required this.estadoSeguimiento,
    required this.fecha,
    required this.insurerCode,
  });

  final int insurerCode;
  final int caseNumber;
  final String titulo;
  final String estadoActual;
  final String estadoSeguimiento;
  final DateTime fecha;
}
