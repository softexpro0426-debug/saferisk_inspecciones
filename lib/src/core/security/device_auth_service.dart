import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';

final deviceAuthServiceProvider = Provider<DeviceAuthService>((ref) {
  return DeviceAuthService();
});

final class SessionUnlockFailure implements Exception {
  const SessionUnlockFailure(this.message);
  final String message;
}

final class SessionLockedException implements Exception {
  const SessionLockedException();
}

final class DeviceAuthService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> authenticate({required bool biometricOnly}) async {
    try {
      if (biometricOnly) {
        if (!await _auth.canCheckBiometrics ||
            (await _auth.getAvailableBiometrics()).isEmpty) {
          throw const SessionUnlockFailure(
            'Configura la biometría del teléfono o elige otra forma de acceso.',
          );
        }
      } else if (!await _auth.isDeviceSupported()) {
        throw const SessionUnlockFailure(
          'Configura el bloqueo del teléfono o usa tu usuario y contraseña.',
        );
      }
      return await _auth.authenticate(
        localizedReason: 'Verifica tu identidad para desbloquear SafeRisk.',
        biometricOnly: biometricOnly,
        persistAcrossBackgrounding: false,
        authMessages: const [
          AndroidAuthMessages(
            signInTitle: 'Desbloquear SafeRisk',
            cancelButton: 'Cancelar',
          ),
          IOSAuthMessages(cancelButton: 'Cancelar'),
        ],
      );
    } on LocalAuthException {
      throw const SessionUnlockFailure(
        'No pudimos verificar tu identidad. Inténtalo de nuevo o elige otra forma de acceso.',
      );
    }
  }
}
