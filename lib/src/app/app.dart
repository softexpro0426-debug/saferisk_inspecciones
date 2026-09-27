import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/security/session_expired.dart';

import '../core/config/app_config.dart';
import '../core/theme/app_theme.dart';
import 'router/app_router.dart';

final class SafeRiskApp extends ConsumerWidget {
  const SafeRiskApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(sessionExpiredProvider, (_, expired) {
      if (expired) {
        appRouter.go('/login');
        ref.read(sessionExpiredProvider.notifier).reset();
      }
    });
    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}
