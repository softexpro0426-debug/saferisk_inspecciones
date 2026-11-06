import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/network/network_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/profile_providers.dart';
import 'terms_and_conditions_page.dart';

final class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(profileSessionProvider);
    final packageState = ref.watch(packageInfoProvider);
    final connectivityState = ref.watch(connectivityProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: sessionState.when(
          loading: () {
            return const _LoadingView();
          },
          error: (error, stackTrace) {
            return _SessionErrorView(
              onRetry: () {
                ref.invalidate(profileSessionProvider);
              },
            );
          },
          data: (session) {
            if (session == null) {
              return const _NoSessionView();
            }

            final userTypeLabel = _userTypeLabel(session.tipoUsuario);

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(profileSessionProvider);
                ref.invalidate(packageInfoProvider);

                await ref.read(profileSessionProvider.future);
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate.fixed([
                        const _Header(),

                        const SizedBox(height: 22),

                        _ProfileHero(
                          name: session.nombreUsuario,
                          username: session.usuario,
                          userType: userTypeLabel,
                        ),

                        const SizedBox(height: 16),

                        _ProfileSection(
                          title: 'Cuenta',
                          icon: Icons.person_outline_rounded,
                          children: [
                            _InfoRow(
                              label: 'Nombre',
                              value: session.nombreUsuario,
                            ),
                            _InfoRow(label: 'Usuario', value: session.usuario),
                            _InfoRow(label: 'Perfil', value: userTypeLabel),
                          ],
                        ),

                        const SizedBox(height: 14),

                        _ConnectionCard(state: connectivityState),

                        const SizedBox(height: 14),

                        _AppInfoCard(state: packageState),

                        const SizedBox(height: 14),

                        _ProfileSection(
                          title: 'Legal',
                          icon: Icons.gavel_outlined,
                          children: [
                            _LegalOption(
                              icon: Icons.description_outlined,
                              title: 'Términos y condiciones',
                              subtitle:
                                  'Consulta las condiciones de uso de SafeRisk.',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) {
                                      return const TermsAndConditionsPage();
                                    },
                                  ),
                                );
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        _LogoutCard(
                          onTap: () {
                            _requestLogout(context: context, ref: ref);
                          },
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _userTypeLabel(String value) {
    return switch (value.trim().toUpperCase()) {
      'I' || 'INSPECTOR' || 'INSPECTORES' => 'Inspector',
      'B' || 'BROKER' || 'BROKERS' => 'Broker',
      _ => 'Usuario',
    };
  }

  Future<void> _requestLogout({
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    HapticFeedback.mediumImpact();

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          icon: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.logout_rounded,
              color: Colors.red,
              size: 28,
            ),
          ),
          title: const Text('Cerrar sesión', textAlign: TextAlign.center),
          content: const Text(
            '¿Deseas cerrar tu sesión en este dispositivo?',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.neutralDark, height: 1.45),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Cerrar sesión'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    await ref.read(sessionStorageProvider).clearSession();
  }
}

final class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Perfil',
          style: TextStyle(
            color: AppColors.secondary,
            fontSize: 25,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 5),
        Text(
          'Información de tu cuenta y aplicación.',
          style: TextStyle(color: AppColors.neutralDark, fontSize: 13),
        ),
      ],
    );
  }
}

final class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.name,
    required this.username,
    required this.userType,
  });

  final String name;
  final String username;
  final String userType;

  @override
  Widget build(BuildContext context) {
    final displayName = name.trim().isEmpty ? username.trim() : name.trim();

    final initials = _resolveInitials(displayName);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.secondary, AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName.isEmpty ? 'Usuario SafeRisk' : displayName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  username.trim(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 13,
                  ),
                ),

                if (userType.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      userType.trim(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _resolveInitials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList(growable: false);

    if (parts.isEmpty) {
      return 'SR';
    }

    if (parts.length == 1) {
      final first = parts.first;

      if (first.length == 1) {
        return first.toUpperCase();
      }

      return first.substring(0, 2).toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

final class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4EAF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.surfaceHighlight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),

              const SizedBox(width: 10),

              Text(
                title,
                style: const TextStyle(
                  color: AppColors.secondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          ...children,
        ],
      ),
    );
  }
}

