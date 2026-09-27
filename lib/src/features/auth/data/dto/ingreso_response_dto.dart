final class IngresoResponseDto {
  const IngresoResponseDto({
    required this.respuesta,
    required this.tipoUsuario,
    required this.nombreUsuario,
  });

  factory IngresoResponseDto.fromJson(Map<String, dynamic> json) {
    return IngresoResponseDto(
      respuesta: _parseBool(json['respuesta']),
      tipoUsuario: json['tipo_usuario']?.toString().trim() ?? '',
      nombreUsuario: json['nombre_usuario']?.toString().trim() ?? '',
    );
  }

  final bool respuesta;
  final String tipoUsuario;
  final String nombreUsuario;

  static bool _parseBool(dynamic value) {
    return switch (value) {
      true => true,
      false => false,
      1 => true,
      0 => false,
      String value =>
        value.toLowerCase().trim() == 'true' || value.trim() == '1',
      _ => false,
    };
  }
}
