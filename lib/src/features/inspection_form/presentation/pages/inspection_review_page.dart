import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/network_error_message.dart';
import '../../../activity/presentation/controller/activity_controller.dart';
import '../../../activity/presentation/controller/recent_activity_controller.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../../inspections/domain/entities/inspection_case.dart';
import '../../../inspections/presentation/controllers/inspections_controller.dart';
import '../controller/inspection_form_controller.dart';

final class InspectionReviewPage extends ConsumerStatefulWidget {
  const InspectionReviewPage({
    required this.inspection,
    required this.insurerCode,
    super.key,
  });

  final InspectionCase inspection;
  final int insurerCode;

  @override
  ConsumerState<InspectionReviewPage> createState() =>
      _InspectionReviewPageState();
}

final class _InspectionReviewPageState
    extends ConsumerState<InspectionReviewPage> {
  bool _requesting = false;

  Future<void> _finalize() async {
    if (_requesting) return;
    setState(() => _requesting = true);
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Finalizar inspección'),
          content: Text(
            '¿Confirmas que finalizaste la inspección del caso '
            '#${widget.inspection.nroCaso}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Finalizar'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;

      final success = await ref
          .read(
            inspectionFormControllerProvider(
              widget.inspection.nroCaso,
            ).notifier,
          )
          .conclude(insurerCode: widget.insurerCode);
      if (!mounted) return;

      if (success) {
        ref.invalidate(inspectionsControllerProvider);
        ref.invalidate(dashboardControllerProvider);
        ref.invalidate(activityControllerProvider);
        ref.invalidate(recentActivityControllerProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inspección finalizada correctamente.')),
        );
      }
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inspection = widget.inspection;
    final state = ref.watch(
      inspectionFormControllerProvider(inspection.nroCaso),
    );
    final completed = state.asData?.value == true;
    final busy = _requesting || state.isLoading;
    final name = inspection.asegurado.trim().isNotEmpty
        ? inspection.asegurado.trim()
        : inspection.nombre.trim();
    final vehicle = [
      inspection.placa.trim().toUpperCase(),
      inspection.marca.trim(),
      inspection.modelo.trim(),
    ].where((value) => value.isNotEmpty).join(' · ');

    return PopScope(
      canPop: !busy,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text('Caso #${inspection.nroCaso}')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: Theme.of(context).textTheme.titleLarge),
                    if (vehicle.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(vehicle),
                    ],
                    const SizedBox(height: 20),
                    Text(
                      completed
                          ? 'Inspección finalizada'
                          : 'Llegada confirmada',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(networkErrorMessage(state.error!)),
              ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.all(20),
          child: FilledButton.icon(
            onPressed: busy || widget.insurerCode <= 0
                ? null
                : completed
                ? () => Navigator.of(context).popUntil((route) => route.isFirst)
                : _finalize,
            icon: busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(completed ? Icons.check : Icons.task_alt),
            label: Text(
              busy
                  ? 'Procesando...'
                  : completed
                  ? 'Volver a inspecciones'
                  : 'Finalizar inspección',
            ),
          ),
        ),
      ),
    );
  }
}
