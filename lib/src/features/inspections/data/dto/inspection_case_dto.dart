import '../../domain/entities/inspection_case.dart';

final class InspectionCaseDto {
  const InspectionCaseDto({
    this.insurerCode,
    required this.nroCaso,
    required this.nombre,
    required this.placa,
    required this.estado,
    required this.fechaInicio,
    required this.fechaFin,
    required this.asegurado,
    required this.identificacion,
    required this.celularAsegurado,
    required this.personaContacto,
    required this.telefonoContacto,
    required this.marca,
    required this.modelo,
    required this.observaciones,
    required this.colorBroker,
    required this.colorInspector,
  });

  factory InspectionCaseDto.fromJson(Map<String, dynamic> json) {
    final insurer = json['aseguradora'];
    if (json.containsKey('aseguradora') && (insurer is! int || insurer <= 0)) {
      throw const FormatException(
        'Consulta devolvió una aseguradora inválida.',
      );
    }
    final number = _toInt(_readField(json, 'nro_caso', 'nroCaso'));
    if (number <= 0) {
      throw const FormatException(
        'Consulta devolvió un número de caso ausente o inválido.',
      );
    }
    return InspectionCaseDto(
      insurerCode: insurer is int ? insurer : null,
      nroCaso: number,
      nombre: _toString(json['nombre']),
      placa: _toString(json['placa']),
      estado: _toString(
        json.containsKey('descripcion_estado')
            ? json['descripcion_estado']
            : json['estado'],
      ),
      fechaInicio: _toDate(
        _readField(
          json,
          'fecha_inicio',
          'fechaInicio',
          currentKey: 'fecha_ini',
        ),
      ),
      fechaFin: _toDate(_readField(json, 'fecha_fin', 'fechaFin')),
      asegurado: _toString(json['asegurado']),
      identificacion: _toString(
        json.containsKey('cedula') ? json['cedula'] : json['identificacion'],
      ),
      celularAsegurado: _toString(
        _readField(json, 'celular_asegurado', 'celularAsegurado'),
      ),
      personaContacto: _toString(
        _readField(json, 'persona_contacto', 'personaContacto'),
      ),
      telefonoContacto: _toString(
        _readField(json, 'telefono_contacto', 'telefonoContacto'),
      ),
      marca: _toString(json['marca']),
      modelo: _toString(json['modelo']),
      observaciones: _toString(
        json.containsKey('observaciones_casos')
            ? json['observaciones_casos']
            : json['observaciones'],
      ),
      colorBroker: _toString(
        _readField(
          json,
          'color_casos_broker',
          'colorCasosBroker',
          currentKey: 'color_broker',
        ),
      ),
      colorInspector: _toString(
        _readField(
          json,
          'color_casos_inspector',
          'colorCasosInspector',
          currentKey: 'color_inspector',
        ),
      ),
    );
  }

  final int nroCaso;
  // Nullable only for previously stored snapshots and older responses.
  final int? insurerCode;
  final String nombre;
  final String placa;
  final String estado;

  final DateTime? fechaInicio;
  final DateTime? fechaFin;

  final String asegurado;
  final String identificacion;
  final String celularAsegurado;

  final String personaContacto;
  final String telefonoContacto;

  final String marca;
  final String modelo;
  final String observaciones;

  final String colorBroker;
  final String colorInspector;

  Map<String, dynamic> toJson() => {
    if (insurerCode != null) 'aseguradora': insurerCode,
    'nro_caso': nroCaso,
    'nombre': nombre,
    'placa': placa,
    'estado': estado,
    'fecha_inicio': fechaInicio?.toIso8601String(),
    'fecha_fin': fechaFin?.toIso8601String(),
    'asegurado': asegurado,
    'identificacion': identificacion,
    'celular_asegurado': celularAsegurado,
    'persona_contacto': personaContacto,
    'telefono_contacto': telefonoContacto,
    'marca': marca,
    'modelo': modelo,
    'observaciones': observaciones,
    'color_casos_broker': colorBroker,
    'color_casos_inspector': colorInspector,
  };

  InspectionCase toDomain() {
    return InspectionCase(
      insurerCode: insurerCode,
      nroCaso: nroCaso,
      nombre: nombre,
      placa: placa,
      estado: estado,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      asegurado: asegurado,
      identificacion: identificacion,
      celularAsegurado: celularAsegurado,
      personaContacto: personaContacto,
      telefonoContacto: telefonoContacto,
      marca: marca,
      modelo: modelo,
      observaciones: observaciones,
      colorBroker: colorBroker,
      colorInspector: colorInspector,
    );
  }

  // Both wire formats were observed: legacy snake_case and mobile camelCase.
  static Object? _readField(
    Map<String, dynamic> json,
    String legacyKey,
    String mobileKey, {
    String? currentKey,
  }) => currentKey != null && json.containsKey(currentKey)
      ? json[currentKey]
      : json.containsKey(legacyKey)
      ? json[legacyKey]
      : json[mobileKey];

  static String _toString(dynamic value) {
    return value?.toString().trim() ?? '';
  }

  static int _toInt(dynamic value) {
    return switch (value) {
      int number => number,
      num number => number.toInt(),
      String value => int.tryParse(value.trim()) ?? 0,
      _ => 0,
    };
  }

  static DateTime? _toDate(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }
}
