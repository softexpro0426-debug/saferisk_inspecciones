import 'package:go_router/go_router.dart';
import 'package:saferisk_inspecciones/src/features/main/presentation/pages/main_shell_page.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) {
        return const SplashPage();
      },
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) {
        return const LoginPage();
      },
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) {
        return const MainShellPage();
      },
    ),
  ],
);
