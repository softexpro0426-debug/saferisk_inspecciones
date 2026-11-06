import '../../../../core/app_update/app_version_policy.dart';

sealed class SplashState {
  const SplashState();
}

final class SplashLoading extends SplashState {
  const SplashLoading();
}

final class SplashAuthenticated extends SplashState {
  const SplashAuthenticated();
}

final class SplashUnauthenticated extends SplashState {
  const SplashUnauthenticated();
}

final class SplashFailure extends SplashState {
  const SplashFailure(this.message);

  final String message;
}

final class SplashUpdateAvailable extends SplashState {
  const SplashUpdateAvailable(this.decision);
  final AppUpdateDecision decision;
}
