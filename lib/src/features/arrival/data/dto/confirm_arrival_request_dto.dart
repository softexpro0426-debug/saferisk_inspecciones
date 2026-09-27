final class ConfirmArrivalRequestDto {
  const ConfirmArrivalRequestDto({
    required this.aseguradora,
    required this.usuario,
    required this.nroCaso,
    required this.fechaHoraLlegada,
    required this.coordenadas,
  });

  final int aseguradora;
  final String usuario;
  final int nroCaso;
  final DateTime fechaHoraLlegada;
  final String coordenadas;

  Map<String, dynamic> toJson() {
    return {
      'Aseguradora': aseguradora,
      'Usuario': usuario,
      'Nro_Caso': nroCaso,
      'Fecha_hora_llegada': fechaHoraLlegada.toIso8601String(),
      'Coordenadas': coordenadas,
    };
  }
}
