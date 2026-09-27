import 'package:geolocator/geolocator.dart';

final class LocationService {
  Future<Position> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw const LocationServiceDisabledException();
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const LocationPermissionException('Permiso de ubicación denegado.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationPermissionException(
        'El permiso de ubicación está bloqueado permanentemente.',
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );
  }

  String formatCoordinates(Position position) {
    return '${position.latitude},${position.longitude}';
  }
}

final class LocationPermissionException implements Exception {
  const LocationPermissionException(this.message);

  final String message;

  @override
  String toString() => message;
}
