import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/network_providers.dart';
import 'splash_state.dart';

final splashControllerProvider =
    AsyncNotifierProvider<SplashController, SplashState>(SplashController.new);

final class SplashController extends AsyncNotifier<SplashState> {
  @override
  Future<SplashState> build() async {
    return _bootstrap();
  }

  Future<SplashState> _bootstrap() async {
    try {
      final sessionStorage = ref.read(sessionStorageProvider);

      final session = await sessionStorage.readSession();

      if (session == null) {
        return const SplashUnauthenticated();
      }

      return const SplashAuthenticated();
    } catch (_) {
      return const SplashFailure('No fue posible inicializar SafeRisk.');
    }
  }

  Future<void> retry() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(_bootstrap);
  }
}
