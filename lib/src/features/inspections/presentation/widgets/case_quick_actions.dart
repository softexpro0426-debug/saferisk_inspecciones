import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';

final class CaseQuickActions extends StatelessWidget {
  const CaseQuickActions({required this.plate, required this.phone, super.key});

  final String plate;
  final String phone;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionButton(
            icon: Icons.copy_rounded,
            label: 'Copiar placa',
            enabled: plate.trim().isNotEmpty,
            onTap: () {
              _copy(context, value: plate, message: 'Placa copiada.');
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.phone_outlined,
            label: 'Copiar teléfono',
            enabled: phone.trim().isNotEmpty,
            onTap: () {
              _copy(context, value: phone, message: 'Teléfono copiado.');
            },
          ),
        ),
      ],
    );
  }

  Future<void> _copy(
    BuildContext context, {
    required String value,
    required String message,
  }) async {
    await Clipboard.setData(ClipboardData(text: value.trim()));

    if (!context.mounted) {
      return;
    }

    HapticFeedback.selectionClick();

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1400),
        ),
      );
  }
}

final class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE4EAF0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: enabled
                    ? AppColors.primary
                    : AppColors.neutralDark.withValues(alpha: 0.4),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: enabled
                        ? AppColors.secondary
                        : AppColors.neutralDark.withValues(alpha: 0.45),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
