import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/inspection_case.dart';

final class InspectionCard extends StatelessWidget {
  const InspectionCard({
    required this.inspection,
    required this.onTap,
    super.key,
  });

  final InspectionCase inspection;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Caso #${inspection.nroCaso}',
                style: const TextStyle(
                  color: AppColors.secondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                inspection.asegurado.isNotEmpty
                    ? inspection.asegurado
                    : inspection.nombre,
              ),
              const SizedBox(height: 8),
              Text(inspection.placa.isEmpty ? 'Sin placa' : inspection.placa),
              const SizedBox(height: 8),
              Text('${inspection.marca} ${inspection.modelo}'.trim()),
              const SizedBox(height: 12),
              Text(
                inspection.estado,
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
