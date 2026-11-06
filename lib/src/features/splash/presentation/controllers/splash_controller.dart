import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/network_providers.dart';
import 'splash_state.dart';
import '../../../../core/app_update/app_update_service.dart';

final splashControllerProvider =
    AsyncNotifierProvider<SplashController, SplashState>(SplashController.new);

final class SplashController extends AsyncNotifier<SplashState> {
  bool _checking = false;
  bool _skipOptional = false;

  @override
  Future<SplashState> build() async {
    return _bootstrap();
  }

  Future<SplashState> _bootstrap() async {
    try {
      try {
        final update = await ref.read(appUpdateServiceProvider).check();
        if (update != null && (update.required || !_skipOptional)) {
          return SplashUpdateAvailable(update);
        }
      } catch (_) {
        // Device/plugin failures must not prevent normal session startup.
      }
      final sessionStorage = ref.read(sessionStorageProvider);

      final session = await sessionStorage.restoreSession();

      if (session == null) {
        return const SplashUnauthenticated();
      }

      return const SplashAuthenticated();
    } catch (_) {
      return const SplashFailure('No fue posible inicializar SafeRisk.');
    }
  }

  Future<void> skipOptionalUpdate() async {
    final current = state.asData?.value;
    if (current is! SplashUpdateAvailable || current.decision.required) return;
    _skipOptional = true;
    await retry();
  }

  Future<void> retry() async {
    if (_checking) return;
    _checking = true;
    try {
      state = const AsyncLoading();

      state = await AsyncValue.guard(_bootstrap);
    } finally {
      _checking = false;
    }
  }
}
