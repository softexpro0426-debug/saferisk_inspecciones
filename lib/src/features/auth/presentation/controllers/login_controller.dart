import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/network_providers.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_type.dart';
import 'login_state.dart';

final loginControllerProvider = NotifierProvider<LoginController, LoginState>(
  LoginController.new,
);

final class LoginController extends Notifier<LoginState> {
  @override
  LoginState build() {
    return const LoginIdle();
  }

  Future<void> login({required String usuario, required String clave}) async {
    if (state is LoginSubmitting) {
      return;
    }

    final cleanUser = usuario.trim();

    if (cleanUser.isEmpty || clave.isEmpty) {
      state = const LoginFailure('Ingresa usuario y contraseña.');
      return;
    }

    state = const LoginSubmitting();

    try {
      final session = await ref
          .read(authRepositoryProvider)
          .login(usuario: cleanUser, clave: clave);

      final userType = UserType.fromApi(session.tipoUsuario);

      switch (userType) {
        case UserType.inspector:
          await ref.read(sessionStorageProvider).saveSession(session);

        case UserType.broker:
        case UserType.unknown:
          await ref.read(sessionStorageProvider).clearSession();
      }

      state = LoginSuccess(session: session);
    } on AuthException catch (error) {
      state = LoginFailure(error.message);
    } catch (_) {
      state = const LoginFailure(
        'Ocurrió un error inesperado al iniciar sesión.',
      );
    }
  }

  void clearError() {
    if (state is LoginFailure) {
      state = const LoginIdle();
    }
  }
}
