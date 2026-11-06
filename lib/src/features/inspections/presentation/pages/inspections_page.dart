import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/network_error_message.dart';
import '../../domain/entities/inspection_filter.dart';
import '../controllers/inspections_controller.dart';
import '../widgets/inspection_card.dart';
import '../widgets/inspection_filters_sheet.dart';
import 'operational_inspection_page.dart';

final class InspectionsPage extends ConsumerWidget {
  const InspectionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inspectionsState = ref.watch(inspectionsControllerProvider);

    final controller = ref.read(inspectionsControllerProvider.notifier);

    final filter = controller.filter;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _Header(
                    onFiltersPressed: () {
                      _openFilters(context: context, ref: ref);
                    },
                  ),
                ),
              ),

              if (_hasAdditionalFilters(filter))
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: _ActiveFilters(
                      filter: filter,
                      onClear: controller.clearFilters,
                    ),
                  ),
                ),

              inspectionsState.when(
                loading: () {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _LoadingState(),
                  );
                },

                error: (error, stackTrace) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: _ErrorState(
                      onRetry: controller.refresh,
                      message: networkErrorMessage(error),
                    ),
                  );
                },

                data: (inspections) {
                  if (inspections.isEmpty) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyState(),
                    );
                  }

                  return SliverMainAxisGroup(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                        sliver: SliverToBoxAdapter(
                          child: _ResultsHeader(count: inspections.length),
                        ),
                      ),

                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                        sliver: SliverList.separated(
                          itemCount: inspections.length,
                          separatorBuilder: (context, index) {
                            return const SizedBox(height: 12);
                          },
                          itemBuilder: (context, index) {
                            final inspection = inspections[index];

                            return InspectionCard(
                              inspection: inspection,
                              onTap: () {
                                final insurerCode =
                                    inspection.insurerCode ??
                                    ref
                                        .read(
                                          inspectionsControllerProvider
                                              .notifier,
                                        )
                                        .filter
                                        .aseguradora;

                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) {
                                      return OperationalInspectionPage(
                                        query: (
                                          caseNumber: inspection.nroCaso,
                                          insurerCode: insurerCode,
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openFilters({
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    final controller = ref.read(inspectionsControllerProvider.notifier);

    final currentFilter = controller.filter;

    final result = await showModalBottomSheet<InspectionFilter>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return InspectionFiltersSheet(
          initialFilter: currentFilter.copyWith(tipoConsulta: 'C'),
        );
      },
    );

    if (result == null) {
      return;
    }

    controller.applyFilter(result.copyWith(tipoConsulta: 'C'));
  }

  bool _hasAdditionalFilters(InspectionFilter filter) {
    return filter.aseguradora > 0 ||
        filter.cedula.trim().isNotEmpty ||
        filter.placa.trim().isNotEmpty ||
        filter.nombre.trim().isNotEmpty ||
        filter.nroCaso > 0;
  }
}

final class _Header extends StatelessWidget {
  const _Header({required this.onFiltersPressed});

  final VoidCallback onFiltersPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Inspecciones',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),

              SizedBox(height: 5),

              Text(
                'Consulta y gestiona tus inspecciones pendientes.',
                style: TextStyle(color: AppColors.neutralDark, fontSize: 13),
              ),
            ],
          ),
        ),

        IconButton.filledTonal(
          onPressed: onFiltersPressed,
          tooltip: 'Filtros',
          icon: const Icon(Icons.tune_rounded),
        ),
      ],
    );
  }
}

final class _ActiveFilters extends StatelessWidget {
  const _ActiveFilters({required this.filter, required this.onClear});

  final InspectionFilter filter;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final filters = <Widget>[];

    if (filter.aseguradora > 0) {
      filters.add(
        _FilterChip(
          label: filter.aseguradoraNombre.trim().isEmpty
              ? 'Aseguradora'
              : filter.aseguradoraNombre.trim(),
          icon: Icons.business_outlined,
        ),
      );
    }

    if (filter.nroCaso > 0) {
      filters.add(
        _FilterChip(
          label: 'Caso #${filter.nroCaso}',
          icon: Icons.assignment_outlined,
        ),
      );
    }

    if (filter.placa.trim().isNotEmpty) {
      filters.add(
        _FilterChip(
          label: 'Placa ${filter.placa.trim().toUpperCase()}',
          icon: Icons.directions_car_outlined,
        ),
      );
    }

    if (filter.cedula.trim().isNotEmpty) {
      filters.add(
        _FilterChip(
          label: 'Cédula ${filter.cedula.trim()}',
          icon: Icons.badge_outlined,
        ),
      );
    }

    if (filter.nombre.trim().isNotEmpty) {
      filters.add(
        _FilterChip(
          label: filter.nombre.trim(),
          icon: Icons.person_outline_rounded,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Filtros activos',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            TextButton(
              onPressed: onClear,
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              child: const Text('Limpiar'),
            ),
          ],
        ),

        const SizedBox(height: 7),

        Wrap(spacing: 7, runSpacing: 7, children: filters),
      ],
    );
  }
}

final class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceHighlight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),

          const SizedBox(width: 6),

          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final class _ResultsHeader extends StatelessWidget {
  const _ResultsHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.assignment_outlined,
          size: 18,
          color: AppColors.primary,
        ),

        const SizedBox(width: 7),

        Expanded(
          child: Text(
            '$count ${count == 1 ? 'inspección pendiente' : 'inspecciones pendientes'}',
            style: const TextStyle(
              color: AppColors.secondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        Text(
          'Desliza para actualizar',
          style: TextStyle(
            color: AppColors.neutralDark.withValues(alpha: 0.58),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

final class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),

          SizedBox(height: 16),

          Text(
            'Consultando inspecciones...',
            style: TextStyle(color: AppColors.neutralDark, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

final class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.surfaceHighlight,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.assignment_turned_in_outlined,
                color: AppColors.primary,
                size: 38,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'No hay inspecciones pendientes',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.secondary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 7),

            const Text(
              'No encontramos inspecciones activas con los filtros seleccionados.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.neutralDark, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

final class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry, required this.message});
  final String message;

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.surfaceHighlight,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 38,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'No pudimos consultar las inspecciones',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.secondary,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.neutralDark, fontSize: 13),
            ),

            const SizedBox(height: 20),

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
