final class EnRouteResponseDto {
  const EnRouteResponseDto({required this.message});

  factory EnRouteResponseDto.fromJson(Map<String, dynamic> json) {
    return EnRouteResponseDto(
      message: json['mensaje']?.toString().trim() ?? '',
    );
  }

  final String message;

  bool get success {
    final normalized = message.trim().toLowerCase();

    return normalized.contains('guardado correctamente');
  }
}
