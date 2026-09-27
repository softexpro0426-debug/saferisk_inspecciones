import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../arrival/presentation/pages/arrival_map_page.dart';
import '../../../inspection_form/presentation/pages/inspection_review_page.dart';
import '../../data/repositories/inspection_workflow_storage.dart';
import '../../data/repositories/en_route_repository_impl.dart';
import '../../domain/entities/inspection_case.dart';
import '../controllers/en_route_controller.dart';
import '../widgets/case_info_card.dart';
import '../widgets/case_quick_actions.dart';

final class InspectionDetailPage extends ConsumerStatefulWidget {
  const InspectionDetailPage({
    required this.inspection,
    required this.insurerCode,
    super.key,
  });

  final InspectionCase inspection;
  final int insurerCode;

  @override
  ConsumerState<InspectionDetailPage> createState() =>
      _InspectionDetailPageState();
}

final class _InspectionDetailPageState
    extends ConsumerState<InspectionDetailPage> {
  bool _navigating = false;
  InspectionCase get inspection => widget.inspection;
  int get insurerCode => widget.insurerCode;

  @override
  Widget build(BuildContext context) {
    final caseNumber = inspection.nroCaso;

    final displayName = inspection.asegurado.trim().isNotEmpty
        ? inspection.asegurado.trim()
        : inspection.nombre.trim();

    final enRouteState = ref.watch(enRouteControllerProvider(caseNumber));

    final registeringEnRoute = enRouteState.isLoading;

    final alreadyEnRoute = switch (enRouteState) {
      AsyncData(:final value) => value,
      _ => false,
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text('Caso #$caseNumber')),
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 130),
            sliver: SliverList(
              delegate: SliverChildListDelegate.fixed([
                _CaseHero(inspection: inspection, displayName: displayName),

                const SizedBox(height: 14),

                CaseQuickActions(
                  plate: inspection.placa,
                  phone: inspection.celularAsegurado,
                ),

                const SizedBox(height: 14),

                CaseInfoCard(
                  title: 'Asegurado',
                  icon: Icons.person_outline_rounded,
                  items: [
                    (label: 'Nombre', value: displayName),
                    (label: 'Identificación', value: inspection.identificacion),
                    (label: 'Celular', value: inspection.celularAsegurado),
                  ],
                ),

                const SizedBox(height: 14),

                CaseInfoCard(
                  title: 'Vehículo',
                  icon: Icons.directions_car_outlined,
                  items: [
                    (
                      label: 'Placa',
                      value: inspection.placa.trim().toUpperCase(),
                    ),
                    (label: 'Marca', value: inspection.marca),
                    (label: 'Modelo', value: inspection.modelo),
                  ],
                ),

                if (_hasContactInfo(inspection)) ...[
                  const SizedBox(height: 14),

                  CaseInfoCard(
                    title: 'Contacto',
                    icon: Icons.contact_phone_outlined,
                    items: [
                      (label: 'Persona', value: inspection.personaContacto),
                      (label: 'Teléfono', value: inspection.telefonoContacto),
                    ],
                  ),
                ],

                const SizedBox(height: 14),

                CaseInfoCard(
                  title: 'Inspección',
                  icon: Icons.assignment_outlined,
                  items: [
                    (label: 'Estado', value: _resolveStatus(inspection.estado)),
                    (
                      label: 'Inicio',
                      value: _formatDate(inspection.fechaInicio),
                    ),
                    if (inspection.fechaFin != null)
                      (
                        label: 'Finalización',
                        value: _formatDate(inspection.fechaFin),
                      ),
                  ],
                ),

                if (inspection.observaciones.trim().isNotEmpty) ...[
                  const SizedBox(height: 14),

                  _ObservationsCard(value: inspection.observaciones),
                ],

                if (enRouteState.hasError) ...[
                  const SizedBox(height: 14),

                  _EnRouteErrorCard(error: enRouteState.error!),
                ],
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 10, 20, 14),
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton.icon(
            onPressed: insurerCode <= 0 || registeringEnRoute || _navigating
                ? null
                : () {
                    _handlePrimaryAction(
                      context: context,
                      ref: ref,
                      alreadyEnRoute: alreadyEnRoute,
                    );
                  },
            icon: registeringEnRoute
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    alreadyEnRoute
                        ? Icons.arrow_forward_rounded
                        : Icons.directions_car_filled_rounded,
                  ),
            label: Text(
              registeringEnRoute
                  ? 'Registrando ubicación...'
                  : alreadyEnRoute
                  ? 'Continuar'
                  : 'En camino',
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handlePrimaryAction({
    required BuildContext context,
    required WidgetRef ref,
    required bool alreadyEnRoute,
  }) async {
    if (_navigating) return;
    setState(() => _navigating = true);
    try {
      if (alreadyEnRoute) {
        HapticFeedback.selectionClick();
        await _openArrivalPage(context, ref);
      } else {
        await _startEnRoute(context: context, ref: ref);
      }
    } finally {
      if (mounted) setState(() => _navigating = false);
    }
  }

  Future<void> _startEnRoute({
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    HapticFeedback.mediumImpact();

    final provider = enRouteControllerProvider(inspection.nroCaso);

    final success = await ref
        .read(provider.notifier)
        .markEnRoute(insurerCode: insurerCode);

    if (!context.mounted) {
      return;
    }

    if (!success) {
      final state = ref.read(provider);

      final message = state.hasError
          ? _resolveEnRouteError(state.error!)
          : 'No fue posible registrar la salida hacia el caso.';

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
        );

      return;
    }

    HapticFeedback.lightImpact();

    if (!context.mounted) {
      return;
    }

    await _openArrivalPage(context, ref);
  }

  Future<void> _openArrivalPage(BuildContext context, WidgetRef ref) async {
    final storage = ref.read(inspectionWorkflowStorageProvider);
    bool arrived;
    try {
      arrived =
          await storage.isArrivalConfirmed(inspection.nroCaso) ||
          await storage.isCompleted(inspection.nroCaso);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No fue posible recuperar el estado del caso.'),
        ),
      );
      return;
    }
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) {
          if (arrived) {
            return InspectionReviewPage(
              inspection: inspection,
              insurerCode: insurerCode,
            );
          }
          return ArrivalMapPage(
            inspection: inspection,
            insurerCode: insurerCode,
          );
        },
      ),
    );
  }

  static bool _hasContactInfo(InspectionCase inspection) {
    return inspection.personaContacto.trim().isNotEmpty ||
        inspection.telefonoContacto.trim().isNotEmpty;
  }

  static String _resolveStatus(String value) {
    final status = value.trim();

    if (status.isEmpty) {
      return 'En proceso';
    }

    return status;
  }

  static String _resolveEnRouteError(Object error) {
    if (error is EnRouteException) {
      return error.message;
    }

    final text = error.toString().toLowerCase();

    if (text.contains('sesión') || text.contains('session')) {
      return 'Tu sesión no está disponible. Inicia sesión nuevamente.';
    }

    if (text.contains('permanentemente') || text.contains('deniedforever')) {
      return 'El permiso de ubicación está bloqueado. '
          'Habilítalo desde la configuración del dispositivo.';
    }

    if (text.contains('permiso') || text.contains('denied')) {
      return 'Permite el acceso a tu ubicación para continuar.';
    }

    if (text.contains('gps') || text.contains('service')) {
      return 'Activa la ubicación de tu dispositivo para continuar.';
    }

    if (text.contains('timeout') || text.contains('timed out')) {
      return 'La conexión está tardando demasiado. Inténtalo nuevamente.';
    }

    if (text.contains('connection') || text.contains('socket')) {
      return 'No fue posible conectar con SafeRisk.';
    }

    return 'No fue posible registrar la salida hacia el caso.';
  }

  static String _formatDate(DateTime? date) {
    if (date == null) {
      return 'No registrada';
    }

    return DateFormat('dd/MM/yyyy · HH:mm').format(date.toLocal());
  }
}

