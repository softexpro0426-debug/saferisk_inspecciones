final class IngresoRequestDto {
  const IngresoRequestDto({
    required this.tipoProceso,
    required this.usuario,
    required this.clave,
    required this.nuevaClave,
  });

  factory IngresoRequestDto.login({
    required String usuario,
    required String clave,
  }) {
    return IngresoRequestDto(
      tipoProceso: 0,
      usuario: usuario,
      clave: clave,
      nuevaClave: '',
    );
  }

  final int tipoProceso;
  final String usuario;
  final String clave;
  final String nuevaClave;

  Map<String, dynamic> toJson() {
    return {
      'tipo_proceso': tipoProceso,
      'usuario': usuario,
      'clave': clave,
      'nueva_clave': nuevaClave,
    };
  }
}
