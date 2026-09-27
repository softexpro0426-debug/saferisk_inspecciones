final class ConcludeServiceRequestDto {
  const ConcludeServiceRequestDto({
    required this.aseguradora,
    required this.usuario,
    required this.nroCaso,
  });

  final int aseguradora;
  final String usuario;
  final int nroCaso;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'Aseguradora': aseguradora,
      'Usuario': usuario,
      'Nro_Caso': nroCaso,
    };
  }
}
