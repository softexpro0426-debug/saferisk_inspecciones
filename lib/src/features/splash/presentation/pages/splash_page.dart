import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/app_update/app_update_prompt.dart';
import '../../../../core/security/session_lock_controller.dart';
import '../controllers/splash_controller.dart';
import '../controllers/splash_state.dart';
import '../widgets/saferisk_brand.dart';

final class SplashPage extends ConsumerWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(sessionLockProvider, (_, access) {
      if (access.isUnlocked &&
          ref.read(splashControllerProvider).asData?.value
              is SplashAuthenticated) {
        context.go('/home');
      }
    });
    ref.listen(splashControllerProvider, (previous, next) {
      next.whenData((splashState) {
        switch (splashState) {
          case SplashAuthenticated():
            if (ref.read(sessionLockProvider).isUnlocked) context.go('/home');

          case SplashUnauthenticated():
            context.go('/login');

          case SplashUpdateAvailable():
          case SplashLoading():
          case SplashFailure():
            break;
        }
      });
    });

    final state = ref.watch(splashControllerProvider);

    if (state.asData?.value case SplashUpdateAvailable(:final decision)) {
      return Scaffold(
        backgroundColor: AppColors.secondary,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: AppUpdatePrompt(
                decision: decision,
                onRetry: () =>
                    ref.read(splashControllerProvider.notifier).retry(),
                onContinue: () => ref
                    .read(splashControllerProvider.notifier)
                    .skipOptionalUpdate(),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.secondary,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const _BackgroundDecoration(),
            const Center(child: SafeRiskBrand()),
            Positioned(
              left: 24,
              right: 24,
              bottom: 36,
              child: state.when(
                loading: () => const _LoadingIndicator(),
                data: (value) {
                  if (value case SplashFailure(:final message)) {
                    return _SplashError(
                      message: message,
                      onRetry: () {
                        ref.read(splashControllerProvider.notifier).retry();
                      },
                    );
                  }

                  return const _LoadingIndicator();
                },
                error: (error, stackTrace) {
                  return _SplashError(
                    message: 'No fue posible iniciar SafeRisk.',
                    onRetry: () {
                      ref.read(splashControllerProvider.notifier).retry();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _BackgroundDecoration extends StatelessWidget {
  const _BackgroundDecoration();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.secondary, AppColors.primary],
        ),
      ),
    );
  }
}

final class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Preparando tu espacio de trabajo',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

final class _SplashError extends StatelessWidget {
  const _SplashError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: onRetry,
          style: TextButton.styleFrom(foregroundColor: AppColors.accent),
          child: const Text('Reintentar'),
        ),
      ],
    );
  }
}
