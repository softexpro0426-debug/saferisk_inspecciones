final class DashboardSummary {
  const DashboardSummary({
    required this.pendientes,
    required this.pendientesHoy,
    required this.finalizadas,
    required this.finalizadasSemana,
    required this.asignadas,
  });

  final int pendientes;
  final int pendientesHoy;
  final int finalizadas;
  final int finalizadasSemana;
  final int asignadas;
}
