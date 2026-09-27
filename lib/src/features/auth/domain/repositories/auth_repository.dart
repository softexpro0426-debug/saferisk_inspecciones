import '../entities/user_session.dart';

abstract interface class AuthRepository {
  Future<UserSession> login({required String usuario, required String clave});

  Future<UserSession?> getCurrentSession();

  Future<void> logout();
}
