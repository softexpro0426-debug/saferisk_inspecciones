final class InspectionCase {
  const InspectionCase({
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

  final int nroCaso;
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
}
