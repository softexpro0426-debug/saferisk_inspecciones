final class EnRouteRequestDto {
  const EnRouteRequestDto({
    required this.user,
    required this.insurerCode,
    required this.caseNumber,
    required this.coordinates,
  });

  final String user;
  final int insurerCode;
  final int caseNumber;
  final String coordinates;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'usuario': user,
      'aseguradora': insurerCode.toString(),
      'caso': caseNumber,
      'estado': 'EnCamino',
      'coordenadas': coordinates,
    };
  }
}
