import '../../../../core/config/pending_api_config.dart';
import '../../domain/entities/operational_inspection.dart';
import 'inspection_case_dto.dart';

abstract final class OperationalInspectionDto {
  static OperationalInspection parse(
    Map<String, dynamic> json, {
    required String usuario,
  }) {
    final insurer = json[PendingApiConfig.insurerField];
    final number = json['nro_caso'];
    if (insurer is! int || insurer <= 0 || number is! int || number <= 0) {
      throw const FormatException('Identidad de caso inválida.');
    }
    return OperationalInspection(
      inspection: InspectionCaseDto.fromJson(json).toDomain(),
      insurerCode: insurer,
      status: OperationalStatus.parse(json[PendingApiConfig.workflowField]),
      usuario: usuario,
    );
  }
}
