import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'terms_document.dart';

/// Shared by the mandatory acceptance screen and the read-only Profile page.
final class TermsDocumentView extends StatelessWidget {
  const TermsDocumentView({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.gavel_rounded, color: Colors.white, size: 28),
            SizedBox(height: 12),
            Text(
              TermsDocument.title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 23,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Versión ${TermsDocument.version} · ${TermsDocument.updatedLabel}',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
      for (var index = 0; index < TermsDocument.sections.length; index++) ...[
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${index + 1}. ${TermsDocument.sections[index].title}',
                style: const TextStyle(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                TermsDocument.sections[index].content,
                style: const TextStyle(
                  color: AppColors.neutralDark,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    ],
  );
}
