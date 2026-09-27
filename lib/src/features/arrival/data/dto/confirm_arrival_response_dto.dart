final class ConfirmArrivalResponseDto {
  const ConfirmArrivalResponseDto({required this.respuesta});

  factory ConfirmArrivalResponseDto.fromJson(Map<String, dynamic> json) {
    return ConfirmArrivalResponseDto(respuesta: json['respuesta'] == true);
  }

  final bool respuesta;
}
