import '../../domain/entities/inspection_case.dart';

final class InspectionCaseDto {
  const InspectionCaseDto({
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
    return InspectionCaseDto(
      nroCaso: _toInt(json['nro_caso']),
      nombre: _toString(json['nombre']),
      placa: _toString(json['placa']),
      estado: _toString(json['estado']),
      fechaInicio: _toDate(json['fecha_inicio']),
      fechaFin: _toDate(json['fecha_fin']),
      asegurado: _toString(json['asegurado']),
      identificacion: _toString(json['identificacion']),
      celularAsegurado: _toString(json['celular_asegurado']),
      personaContacto: _toString(json['persona_contacto']),
      telefonoContacto: _toString(json['telefono_contacto']),
      marca: _toString(json['marca']),
      modelo: _toString(json['modelo']),
      observaciones: _toString(json['observaciones']),
      colorBroker: _toString(json['color_casos_broker']),
      colorInspector: _toString(json['color_casos_inspector']),
    );
  }

  final int nroCaso;
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

  InspectionCase toDomain() {
    return InspectionCase(
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

  static String _toString(dynamic value) {
    return value?.toString().trim() ?? '';
  }

  static int _toInt(dynamic value) {
    return switch (value) {
      int number => number,
      num number => number.toInt(),
      String value => int.tryParse(value) ?? 0,
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
