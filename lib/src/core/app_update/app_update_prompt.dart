import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_version_policy.dart';

final class AppUpdatePrompt extends StatefulWidget {
  const AppUpdatePrompt({
    required this.decision,
    required this.onRetry,
    required this.onContinue,
    super.key,
  });
  final AppUpdateDecision decision;
  final VoidCallback onRetry;
  final VoidCallback onContinue;

  @override
  State<AppUpdatePrompt> createState() => _AppUpdatePromptState();
}

final class _AppUpdatePromptState extends State<AppUpdatePrompt>
    with WidgetsBindingObserver {
  bool _opening = false;
  bool _leftForStore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _leftForStore) {
      _leftForStore = false;
      widget.onRetry();
    }
  }

  Future<void> _openStore() async {
    if (_opening) return;
    setState(() {
      _opening = true;
      _error = null;
    });
    try {
      _leftForStore = true;
      final opened = await launchUrl(
        widget.decision.policy.url,
        mode: LaunchMode.externalApplication,
      );
      if (!opened) throw StateError('Store unavailable');
    } catch (_) {
      _leftForStore = false;
      if (mounted) {
        setState(() {
          _error = 'No fue posible abrir la tienda. Inténtalo nuevamente.';
        });
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final decision = widget.decision;
    return PopScope(
      canPop: !decision.required,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                decision.required
                    ? 'Actualización necesaria'
                    : 'Nueva versión disponible',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text('Versión ${decision.policy.version}'),
              if (decision.policy.notes.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 100),
                    child: SingleChildScrollView(
                      child: Text(decision.policy.notes),
                    ),
                  ),
                ),
              if (decision.required)
                const Text('Actualiza la aplicación para continuar.'),
              if (_error != null) Text(_error!),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _opening ? null : _openStore,
                child: Text(_opening ? 'Abriendo...' : 'Actualizar'),
              ),
              TextButton(
                onPressed: _opening ? null : widget.onRetry,
                child: const Text('Volver a comprobar'),
              ),
              if (!decision.required)
                TextButton(
                  onPressed: _opening ? null : widget.onContinue,
                  child: const Text('Ahora no'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
