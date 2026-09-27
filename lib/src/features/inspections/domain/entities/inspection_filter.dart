final class InspectionFilter {
  const InspectionFilter({
    this.aseguradora = 0,
    this.aseguradoraNombre = '',
    this.tipoConsulta = 'C',
    this.cedula = '',
    this.placa = '',
    this.nombre = '',
    this.nroCaso = 0,
  });

  final int aseguradora;
  final String aseguradoraNombre;
  final String tipoConsulta;
  final String cedula;
  final String placa;
  final String nombre;
  final int nroCaso;

  InspectionFilter copyWith({
    int? aseguradora,
    String? aseguradoraNombre,
    String? tipoConsulta,
    String? cedula,
    String? placa,
    String? nombre,
    int? nroCaso,
  }) {
    return InspectionFilter(
      aseguradora: aseguradora ?? this.aseguradora,
      aseguradoraNombre: aseguradoraNombre ?? this.aseguradoraNombre,
      tipoConsulta: tipoConsulta ?? this.tipoConsulta,
      cedula: cedula ?? this.cedula,
      placa: placa ?? this.placa,
      nombre: nombre ?? this.nombre,
      nroCaso: nroCaso ?? this.nroCaso,
    );
  }
}
