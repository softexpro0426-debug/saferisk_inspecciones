import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

import '../../../../core/location/location_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../inspection_form/presentation/pages/inspection_review_page.dart';
import '../../../inspections/domain/entities/inspection_case.dart';
import '../../../inspections/presentation/widgets/inspection_progress_bar.dart';
import '../controllers/confirm_arrival_controller.dart';

final class ArrivalMapPage extends ConsumerStatefulWidget {
  const ArrivalMapPage({
    required this.inspection,
    required this.insurerCode,
    super.key,
  });

  final InspectionCase inspection;
  final int insurerCode;

  @override
  ConsumerState<ArrivalMapPage> createState() => _ArrivalMapPageState();
}

final class _ArrivalMapPageState extends ConsumerState<ArrivalMapPage> {
  GoogleMapController? _mapController;

  Position? _position;

  bool _openingFinalization = false;
  bool _loadingLocation = true;
  bool _refreshingLocation = false;

  String? _locationError;
  DateTime? _lastLocationUpdate;

  @override
  void initState() {
    super.initState();

    Future.microtask(_loadInitialLocation);
  }

  @override
  void dispose() {
    _mapController?.dispose();

    super.dispose();
  }

  Future<void> _loadInitialLocation() async {
    await _loadLocation(moveCamera: false);
  }

  Future<void> _refreshLocation() async {
    if (_refreshingLocation) {
      return;
    }

    HapticFeedback.selectionClick();

    setState(() {
      _refreshingLocation = true;
    });

    await _loadLocation(moveCamera: true);

    if (!mounted) {
      return;
    }

    setState(() {
      _refreshingLocation = false;
    });
  }

