import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../theme/app_colors.dart';
import 'location_providers.dart';
import 'location_service.dart';

/// Shows the same position provider refreshed when an inspection step is sent.
final class CurrentLocationCard extends ConsumerWidget {
  const CurrentLocationCard({this.busy = false, super.key});

  final bool busy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = ref.watch(currentPositionProvider);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4EAF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            child: Row(
              children: [
                const Icon(Icons.my_location_rounded, color: AppColors.primary),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Tu ubicación',
                    style: TextStyle(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Actualizar ubicación',
                  onPressed: busy || position.isLoading
                      ? null
                      : () => ref.invalidate(currentPositionProvider),
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
          ),
          if (position.isLoading) const LinearProgressIndicator(minHeight: 2),
          position.when(
            data: (value) =>
                _PositionMap(position: value, busy: busy || position.isLoading),
            loading: () => const SizedBox(
              height: 240,
              child: Center(child: Text('Buscando tu ubicación…')),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(switch (error) {
                    LocationServiceDisabledException() =>
                      'Activa la ubicación del teléfono para ver el mapa.',
                    LocationPermissionException() =>
                      'Permite el acceso a tu ubicación para ver el mapa.',
                    TimeoutException() =>
                      'No pudimos obtener tu ubicación. Vuelve a intentarlo.',
                    _ =>
                      'No pudimos obtener tu ubicación. Vuelve a intentarlo.',
                  }),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: busy
                            ? null
                            : () => ref.invalidate(currentPositionProvider),
                        child: const Text('Reintentar'),
                      ),
                      TextButton(
                        onPressed: busy
                            ? null
                            : () async {
                                if (error is LocationServiceDisabledException) {
                                  await Geolocator.openLocationSettings();
                                } else {
                                  await Geolocator.openAppSettings();
                                }
                              },
                        child: const Text('Abrir ajustes'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final class _PositionMap extends StatefulWidget {
  const _PositionMap({required this.position, required this.busy});
  final Position position;
  final bool busy;

  @override
  State<_PositionMap> createState() => _PositionMapState();
}

final class _PositionMapState extends State<_PositionMap> {
  GoogleMapController? _controller;
  LatLng get _target =>
      LatLng(widget.position.latitude, widget.position.longitude);

  Future<void> _recenter() async {
    try {
      await _controller?.animateCamera(CameraUpdate.newLatLngZoom(_target, 17));
    } catch (_) {
      // Camera movement is optional; a disposed map must not affect the step.
    }
  }

  @override
  void didUpdateWidget(covariant _PositionMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.position != widget.position) unawaited(_recenter());
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 260,
    child: Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: _target, zoom: 17),
          onMapCreated: (controller) => _controller = controller,
          markers: {
            Marker(
              markerId: const MarkerId('inspector'),
              position: _target,
              infoWindow: const InfoWindow(title: 'Tu ubicación'),
            ),
          },
          mapToolbarEnabled: false,
          zoomControlsEnabled: false,
          myLocationButtonEnabled: false,
        ),
        Positioned(
          right: 12,
          bottom: 12,
          child: Material(
            color: AppColors.surface,
            elevation: 2,
            shape: const CircleBorder(),
            child: IconButton(
              tooltip: 'Centrar mi ubicación',
              onPressed: widget.busy ? null : _recenter,
              icon: const Icon(
                Icons.my_location_rounded,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
