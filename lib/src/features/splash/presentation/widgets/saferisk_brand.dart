import 'package:flutter/material.dart';

final class SafeRiskBrand extends StatelessWidget {
  const SafeRiskBrand({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/branding/saferisk_logo_white.png',
          width: 190,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 18),
        Text(
          'TÉCNICAMENTE SEGUROS',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.72),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.2,
          ),
        ),
      ],
    );
  }
}
