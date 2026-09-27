final class ActivityCase {
  const ActivityCase({
    required this.nroCaso,
    required this.nombre,
    required this.asegurado,
    required this.placa,
    required this.estado,
    required this.marca,
    required this.modelo,
    required this.fechaFin,
  });

  final int nroCaso;
  final String nombre;
  final String asegurado;
  final String placa;
  final String estado;
  final String marca;
  final String modelo;

  final DateTime? fechaFin;

  String get displayName {
    final insured = asegurado.trim();

    if (insured.isNotEmpty) {
      return insured;
    }

    final fallback = nombre.trim();

    if (fallback.isNotEmpty) {
      return fallback;
    }

    return 'Sin asegurado';
  }

  String get vehicle {
    return [
      placa.trim().toUpperCase(),
      marca.trim(),
      modelo.trim(),
    ].where((value) => value.isNotEmpty).join(' · ');
  }
}