  Future<void> _loadLocation({required bool moveCamera}) async {
    try {
      final locationService = ref.read(locationServiceProvider);

      final position = await locationService.getCurrentPosition();

      if (!mounted) {
        return;
      }

      setState(() {
        _position = position;
        _locationError = null;
        _loadingLocation = false;
        _lastLocationUpdate = DateTime.now();
      });

      if (moveCamera) {
        await _moveCameraToCurrentLocation(position);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadingLocation = false;
        _locationError = _resolveLocationError(error);
      });
    }
  }

  Future<void> _moveCameraToCurrentLocation(Position position) async {
    final controller = _mapController;

    if (controller == null) {
      return;
    }

    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 17.5,
        ),
      ),
    );
  }

  Future<void> _recenter() async {
    final position = _position;

    if (position == null) {
      await _refreshLocation();
      return;
    }

    HapticFeedback.selectionClick();

    await _moveCameraToCurrentLocation(position);
  }

  Future<void> _confirmArrival() async {
    HapticFeedback.mediumImpact();

    final success = await ref
        .read(
          confirmArrivalControllerProvider(widget.inspection.nroCaso).notifier,
        )
        .confirm(insurerCode: widget.insurerCode);

    if (!mounted) {
      return;
    }

    if (!success) {
      final state = ref.read(
        confirmArrivalControllerProvider(widget.inspection.nroCaso),
      );

      final message = state.hasError
          ? _resolveArrivalError(state.error!)
          : 'No fue posible confirmar la llegada.';

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
        );

      return;
    }

    // La API ya obtuvo una posición fresca dentro
    // de ConfirmArrivalController.
    //
    // Refrescamos también la ubicación visual del mapa
    // para que la UI represente una posición reciente.
    await _loadLocation(moveCamera: true);

    if (!mounted) {
      return;
    }

    HapticFeedback.lightImpact();

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Llegada confirmada correctamente.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _continueInspection() async {
    if (_openingFinalization) return;
    setState(() => _openingFinalization = true);
    try {
      HapticFeedback.lightImpact();

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) {
            return InspectionReviewPage(
              inspection: widget.inspection,
              insurerCode: widget.insurerCode,
            );
          },
        ),
      );
    } finally {
      if (mounted) setState(() => _openingFinalization = false);
    }
  }

  String _resolveLocationError(Object error) {
    final text = error.toString().toLowerCase();

    if (text.contains('permanentemente') || text.contains('deniedforever')) {
      return 'El permiso de ubicación está bloqueado. '
          'Debes habilitarlo desde la configuración del dispositivo.';
    }

    if (text.contains('permiso') || text.contains('denied')) {
      return 'SafeRisk necesita permiso de ubicación '
          'para registrar la posición del inspector.';
    }

    if (text.contains('service') || text.contains('gps')) {
      return 'El GPS del dispositivo está desactivado.';
    }

    return 'No fue posible obtener la ubicación actual.';
  }

  String _resolveArrivalError(Object error) {
    final text = error.toString().toLowerCase();

    if (text.contains('sesión') || text.contains('session')) {
      return 'No existe una sesión activa.';
    }

    if (text.contains('permiso') || text.contains('denied')) {
      return 'SafeRisk necesita permiso de ubicación para confirmar la llegada.';
    }

    if (text.contains('gps') || text.contains('service')) {
      return 'Activa el GPS para confirmar la llegada.';
    }

    if (text.contains('timeout') || text.contains('timed out')) {
      return 'El servidor está tardando demasiado en responder.';
    }

    if (text.contains('connection') || text.contains('socket')) {
      return 'No fue posible conectar con SafeRisk.';
    }

    return 'No fue posible confirmar la llegada.';
  }

  @override
  Widget build(BuildContext context) {
    final confirmArrivalState = ref.watch(
      confirmArrivalControllerProvider(widget.inspection.nroCaso),
    );
    final confirmingArrival = confirmArrivalState.isLoading;

    final arrivalConfirmed = switch (confirmArrivalState) {
      AsyncData(:final value) => value == true,
      _ => false,
    };
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Ubicación · Caso #${widget.inspection.nroCaso}'),
      ),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 130),
              sliver: SliverList(
                delegate: SliverChildListDelegate.fixed([
                  InspectionProgressBar(
                    currentStep: arrivalConfirmed
                        ? InspectionWorkflowStep.arrived
                        : InspectionWorkflowStep.enRoute,
                  ),

                  const SizedBox(height: 14),

                  _CaseLocationHeader(inspection: widget.inspection),

                  const SizedBox(height: 14),

                  _LocationStatusCard(
                    loading: _loadingLocation,
                    refreshing: _refreshingLocation,
                    position: _position,
                    lastUpdate: _lastLocationUpdate,
                    error: _locationError,
                    onRefresh: _refreshLocation,
                  ),

                  const SizedBox(height: 14),

                  _MapCard(
                    position: _position,
                    loading: _loadingLocation,
                    error: _locationError,
                    onMapCreated: (controller) {
                      _mapController = controller;
                    },
                    onRetry: _refreshLocation,
                    onRecenter: _recenter,
                  ),

                  if (arrivalConfirmed) ...[
                    const SizedBox(height: 14),
                    const _ArrivalConfirmedCard(),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 10, 20, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed:
                    confirmingArrival ||
                        arrivalConfirmed ||
                        widget.insurerCode <= 0
                    ? null
                    : _confirmArrival,
                icon: confirmingArrival
                    ? const SizedBox(
                        width: 19,
                        height: 19,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        arrivalConfirmed
                            ? Icons.check_circle_rounded
                            : Icons.location_on_rounded,
                      ),
                label: Text(
                  confirmingArrival
                      ? 'Confirmando llegada...'
                      : arrivalConfirmed
                      ? 'Llegada confirmada'
                      : 'Confirmar llegada',
                ),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: arrivalConfirmed && !_openingFinalization
                    ? _continueInspection
                    : null,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Ir a finalizar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _CaseLocationHeader extends StatelessWidget {
  const _CaseLocationHeader({required this.inspection});

  final InspectionCase inspection;

  @override
  Widget build(BuildContext context) {
    final name = inspection.asegurado.trim().isNotEmpty
        ? inspection.asegurado.trim()
        : inspection.nombre.trim();

    final vehicle = [
      inspection.placa.trim().toUpperCase(),
      inspection.marca.trim(),
      inspection.modelo.trim(),
    ].where((value) => value.isNotEmpty).join(' · ');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4EAF0)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.surfaceHighlight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.directions_car_outlined,
              color: AppColors.primary,
              size: 23,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'Caso #${inspection.nroCaso}' : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                if (vehicle.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    vehicle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.neutralDark,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
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
}

final class _LocationStatusCard extends StatelessWidget {
  const _LocationStatusCard({
    required this.loading,
    required this.refreshing,
    required this.position,
    required this.lastUpdate,
    required this.error,
    required this.onRefresh,
  });

  final bool loading;
  final bool refreshing;
  final Position? position;
  final DateTime? lastUpdate;
  final String? error;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final position = this.position;

    if (loading && position == null) {
      return const _LoadingLocationCard();
    }

    if (error != null && position == null) {
      return _LocationErrorCard(message: error!, onRetry: onRefresh);
    }

    if (position == null) {
      return _LocationErrorCard(
        message: 'No existe una ubicación disponible.',
        onRetry: onRefresh,
      );
    }

    final accuracy = position.accuracy;

    final quality = _resolveAccuracyQuality(accuracy);

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
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.surfaceHighlight,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.gps_fixed_rounded,
                  color: AppColors.primary,
                  size: 21,
                ),
              ),

              const SizedBox(width: 12),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ubicación actual',
                      style: TextStyle(
                        color: AppColors.secondary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'GPS activo',
                      style: TextStyle(
                        color: AppColors.neutralDark,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              IconButton(
                onPressed: refreshing ? null : onRefresh,
                tooltip: 'Actualizar ubicación',
                icon: refreshing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
              ),
            ],
          ),

          const SizedBox(height: 18),

          _LocationMetric(
            label: 'Precisión',
            value: '± ${accuracy.toStringAsFixed(0)} m',
            trailing: _AccuracyBadge(quality: quality),
          ),

          const SizedBox(height: 13),

          _LocationMetric(
            label: 'Latitud',
            value: position.latitude.toStringAsFixed(6),
          ),

          const SizedBox(height: 13),

          _LocationMetric(
            label: 'Longitud',
            value: position.longitude.toStringAsFixed(6),
          ),

          if (position.altitude != 0) ...[
            const SizedBox(height: 13),
            _LocationMetric(
              label: 'Altitud',
              value: '${position.altitude.toStringAsFixed(0)} m',
            ),
          ],

          const SizedBox(height: 13),

          _LocationMetric(
            label: 'Actualizado',
            value: lastUpdate == null
                ? 'Ahora'
                : DateFormat('HH:mm:ss').format(lastUpdate!),
          ),

          if (accuracy > 50) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 20,
                  ),
                  SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'La precisión GPS es baja. '
                      'Es recomendable esperar unos segundos '
                      'y actualizar la ubicación.',
                      style: TextStyle(
                        color: AppColors.neutralDark,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static _AccuracyQuality _resolveAccuracyQuality(double accuracy) {
    if (accuracy <= 15) {
      return _AccuracyQuality.good;
    }

    if (accuracy <= 50) {
      return _AccuracyQuality.regular;
    }

    return _AccuracyQuality.poor;
  }
}

final class _LocationMetric extends StatelessWidget {
  const _LocationMetric({
    required this.label,
    required this.value,
    this.trailing,
  });

  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.neutralDark.withValues(alpha: 0.68),
              fontSize: 12.5,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.secondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

enum _AccuracyQuality { good, regular, poor }

final class _AccuracyBadge extends StatelessWidget {
  const _AccuracyBadge({required this.quality});

  final _AccuracyQuality quality;

  @override
  Widget build(BuildContext context) {
    final label = switch (quality) {
      _AccuracyQuality.good => 'Buena',
      _AccuracyQuality.regular => 'Regular',
      _AccuracyQuality.poor => 'Baja',
    };

    final color = switch (quality) {
      _AccuracyQuality.good => Colors.green,
      _AccuracyQuality.regular => Colors.orange,
      _AccuracyQuality.poor => Colors.red,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

final class _MapCard extends StatelessWidget {
  const _MapCard({
    required this.position,
    required this.loading,
    required this.error,
    required this.onMapCreated,
    required this.onRetry,
    required this.onRecenter,
  });

  final Position? position;
  final bool loading;
  final String? error;
  final ValueChanged<GoogleMapController> onMapCreated;
  final VoidCallback onRetry;
  final VoidCallback onRecenter;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 360,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4EAF0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (loading && position == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null && position == null) {
      return _MapUnavailable(message: error!, onRetry: onRetry);
    }

    final currentPosition = position;

    if (currentPosition == null) {
      return _MapUnavailable(
        message: 'Ubicación no disponible.',
        onRetry: onRetry,
      );
    }

    final target = LatLng(currentPosition.latitude, currentPosition.longitude);

    return Stack(
      children: [
        Positioned.fill(
          child: GoogleMap(
            initialCameraPosition: CameraPosition(target: target, zoom: 17.5),
            onMapCreated: onMapCreated,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            compassEnabled: true,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            markers: {
              Marker(
                markerId: const MarkerId('inspector_location'),
                position: target,
                infoWindow: const InfoWindow(title: 'Ubicación del inspector'),
              ),
            },
          ),
        ),

        Positioned(
          right: 12,
          bottom: 12,
          child: Material(
            color: AppColors.surface,
            elevation: 4,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: onRecenter,
              borderRadius: BorderRadius.circular(14),
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Icon(
                  Icons.my_location_rounded,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

final class _LoadingLocationCard extends StatelessWidget {
  const _LoadingLocationCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4EAF0)),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Obteniendo ubicación',
                  style: TextStyle(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Esperando una lectura GPS precisa...',
                  style: TextStyle(color: AppColors.neutralDark, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final class _LocationErrorCard extends StatelessWidget {
  const _LocationErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          const Icon(Icons.location_off_rounded, color: Colors.red, size: 36),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.neutralDark,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

final class _MapUnavailable extends StatelessWidget {
  const _MapUnavailable({required this.message, required this.onRetry});

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
              Icons.map_outlined,
              size: 42,
              color: AppColors.neutralDark,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.neutralDark,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Actualizar'),
            ),
          ],
        ),
      ),
    );
  }
}

final class _ArrivalConfirmedCard extends StatelessWidget {
  const _ArrivalConfirmedCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.withValues(alpha: 0.18)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_rounded, color: Colors.green, size: 21),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'La llegada fue registrada correctamente. '
              'Ya puedes continuar con la inspección.',
              style: TextStyle(
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
