import 'package:flutter/material.dart';

import '../../../../core/legal/terms_document_view.dart';
import '../../../../core/theme/app_colors.dart';

final class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(title: const Text('Términos y condiciones')),
    body: const SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 18, 20, 40),
        child: TermsDocumentView(),
      ),
    ),
  );
}
