import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/auth/domain/entities/user_session.dart';

final class SessionStorage {
  SessionStorage(this._storage);

  final FlutterSecureStorage _storage;

  static const _usuarioKey = 'session_usuario';
  static const _nombreUsuarioKey = 'session_nombre_usuario';
  static const _tipoUsuarioKey = 'session_tipo_usuario';

  Future<void> saveSession(UserSession session) async {
    await Future.wait([
      _storage.write(key: _usuarioKey, value: session.usuario),
      _storage.write(key: _nombreUsuarioKey, value: session.nombreUsuario),
      _storage.write(key: _tipoUsuarioKey, value: session.tipoUsuario),
    ]);
  }

  Future<UserSession?> readSession() async {
    final values = await Future.wait([
      _storage.read(key: _usuarioKey),
      _storage.read(key: _nombreUsuarioKey),
      _storage.read(key: _tipoUsuarioKey),
    ]);

    final usuario = values[0];
    final nombreUsuario = values[1];
    final tipoUsuario = values[2];

    if (usuario == null ||
        usuario.isEmpty ||
        nombreUsuario == null ||
        nombreUsuario.isEmpty) {
      return null;
    }

    return UserSession(
      usuario: usuario,
      nombreUsuario: nombreUsuario,
      tipoUsuario: tipoUsuario ?? '',
    );
  }

  Future<bool> hasSession() async {
    return await readSession() != null;
  }

  Future<void> clearSession() async {
    await Future.wait([
      _storage.delete(key: _usuarioKey),
      _storage.delete(key: _nombreUsuarioKey),
      _storage.delete(key: _tipoUsuarioKey),
    ]);
  }
}