final class _CaseHero extends StatelessWidget {
  const _CaseHero({required this.inspection, required this.displayName});

  final InspectionCase inspection;
  final String displayName;

  @override
  Widget build(BuildContext context) {
    final vehicle = [
      inspection.marca.trim(),
      inspection.modelo.trim(),
    ].where((value) => value.isNotEmpty).join(' ');

    final status = _resolveHeroStatus(inspection.estado);

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
            color: AppColors.secondary.withValues(alpha: 0.14),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Caso #${inspection.nroCaso}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              Container(
                constraints: const BoxConstraints(maxWidth: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          if (inspection.placa.trim().isNotEmpty) ...[
            const SizedBox(height: 18),

            Text(
              inspection.placa.trim().toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],

          if (vehicle.isNotEmpty) ...[
            const SizedBox(height: 4),

            Text(
              vehicle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.84),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],

          const SizedBox(height: 16),

          Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                size: 17,
                color: Colors.white.withValues(alpha: 0.8),
              ),

              const SizedBox(width: 7),

              Expanded(
                child: Text(
                  displayName.isEmpty
                      ? 'Sin asegurado registrado'
                      : displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _resolveHeroStatus(String value) {
    final status = value.trim();

    if (status.isEmpty) {
      return 'En proceso';
    }

    return status;
  }
}

final class _ObservationsCard extends StatefulWidget {
  const _ObservationsCard({required this.value});

  final String value;

  @override
  State<_ObservationsCard> createState() {
    return _ObservationsCardState();
  }
}

final class _ObservationsCardState extends State<_ObservationsCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final value = widget.value.trim();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4EAF0)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            setState(() {
              _expanded = !_expanded;
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.notes_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),

                    const SizedBox(width: 9),

                    const Expanded(
                      child: Text(
                        'Observaciones',
                        style: TextStyle(
                          color: AppColors.secondary,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),

                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 160),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),

                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 180),
                  crossFadeState: _expanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  firstChild: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.neutralDark,
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Text(
                      value,
                      style: const TextStyle(
                        color: AppColors.neutralDark,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _EnRouteErrorCard extends StatelessWidget {
  const _EnRouteErrorCard({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final message = error is EnRouteException
        ? (error as EnRouteException).message
        : 'No fue posible continuar con el caso.';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange,
            size: 21,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.neutralDark,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
