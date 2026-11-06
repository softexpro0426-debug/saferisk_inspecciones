import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/network_error_message.dart';
import '../../../../core/location/current_location_card.dart';
import '../../../../core/security/session_lock_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/operational_inspection.dart';
import '../controllers/operational_workflow_controller.dart';
import '../widgets/case_info_card.dart';
import '../widgets/inspection_progress_bar.dart';
import '../widgets/case_quick_actions.dart';

/// Entry point shared by activity and inspection lists after contract activation.
final class OperationalInspectionPage extends ConsumerStatefulWidget {
  const OperationalInspectionPage({required this.query, super.key});
  final WorkflowQuery query;

  @override
  ConsumerState<OperationalInspectionPage> createState() =>
      _OperationalInspectionPageState();
}

final class _OperationalInspectionPageState
    extends ConsumerState<OperationalInspectionPage> {
  bool _confirming = false;
  bool _pendingCompletion = false;
  bool _leaving = false;

  Future<void> _advance(OperationalStatus expected) async {
    if (_confirming) return;
    setState(() => _confirming = true);
    OperationalStatus? result;
    try {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(expected.nextAction!),
          content: Text(switch (expected) {
            OperationalStatus.assigned =>
              '¿Ya estás en camino hacia la inspección?',
            OperationalStatus.enRoute => '¿Llegaste al lugar de la inspección?',
            OperationalStatus.arrived => '¿Vas a comenzar la inspección?',
            _ =>
              '¿Terminaste la inspección? Al finalizar ya no podrás continuarla.',
          }),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(expected.nextAction!),
            ),
          ],
        ),
      );
      if (accepted != true || !mounted) return;
      result = await ref
          .read(operationalWorkflowProvider(widget.query).notifier)
          .advance(expected);
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
    if (!mounted || result != OperationalStatus.completed) return;
    _pendingCompletion = true;
    await _leaveCompletedInspection();
  }

  Future<void> _leaveCompletedInspection() async {
    if (!mounted ||
        !_pendingCompletion ||
        _leaving ||
        !ref.read(sessionLockProvider).isUnlocked) {
      return;
    }
    _leaving = true;
    // Let PopScope rebuild after the request lock has been released.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    if (!ref.read(sessionLockProvider).isUnlocked) {
      _leaving = false;
      return;
    }
    if (ModalRoute.of(context)?.isCurrent != true) {
      _leaving = false;
      return;
    }
    _pendingCompletion = false;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Inspección finalizada.')));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(sessionLockProvider, (_, access) {
      if (access.isUnlocked && _pendingCompletion) {
        unawaited(_leaveCompletedInspection());
      }
    });
    final state = ref.watch(operationalWorkflowProvider(widget.query));
    final controller = ref.read(
      operationalWorkflowProvider(widget.query).notifier,
    );
    final busy = _confirming || (state.asData?.value.busy ?? false);
    return PopScope(
      canPop: !busy && ref.watch(sessionLockProvider).isUnlocked,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('Inspección #${widget.query.caseNumber}'),
          actions: [
            IconButton(
              tooltip: 'Actualizar',
              onPressed: busy || state.isLoading ? null : controller.refresh,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        bottomNavigationBar: state.asData == null
            ? null
            : SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                      ),
                      onPressed: busy
                          ? null
                          : state.asData!.value.needsRefresh
                          ? controller.refresh
                          : state.asData!.value.item.status.nextAction == null
                          ? () => Navigator.pop(context)
                          : () => _advance(state.asData!.value.item.status),
                      child: busy
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              state.asData!.value.needsRefresh
                                  ? 'Reintentar conexión'
                                  : state
                                            .asData!
                                            .value
                                            .item
                                            .status
                                            .nextAction ??
                                        'Volver',
                            ),
                    ),
                  ),
                ),
              ),
        body: state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_off_rounded,
                    size: 44,
                    color: AppColors.neutralDark,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    error is WorkflowException
                        ? error.message
                        : networkErrorMessage(error),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: controller.refresh,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          ),
          data: (view) {
            final item = view.item;
            final inspection = item.inspection;
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: item.status == OperationalStatus.completed
                        ? AppColors.success.withValues(alpha: 0.08)
                        : AppColors.surfaceHighlight,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.status.label,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(switch (item.status) {
                        OperationalStatus.assigned =>
                          'Revisa los datos antes de salir.',
                        OperationalStatus.enRoute =>
                          'Confirma tu llegada cuando estés en el lugar.',
                        OperationalStatus.arrived =>
                          'Todo listo para iniciar la inspección.',
                        OperationalStatus.started =>
                          'Cuando termines, marca la inspección como finalizada.',
                        OperationalStatus.completed => 'Inspección completada.',
                      }, style: const TextStyle(color: AppColors.neutralDark)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                InspectionProgressBar(currentStep: item.status),
                if (item.status != OperationalStatus.completed) ...[
                  const SizedBox(height: 16),
                  CurrentLocationCard(busy: busy),
                ],
                const SizedBox(height: 16),
                CaseInfoCard(
                  title: 'Datos de la inspección',
                  icon: Icons.assignment_outlined,
                  items: [
                    (label: 'Asegurado', value: inspection.asegurado),
                    (label: 'Placa', value: inspection.placa),
                    (label: 'Marca', value: inspection.marca),
                    (label: 'Modelo', value: inspection.modelo),
                  ],
                ),
                const SizedBox(height: 16),
                CaseInfoCard(
                  title: 'Contacto',
                  icon: Icons.person_outline_rounded,
                  items: [
                    (label: 'Nombre', value: inspection.personaContacto),
                    (
                      label: 'Teléfono',
                      value: inspection.telefonoContacto.isNotEmpty
                          ? inspection.telefonoContacto
                          : inspection.celularAsegurado,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                CaseQuickActions(
                  plate: inspection.placa,
                  phone: inspection.telefonoContacto.isNotEmpty
                      ? inspection.telefonoContacto
                      : inspection.celularAsegurado,
                ),
                if (inspection.observaciones.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: CaseInfoCard(
                      title: 'Observaciones',
                      icon: Icons.notes_rounded,
                      items: [
                        (label: 'Detalle', value: inspection.observaciones),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                if (!view.busy && view.message != null)
                  Text(
                    view.message!,
                    style: const TextStyle(color: AppColors.neutralDark),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

final class OperationalCaseLink extends StatefulWidget {
  const OperationalCaseLink({
    required this.query,
    required this.child,
    super.key,
  });
  final WorkflowQuery query;
  final Widget child;

  @override
  State<OperationalCaseLink> createState() => _OperationalCaseLinkState();
}

final class _OperationalCaseLinkState extends State<OperationalCaseLink> {
  bool _opening = false;

  Future<void> _open() async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => OperationalInspectionPage(query: widget.query),
        ),
      );
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Abrir caso #${widget.query.caseNumber}',
    child: InkWell(
      onTap: _opening ? null : _open,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(child: widget.child),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    ),
  );
}
