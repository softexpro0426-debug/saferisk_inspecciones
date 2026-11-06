import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/operational_inspection.dart';

final class InspectionProgressBar extends StatelessWidget {
  const InspectionProgressBar({required this.currentStep, super.key});

  final OperationalStatus currentStep;

  @override
  Widget build(BuildContext context) {
    final steps = <({OperationalStatus step, String label, IconData icon})>[
      (
        step: OperationalStatus.assigned,
        label: 'Asignada',
        icon: Icons.description_outlined,
      ),
      (
        step: OperationalStatus.enRoute,
        label: 'En camino',
        icon: Icons.location_on_outlined,
      ),
      (
        step: OperationalStatus.arrived,
        label: 'Llegada',
        icon: Icons.fact_check_outlined,
      ),
      (
        step: OperationalStatus.started,
        label: 'Iniciada',
        icon: Icons.assignment_outlined,
      ),
      (
        step: OperationalStatus.completed,
        label: 'Finalizada',
        icon: Icons.task_alt_outlined,
      ),
    ];
    final currentIndex = steps.indexWhere((item) => item.step == currentStep);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4EAF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Progreso de inspección',
            style: TextStyle(
              color: AppColors.secondary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(steps.length, (index) {
              final data = steps[index];
              final completed = index < currentIndex;
              final active = index == currentIndex;

              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _ProgressStep(
                        icon: data.icon,
                        label: data.label,
                        completed: completed,
                        active: active,
                      ),
                    ),
                    if (index != steps.length - 1)
                      SizedBox(
                        width: 8,
                        child: Container(
                          height: 2,
                          color: index < currentIndex
                              ? AppColors.primary
                              : const Color(0xFFDCE4EC),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

final class _ProgressStep extends StatelessWidget {
  const _ProgressStep({
    required this.icon,
    required this.label,
    required this.completed,
    required this.active,
  });

  final IconData icon;
  final String label;
  final bool completed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final foreground = completed || active
        ? AppColors.primary
        : AppColors.neutralDark;

    final background = completed || active
        ? AppColors.surfaceHighlight
        : const Color(0xFFF0F3F6);

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: background,
            shape: BoxShape.circle,
            border: Border.all(
              color: completed || active
                  ? AppColors.primary.withValues(alpha: 0.22)
                  : const Color(0xFFE2E7EC),
            ),
          ),
          child: Icon(
            completed ? Icons.check_rounded : icon,
            size: 19,
            color: foreground,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          label,
          maxLines: 2,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: foreground,
            fontSize: 11,
            fontWeight: active ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
