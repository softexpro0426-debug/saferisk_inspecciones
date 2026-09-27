import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/service_providers.dart';
import '../../../../core/theme/app_colors.dart';

Future<void> showBrokerAccessDialog({
  required BuildContext context,
  required WidgetRef ref,
}) async {
  HapticFeedback.mediumImpact();

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        icon: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.surfaceHighlight,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(
            Icons.business_center_outlined,
            color: AppColors.primary,
            size: 31,
          ),
        ),
        title: const Text(
          'Aplicación para Inspectores',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.secondary,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Esta aplicación de SafeRisk está disponible '
              'exclusivamente para usuarios con perfil de Inspector.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.neutralDark,
                fontSize: 13.5,
                height: 1.5,
              ),
            ),
            SizedBox(height: 14),
            Text(
              'Tu cuenta corresponde a un perfil Broker. '
              'Para continuar, utiliza la aplicación SafeRisk para Brokers.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.neutralDark,
                fontSize: 13.5,
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () async {
                try {
                  await ref.read(appStoreLauncherProvider).openBrokerStore();
                } catch (_) {
                  if (!dialogContext.mounted) {
                    return;
                  }

                  ScaffoldMessenger.of(dialogContext)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(
                        content: Text(
                          'No fue posible abrir la tienda de aplicaciones.',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                }
              },
              icon: const Icon(Icons.storefront_outlined),
              label: const Text('Descargar app para Brokers'),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Volver al inicio de sesión'),
            ),
          ),
        ],
      );
    },
  );
}
