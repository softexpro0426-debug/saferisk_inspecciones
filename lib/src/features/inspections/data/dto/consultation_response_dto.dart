import 'inspection_case_dto.dart';

final class ConsultationResponseDto {
  const ConsultationResponseDto({required this.cases});

  factory ConsultationResponseDto.fromJson(Map<String, dynamic> json) {
    final rawCases = json.containsKey('Casos') ? json['Casos'] : json['casos'];

    if (rawCases is! List) {
      throw const FormatException(
        'La respuesta no contiene una lista Casos/casos válida.',
      );
    }

    return ConsultationResponseDto(
      cases: rawCases
          .map((item) {
            if (item is! Map) {
              throw const FormatException(
                'La lista Casos contiene un registro inválido.',
              );
            }
            return InspectionCaseDto.fromJson(Map<String, dynamic>.from(item));
          })
          .toList(growable: false),
    );
  }

  final List<InspectionCaseDto> cases;
}