final class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cleanValue = value.trim().isEmpty ? 'No registrado' : value.trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.neutralDark.withValues(alpha: 0.68),
                fontSize: 13,
              ),
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              cleanValue,
              style: const TextStyle(
                color: AppColors.secondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final class _ConnectionCard extends StatelessWidget {
  const _ConnectionCard({required this.state});

  final AsyncValue<List<ConnectivityResult>> state;

  @override
  Widget build(BuildContext context) {
    return state.when(
      loading: () {
        return const _StatusCard(
          icon: Icons.wifi_find_rounded,
          title: 'Conexión',
          value: 'Comprobando...',
          color: AppColors.primary,
        );
      },
      error: (error, stackTrace) {
        return const _StatusCard(
          icon: Icons.wifi_off_rounded,
          title: 'Conexión',
          value: 'No disponible',
          color: Colors.orange,
        );
      },
      data: (results) {
        final connected =
            results.isNotEmpty && !results.contains(ConnectivityResult.none);

        final description = _connectionDescription(results);

        return _StatusCard(
          icon: connected ? Icons.wifi_rounded : Icons.wifi_off_rounded,
          title: 'Conexión',
          value: description,
          color: connected ? Colors.green : Colors.orange,
        );
      },
    );
  }

  static String _connectionDescription(List<ConnectivityResult> results) {
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      return 'Sin conexión';
    }

    if (results.contains(ConnectivityResult.wifi)) {
      return 'Wi-Fi';
    }

    if (results.contains(ConnectivityResult.mobile)) {
      return 'Datos móviles';
    }

    if (results.contains(ConnectivityResult.ethernet)) {
      return 'Ethernet';
    }

    if (results.contains(ConnectivityResult.vpn)) {
      return 'VPN';
    }

    return 'Conectado';
  }
}

final class _AppInfoCard extends StatelessWidget {
  const _AppInfoCard({required this.state});

  final AsyncValue<PackageInfo> state;

  @override
  Widget build(BuildContext context) {
    return _ProfileSection(
      title: 'Aplicación',
      icon: Icons.info_outline_rounded,
      children: [
        state.when(
          loading: () {
            return const _InfoRow(label: 'Versión', value: 'Cargando...');
          },
          error: (error, stackTrace) {
            return const _InfoRow(label: 'Versión', value: 'No disponible');
          },
          data: (package) {
            return Column(
              children: [
                _InfoRow(label: 'Aplicación', value: package.appName),
                _InfoRow(label: 'Versión', value: package.version),
              ],
            );
          },
        ),
      ],
    );
  }
}

final class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4EAF0)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final class _LegalOption extends StatelessWidget {
  const _LegalOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.surfaceHighlight,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.secondary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.neutralDark,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.neutralDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _LogoutCard extends StatelessWidget {
  const _LogoutCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.withValues(alpha: 0.14)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.logout_rounded, color: Colors.red),
              ),

              const SizedBox(width: 13),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cerrar sesión',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Salir de SafeRisk.',
                      style: TextStyle(
                        color: AppColors.neutralDark,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(Icons.chevron_right_rounded, color: Colors.red),
            ],
          ),
        ),
      ),
    );
  }
}

final class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

final class _SessionErrorView extends StatelessWidget {
  const _SessionErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 46,
              color: AppColors.neutralDark,
            ),

            const SizedBox(height: 16),

            const Text(
              'No pudimos cargar tu perfil',
              style: TextStyle(
                color: AppColors.secondary,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 18),

            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

final class _NoSessionView extends StatelessWidget {
  const _NoSessionView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(30),
        child: Text(
          'No existe una sesión activa.',
          style: TextStyle(color: AppColors.neutralDark),
        ),
      ),
    );
  }
}
