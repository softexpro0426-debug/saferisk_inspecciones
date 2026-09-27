import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/activity_case.dart';
import '../../domain/entities/activity_summary.dart';
import '../../domain/entities/recent_activity.dart';
import '../../../../core/network/network_error_message.dart';
import '../controller/recent_activity_controller.dart';
import '../controller/activity_controller.dart';

final class ActivityPage extends ConsumerWidget {
  const ActivityPage({this.onOpenInspections, super.key});

  final VoidCallback? onOpenInspections;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(activityControllerProvider);
    final recentState = ref.watch(recentActivityControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              ref.read(activityControllerProvider.notifier).refresh(),
              ref.read(recentActivityControllerProvider.notifier).refresh(),
            ]);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
            children: [
              const _Header(),
              const SizedBox(height: 20),
              state.when(
                loading: () => const _LoadingView(),
                error: (error, _) => _ErrorView(
                  message: error is ActivityException
                      ? error.message
                      : 'No fue posible cargar el resumen.',
                  onRetry: () =>
                      ref.read(activityControllerProvider.notifier).refresh(),
                ),
                data: (summary) => _ActivityContent(
                  summary: summary,
                  onOpenInspections: onOpenInspections,
                ),
              ),
              const SizedBox(height: 18),
              const _SectionHeader(
                title: 'Actividad reciente',
                subtitle: 'Últimos movimientos',
              ),
              const SizedBox(height: 10),
              recentState.when(
                loading: () => const _LoadingView(),
                error: (error, _) => _ErrorView(
                  message: networkErrorMessage(error),
                  onRetry: () => ref
                      .read(recentActivityControllerProvider.notifier)
                      .refresh(),
                ),
                data: (items) => items.isEmpty
                    ? const _EmptyActivityCard()
                    : _RecentActivityCard(items: items),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _ActivityContent extends StatelessWidget {
  const _ActivityContent({
    required this.summary,
    required this.onOpenInspections,
  });

  final ActivitySummary summary;
  final VoidCallback? onOpenInspections;

  @override
  Widget build(BuildContext context) {
    final completedToday = summary.completedToday(DateTime.now());

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                value: '${summary.pendingCount}',
                label: 'Pendientes',
                icon: Icons.pending_actions_rounded,
                color: Colors.orange,
                onTap: onOpenInspections,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: _MetricCard(
                value: '$completedToday',
                label: 'Finalizadas hoy',
                icon: Icons.task_alt_rounded,
                color: Colors.green,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        _SectionHeader(
          title: 'Pendientes de atención',
          subtitle: summary.pendingCount == 1
              ? '1 inspección pendiente'
              : '${summary.pendingCount} inspecciones pendientes',
          actionLabel: 'Ver todas',
          onAction: onOpenInspections,
        ),

        const SizedBox(height: 10),

        if (summary.pending.isEmpty)
          const _EmptyPendingCard()
        else
          ...summary.pending
              .take(5)
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _PendingCaseCard(item: item, onTap: onOpenInspections),
                ),
              ),
      ],
    );
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
          'Actividad',
          style: TextStyle(
            color: AppColors.secondary,
            fontSize: 25,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 5),
        Text(
          'Resumen de tus inspecciones.',
          style: TextStyle(color: AppColors.neutralDark, fontSize: 13),
        ),
      ],
    );
  }
}

final class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

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
            border: Border.all(color: const Color(0xFFE4EAF0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),

              const SizedBox(height: 14),

              Text(
                value,
                style: const TextStyle(
                  color: AppColors.secondary,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                label,
                style: const TextStyle(
                  color: AppColors.neutralDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.secondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.neutralDark,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        if (actionLabel != null && onAction != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

final class _PendingCaseCard extends StatelessWidget {
  const _PendingCaseCard({required this.item, required this.onTap});

  final ActivityCase item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final status = item.estado.trim().isEmpty ? 'En curso' : item.estado.trim();

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFFE4EAF0)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.pending_actions_rounded,
                  color: Colors.orange,
                  size: 21,
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Caso #${item.nroCaso}',
                      style: const TextStyle(
                        color: AppColors.secondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      item.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.neutralDark,
                        fontSize: 12.5,
                      ),
                    ),

                    if (item.vehicle.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        item.vehicle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.neutralDark.withValues(alpha: 0.72),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    constraints: const BoxConstraints(maxWidth: 110),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.neutralDark,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard({required this.items});

  final List<RecentActivity> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4EAF0)),
      ),
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            _ActivityRow(item: items[index]),
            if (index != items.length - 1) const Divider(height: 22),
          ],
        ],
      ),
    );
  }
}

final class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.item});

  final RecentActivity item;

  @override
  Widget build(BuildContext context) {
    final completed = item.estado.trim().toUpperCase() == 'FINALIZADO';

    final color = completed ? Colors.green : AppColors.primary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            completed ? Icons.task_alt_rounded : Icons.history_rounded,
            color: color,
            size: 19,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.titulo,
                style: const TextStyle(
                  color: AppColors.secondary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                item.estado,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.neutralDark,
                  fontSize: 12,
                ),
              ),

              ...[
                const SizedBox(height: 4),
                Text(
                  _formatDate(item.fecha),
                  style: TextStyle(
                    color: AppColors.neutralDark.withValues(alpha: 0.65),
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  static String _formatDate(DateTime value) {
    final now = DateTime.now();

    final today =
        value.year == now.year &&
        value.month == now.month &&
        value.day == now.day;

    final hour = value.hour.toString().padLeft(2, '0');

    final minute = value.minute.toString().padLeft(2, '0');

    if (today) {
      return 'Hoy · $hour:$minute';
    }

    final day = value.day.toString().padLeft(2, '0');

    final month = value.month.toString().padLeft(2, '0');

    return '$day/$month/${value.year} · $hour:$minute';
  }
}

final class _EmptyPendingCard extends StatelessWidget {
  const _EmptyPendingCard();

  @override
  Widget build(BuildContext context) {
    return const _EmptyCard(
      icon: Icons.task_alt_rounded,
      title: 'Sin pendientes',
      message: 'No tienes inspecciones pendientes.',
    );
  }
}

final class _EmptyActivityCard extends StatelessWidget {
  const _EmptyActivityCard();

  @override
  Widget build(BuildContext context) {
    return const _EmptyCard(
      icon: Icons.history_rounded,
      title: 'Sin actividad reciente',
      message: 'No hay movimientos para mostrar.',
    );
  }
}

final class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4EAF0)),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 28),

          const SizedBox(height: 10),

          Text(
            title,
            style: const TextStyle(
              color: AppColors.secondary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.neutralDark,
              fontSize: 12.5,
            ),
          ),
        ],
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

final class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
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
              Icons.cloud_off_rounded,
              color: AppColors.neutralDark,
              size: 46,
            ),

            const SizedBox(height: 16),

            const Text(
              'No pudimos cargar la actividad',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.secondary,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 7),

            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.neutralDark,
                fontSize: 13,
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
