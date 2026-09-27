import 'package:dio/dio.dart';

import '../../../../core/security/session_storage.dart';
import '../../domain/entities/user_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

final class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required SessionStorage sessionStorage,
  }) : _remoteDataSource = remoteDataSource,
       _sessionStorage = sessionStorage;

  final AuthRemoteDataSource _remoteDataSource;
  final SessionStorage _sessionStorage;

  @override
  Future<UserSession> login({
    required String usuario,
    required String clave,
  }) async {
    try {
      final cleanUser = usuario.trim();

      final response = await _remoteDataSource.login(
        usuario: cleanUser,
        clave: clave,
      );

      if (!response.respuesta) {
        throw const InvalidCredentialsException();
      }

      return UserSession(
        usuario: cleanUser,
        nombreUsuario: response.nombreUsuario,
        tipoUsuario: response.tipoUsuario,
      );
    } on InvalidCredentialsException {
      rethrow;
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  @override
  Future<UserSession?> getCurrentSession() {
    return _sessionStorage.readSession();
  }

  @override
  Future<void> logout() {
    return _sessionStorage.clearSession();
  }

  AuthException _mapDioException(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return const ConnectionException(
        'El servidor está tardando demasiado en responder.',
      );
    }

    if (error.type == DioExceptionType.connectionError) {
      return const ConnectionException(
        'No fue posible conectar con SafeRisk. Revisa tu conexión.',
      );
    }

    final statusCode = error.response?.statusCode;

    return switch (statusCode) {
      400 => const AuthServerException('La solicitud enviada no es válida.'),
      401 => const InvalidCredentialsException(),
      403 => const AuthServerException('No tienes autorización para ingresar.'),
      int code when code >= 500 => const AuthServerException(
        'El servidor SafeRisk no está disponible en este momento.',
      ),
      _ => const AuthServerException('No fue posible iniciar sesión.'),
    };
  }
}

sealed class AuthException implements Exception {
  const AuthException(this.message);

  final String message;
}

final class InvalidCredentialsException extends AuthException {
  const InvalidCredentialsException()
    : super('Usuario o contraseña incorrectos.');
}

final class ConnectionException extends AuthException {
  const ConnectionException(super.message);
}

final class AuthServerException extends AuthException {
  const AuthServerException(super.message);
}
