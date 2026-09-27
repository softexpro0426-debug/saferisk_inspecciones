import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../inspections/presentation/controllers/inspections_controller.dart';
import '../../domain/entities/dashboard_action.dart';
import '../controllers/dashboard_controller.dart';

final class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key, this.onOpenInspections});

  final VoidCallback? onOpenInspections;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () {
            return ref.read(dashboardControllerProvider.notifier).refresh();
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(20, 18, 20, 0),
                sliver: SliverToBoxAdapter(child: _DashboardHeader()),
              ),
              dashboardState.when(
                loading: () {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _DashboardLoading(),
                  );
                },
                error: (error, stackTrace) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: _DashboardError(
                      onRetry: () {
                        ref
                            .read(dashboardControllerProvider.notifier)
                            .refresh();
                      },
                    ),
                  );
                },
                data: (dashboard) {
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate.fixed([
                        _PrimaryMetricCard(
                          title: 'Pendientes',
                          value: dashboard.pendientes,
                          subtitle: 'Inspecciones que requieren atención.',
                          icon: Icons.assignment_late_outlined,
                          onTap: () {
                            _openAction(
                              context: context,
                              ref: ref,
                              action: DashboardAction.pending,
                            );
                          },
                        ),

                        const SizedBox(height: 14),

                        Row(
                          children: [
                            Expanded(
                              child: _MetricCard(
                                title: 'Para hoy',
                                value: dashboard.pendientesHoy,
                                icon: Icons.today_outlined,
                                onTap: () {
                                  _openAction(
                                    context: context,
                                    ref: ref,
                                    action: DashboardAction.pendingToday,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MetricCard(
                                title: 'Finalizadas',
                                value: dashboard.finalizadas,
                                icon: Icons.task_alt_rounded,
                                onTap: () {
                                  _openAction(
                                    context: context,
                                    ref: ref,
                                    action: DashboardAction.completed,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: _MetricCard(
                                title: 'Esta semana',
                                value: dashboard.finalizadasSemana,
                                icon: Icons.date_range_outlined,
                                onTap: () {
                                  _openAction(
                                    context: context,
                                    ref: ref,
                                    action: DashboardAction.completedWeek,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MetricCard(
                                title: 'Asignadas',
                                value: dashboard.asignadas,
                                icon: Icons.assignment_ind_outlined,
                                onTap: () {
                                  _openAction(
                                    context: context,
                                    ref: ref,
                                    action: DashboardAction.assigned,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        _OperationalSummaryCard(
                          pending: dashboard.pendientes,
                          pendingToday: dashboard.pendientesHoy,
                          completed: dashboard.finalizadas,
                        ),
                      ]),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openAction({
    required BuildContext context,
    required WidgetRef ref,
    required DashboardAction action,
  }) {
    final controller = ref.read(inspectionsControllerProvider.notifier);

    final currentFilter = controller.filter;

    final nextFilter = switch (action) {
      DashboardAction.pending => currentFilter.copyWith(tipoConsulta: 'C'),

      DashboardAction.pendingToday => currentFilter.copyWith(tipoConsulta: 'C'),

      DashboardAction.completed => currentFilter.copyWith(tipoConsulta: 'P'),

      DashboardAction.completedWeek => currentFilter.copyWith(
        tipoConsulta: 'P',
      ),

      DashboardAction.assigned => currentFilter.copyWith(tipoConsulta: 'C'),
    };

    controller.applyFilter(nextFilter);

    onOpenInspections?.call();
  }
}

final class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Inicio',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Resumen operativo de tus inspecciones.',
                style: TextStyle(color: AppColors.neutralDark, fontSize: 13),
              ),
            ],
          ),
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.surfaceHighlight,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.shield_outlined, color: AppColors.primary),
        ),
      ],
    );
  }
}

final class _PrimaryMetricCard extends StatelessWidget {
  const _PrimaryMetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final int value;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
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
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$value',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final int value;
  final IconData icon;
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
            border: Border.all(color: const Color(0xFFE4EAF0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.surfaceHighlight,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(height: 16),
              Text(
                '$value',
                style: const TextStyle(
                  color: AppColors.secondary,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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

final class _OperationalSummaryCard extends StatelessWidget {
  const _OperationalSummaryCard({
    required this.pending,
    required this.pendingToday,
    required this.completed,
  });

  final int pending;
  final int pendingToday;
  final int completed;

  @override
  Widget build(BuildContext context) {
    final message = switch ((pending, pendingToday)) {
      (0, _) => 'No tienes inspecciones pendientes.',
      (_, > 0) => 'Tienes $pendingToday inspecciones pendientes para hoy.',
      _ => 'Tienes $pending inspecciones pendientes.',
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4EAF0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.surfaceHighlight,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.insights_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Resumen',
                  style: TextStyle(
                    color: AppColors.secondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.neutralDark,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$completed inspecciones finalizadas.',
                  style: TextStyle(
                    color: AppColors.neutralDark.withValues(alpha: 0.68),
                    fontSize: 11.5,
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

final class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

final class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.onRetry});

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
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'No pudimos cargar el resumen',
              style: TextStyle(
                color: AppColors.secondary,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Comprueba tu conexión e inténtalo nuevamente.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.neutralDark, fontSize: 13),
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
