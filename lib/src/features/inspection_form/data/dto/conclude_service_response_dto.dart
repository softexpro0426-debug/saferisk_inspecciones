final class ConcludeServiceResponseDto {
  const ConcludeServiceResponseDto({required this.respuesta});

  factory ConcludeServiceResponseDto.fromJson(Map<String, dynamic> json) {
    return ConcludeServiceResponseDto(respuesta: json['respuesta'] == true);
  }

  final bool respuesta;
}
