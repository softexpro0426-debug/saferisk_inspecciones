import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/network_providers.dart';
import '../security/session_lock_controller.dart';
import '../theme/app_colors.dart';
import 'terms_document_view.dart';

final class TermsAcceptancePage extends ConsumerStatefulWidget {
  const TermsAcceptancePage({super.key});

  @override
  ConsumerState<TermsAcceptancePage> createState() =>
      _TermsAcceptancePageState();
}

final class _TermsAcceptancePageState
    extends ConsumerState<TermsAcceptancePage> {
  bool _accepted = false;
  bool _leaving = false;
  String? _error;

  Future<void> _decline() async {
    if (_leaving || ref.read(sessionLockProvider).checking) return;
    setState(() {
      _leaving = true;
      _error = null;
    });
    try {
      await ref.read(sessionStorageProvider).clearSession();
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'No pudimos cerrar la sesión. Vuelve a intentarlo.',
        );
      }
    } finally {
      if (mounted) setState(() => _leaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sessionLockProvider);
    final busy = state.checking || _leaving;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Antes de continuar',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  color: AppColors.secondary,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Revisa las condiciones de uso de SafeRisk Inspecciones.',
                style: TextStyle(color: AppColors.neutralDark),
              ),
              SizedBox(height: 20),
              TermsDocumentView(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CheckboxListTile(
                value: _accepted,
                onChanged: busy
                    ? null
                    : (value) => setState(() => _accepted = value ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'He leído y acepto los Términos y condiciones.',
                ),
              ),
              if (_error != null || state.message != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _error ?? state.message!,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              FilledButton(
                onPressed: busy || !_accepted
                    ? null
                    : () =>
                          ref.read(sessionLockProvider.notifier).acceptTerms(),
                child: busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Aceptar y continuar'),
              ),
              TextButton(
                onPressed: busy ? null : _decline,
                child: const Text('No aceptar y salir'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
