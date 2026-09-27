import '../../domain/entities/dashboard_summary.dart';

final class DashboardDto {
  const DashboardDto({
    required this.pendientes,
    required this.pendientesHoy,
    required this.finalizadas,
    required this.finalizadasSemana,
    required this.asignadas,
  });

  factory DashboardDto.fromJson(Map<String, dynamic> json) {
    return DashboardDto(
      pendientes: _toInt(json['pendientes']),
      pendientesHoy: _toInt(json['pendientes_hoy']),
      finalizadas: _toInt(json['finalizadas']),
      finalizadasSemana: _toInt(json['finalizadas_semana']),
      asignadas: _toInt(json['asignadas_count']),
    );
  }

  final int pendientes;
  final int pendientesHoy;
  final int finalizadas;
  final int finalizadasSemana;
  final int asignadas;

  DashboardSummary toDomain() {
    return DashboardSummary(
      pendientes: pendientes,
      pendientesHoy: pendientesHoy,
      finalizadas: finalizadas,
      finalizadasSemana: finalizadasSemana,
      asignadas: asignadas,
    );
  }

  static int _toInt(dynamic value) {
    return switch (value) {
      int number => number,
      num number => number.toInt(),
      String value => int.tryParse(value) ?? 0,
      _ => 0,
    };
  }
}
