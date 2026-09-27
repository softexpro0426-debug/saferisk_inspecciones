import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

final class SafeRiskLoginHeader extends StatelessWidget {
  const SafeRiskLoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          'assets/branding/saferisk_logo_horizontal.png',
          width: 170,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 20),
        const Text(
          'TÉCNICAMENTE SEGUROS',
          style: TextStyle(
            color: AppColors.neutralDark,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}
