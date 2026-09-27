import '../../domain/entities/insurer.dart';

final class InsurerDto {
  const InsurerDto({required this.codigo, required this.nombre});

  factory InsurerDto.fromJson(Map<String, dynamic> json) {
    return InsurerDto(
      codigo: _toInt(json['codigo']),
      nombre: json['nombre']?.toString().trim() ?? '',
    );
  }

  final int codigo;
  final String nombre;

  Insurer toDomain() {
    return Insurer(codigo: codigo, nombre: nombre);
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
