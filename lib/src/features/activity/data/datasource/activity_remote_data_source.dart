import 'package:dio/dio.dart';

import '../../domain/entities/activity_case.dart';

final class ActivityRemoteDataSource {
  const ActivityRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<ActivityCase>> getCases({
    required String usuario,
    required String tipoConsulta,
  }) async {
    final response = await _dio.post<dynamic>(
      'api/Consulta',
      data: <String, dynamic>{
        'aseguradora': 0,
        'usuario': usuario,
        'tipo_consulta': tipoConsulta,
        'cedula': '',
        'placa': '',
        'nombre': '',
        'nro_caso': 0,
      },
    );

    final data = response.data;

    if (data is! Map) {
      throw const FormatException(
        'La respuesta de Consulta no tiene el formato esperado.',
      );
    }

    final rawCases = data['Casos'];

    if (rawCases == null) {
      return const <ActivityCase>[];
    }

    if (rawCases is! List) {
      throw const FormatException(
        'La propiedad Casos no contiene una lista válida.',
      );
    }

    return rawCases
        .whereType<Map>()
        .map((json) => _mapCase(Map<String, dynamic>.from(json)))
        .toList(growable: false);
  }

  ActivityCase _mapCase(Map<String, dynamic> json) {
    return ActivityCase(
      nroCaso: _readInt(json['nro_caso']),
      nombre: _readString(json['nombre']),
      asegurado: _readString(json['asegurado']),
      placa: _readString(json['placa']),
      estado: _readString(json['estado']),
      marca: _readString(json['marca']),
      modelo: _readString(json['modelo']),
      fechaFin: _readDate(json['fecha_fin']),
    );
  }

  int _readInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _readString(dynamic value) {
    return value?.toString().trim() ?? '';
  }

  DateTime? _readDate(dynamic value) {
    final text = value?.toString().trim() ?? '';

    if (text.isEmpty) {
      return null;
    }

    return DateTime.tryParse(text);
  }
}
