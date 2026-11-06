import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/security/session_expired.dart';
import '../core/security/session_gate.dart';
import '../core/security/session_lock_controller.dart';
import '../features/activity/presentation/controller/recent_activity_controller.dart';
import '../features/dashboard/presentation/controllers/dashboard_controller.dart';
import '../features/inspections/presentation/controllers/inspections_controller.dart';
import '../features/inspections/presentation/controllers/insurers_controller.dart';
import '../features/inspections/presentation/controllers/operational_workflow_controller.dart';
import '../features/profile/presentation/providers/profile_providers.dart';

import '../core/config/app_config.dart';
import '../core/theme/app_theme.dart';
import 'router/app_router.dart';

final class SafeRiskApp extends ConsumerWidget {
  const SafeRiskApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(sessionLockProvider, (previous, access) {
      if (previous?.usuario != access.usuario) {
        ref.invalidate(inspectionsControllerProvider);
        ref.invalidate(insurersControllerProvider);
        ref.invalidate(dashboardControllerProvider);
        ref.invalidate(recentActivityControllerProvider);
        ref.invalidate(operationalWorkflowProvider);
        ref.invalidate(profileSessionProvider);
      }
      if (previous?.hasSession == true &&
          access.access == SessionAccess.signedOut) {
        appRouter.go('/login');
      }
    });
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
      builder: (context, child) =>
          SessionGate(child: child ?? const SizedBox.shrink()),
    );
  }
}
