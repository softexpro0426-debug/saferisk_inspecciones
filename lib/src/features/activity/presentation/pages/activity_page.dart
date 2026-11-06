import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/network_error_message.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../inspections/domain/entities/activity_workflow_resolver.dart';
import '../../../inspections/domain/entities/operational_inspection.dart';
import '../../../inspections/presentation/pages/operational_inspection_page.dart';
import '../../domain/entities/activity_overview.dart';
import '../../domain/entities/recent_activity.dart';
import '../controller/recent_activity_controller.dart';

final class ActivityPage extends ConsumerWidget {
  const ActivityPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recentActivityControllerProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () =>
              ref.read(recentActivityControllerProvider.notifier).refresh(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(20, 18, 20, 24),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Actividad',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                          color: AppColors.secondary,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Continúa tus inspecciones y revisa tus movimientos.',
                        style: TextStyle(color: AppColors.neutralDark),
                      ),
                    ],
                  ),
                ),
              ),
              ...state.when(
                loading: () => const <Widget>[
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
                error: (error, _) => <Widget>[
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.cloud_off_rounded,
                            size: 44,
                            color: AppColors.neutralDark,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            networkErrorMessage(error),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: () => ref
                                .read(recentActivityControllerProvider.notifier)
                                .refresh(),
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                data: (events) {
                  final overview = ActivityOverview(events);
                  return <Widget>[
                    const SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverToBoxAdapter(
                        child: _SectionTitle('En curso'),
                      ),
                    ),
                    if (overview.inProgress.isEmpty)
                      const SliverPadding(
                        padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
                        sliver: SliverToBoxAdapter(
                          child: _EmptyCard(
                            'No tienes inspecciones en curso.',
                            Icons.task_alt_outlined,
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        sliver: SliverList.separated(
                          itemCount: overview.inProgress.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, index) =>
                              _InProgressCard(overview.inProgress[index]),
                        ),
                      ),
                    const SliverPadding(
                      padding: EdgeInsets.fromLTRB(20, 28, 20, 12),
                      sliver: SliverToBoxAdapter(
                        child: _SectionTitle('Últimos movimientos'),
                      ),
                    ),
                    if (overview.history.isEmpty)
                      const SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverToBoxAdapter(
                          child: _EmptyCard(
                            'Todavía no hay movimientos para mostrar.',
                            Icons.history_rounded,
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList.separated(
                          itemCount: overview.history.length,
                          separatorBuilder: (_, _) => const Divider(height: 28),
                          itemBuilder: (_, index) =>
                              _HistoryRow(overview.history[index]),
                        ),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 32)),
                  ];
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _InProgressCard extends StatelessWidget {
  const _InProgressCard(this.item);
  final RecentActivity item;

  @override
  Widget build(BuildContext context) {
    final status = ActivityWorkflowResolver.knownStatus(item.estadoActual)!;
    final (color, icon) = _appearance(status);
    final label = switch (status) {
      OperationalStatus.enRoute => 'En camino',
      OperationalStatus.arrived => 'En el lugar',
      _ => 'Inspección en curso',
    };
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: OperationalCaseLink(
          query: (caseNumber: item.caseNumber, insurerCode: item.insurerCode),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.titulo,
                style: const TextStyle(
                  color: AppColors.secondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Continuar · ${status.nextAction!}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _HistoryRow extends StatelessWidget {
  const _HistoryRow(this.item);
  final RecentActivity item;

  @override
  Widget build(BuildContext context) {
    final status = ActivityWorkflowResolver.knownStatus(item.estadoSeguimiento);
    final (color, icon) = _appearance(status);
    final text = switch (status) {
      OperationalStatus.assigned => 'Inspección asignada',
      OperationalStatus.enRoute => 'Salida registrada',
      OperationalStatus.arrived => 'Llegada confirmada',
      OperationalStatus.started => 'Inspección iniciada',
      OperationalStatus.completed => 'Inspección finalizada',
      _ => switch (item.estadoSeguimiento.trim().toUpperCase()) {
        'ASEGURABLE' => 'Asegurable',
        'COORDINADO' => 'Coordinado',
        'FALLIDO' => 'Fallido',
        _ =>
          item.estadoSeguimiento.trim().isEmpty
              ? 'Movimiento registrado'
              : item.estadoSeguimiento.trim(),
      },
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
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
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(text, style: TextStyle(color: color)),
              const SizedBox(height: 4),
              Text(
                _formatDate(item.fecha),
                style: const TextStyle(
                  color: AppColors.neutralDark,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

final class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: AppColors.secondary,
      fontSize: 18,
      fontWeight: FontWeight.w800,
    ),
  );
}

final class _EmptyCard extends StatelessWidget {
  const _EmptyCard(this.text, this.icon);
  final String text;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Icon(icon, color: AppColors.neutralDark),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AppColors.neutralDark),
          ),
        ),
      ],
    ),
  );
}

(Color, IconData) _appearance(OperationalStatus? status) => switch (status) {
  OperationalStatus.enRoute => (
    AppColors.primary,
    Icons.directions_car_rounded,
  ),
  OperationalStatus.arrived => (
    const Color(0xFF946200),
    Icons.location_on_rounded,
  ),
  OperationalStatus.started => (
    const Color(0xFF7541A6),
    Icons.assignment_rounded,
  ),
  OperationalStatus.completed => (AppColors.success, Icons.task_alt_rounded),
  _ => (AppColors.neutralDark, Icons.history_rounded),
};

String _formatDate(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  String pad(int value) => value.toString().padLeft(2, '0');
  final time = '${pad(date.hour)}:${pad(date.minute)}';
  final prefix = day == today
      ? 'Hoy'
      : day == DateTime(now.year, now.month, now.day - 1)
      ? 'Ayer'
      : '${pad(date.day)}/${pad(date.month)}/${date.year}';
  return '$prefix · $time';
}
