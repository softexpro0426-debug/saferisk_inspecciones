import '../../domain/entities/inspection_filter.dart';

final class ConsultationRequestDto {
  const ConsultationRequestDto({
    required this.aseguradora,
    required this.usuario,
    required this.tipoConsulta,
    required this.cedula,
    required this.placa,
    required this.nombre,
    required this.nroCaso,
  });

  factory ConsultationRequestDto.fromFilter({
    required InspectionFilter filter,
    required String usuario,
  }) {
    return ConsultationRequestDto(
      aseguradora: filter.aseguradora,
      usuario: usuario.trim(),
      tipoConsulta: filter.tipoConsulta.trim(),
      cedula: filter.cedula.trim(),
      placa: filter.placa.trim().toUpperCase(),
      nombre: filter.nombre.trim(),
      nroCaso: filter.nroCaso,
    );
  }

  final int aseguradora;
  final String usuario;
  final String tipoConsulta;
  final String cedula;
  final String placa;
  final String nombre;
  final int nroCaso;

  Map<String, dynamic> toJson() {
    return {
      'Aseguradora': aseguradora,
      'Usuario': usuario,
      'Tipo_Consulta': tipoConsulta,
      'Cedula': cedula,
      'Placa': placa,
      'Nombre': nombre,
      'Nro_Caso': nroCaso.toString(),
    };
  }
}
