import 'inspection_case_dto.dart';

final class ConsultationResponseDto {
  const ConsultationResponseDto({required this.cases});

  factory ConsultationResponseDto.fromJson(Map<String, dynamic> json) {
    final rawCases = json['Casos'];

    if (rawCases is! List) {
      return const ConsultationResponseDto(cases: []);
    }

    return ConsultationResponseDto(
      cases: rawCases
          .whereType<Map>()
          .map(
            (item) =>
                InspectionCaseDto.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(growable: false),
    );
  }

  final List<InspectionCaseDto> cases;
}
