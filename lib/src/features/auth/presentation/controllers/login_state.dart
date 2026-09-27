import '../../domain/entities/user_session.dart';

sealed class LoginState {
  const LoginState();
}

final class LoginIdle extends LoginState {
  const LoginIdle();
}

final class LoginSubmitting extends LoginState {
  const LoginSubmitting();
}

final class LoginSuccess extends LoginState {
  const LoginSuccess({required this.session});

  final UserSession session;
}

final class LoginFailure extends LoginState {
  const LoginFailure(this.message);

  final String message;
}
