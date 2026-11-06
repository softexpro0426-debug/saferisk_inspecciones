import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/entities/user_type.dart';
import '../network/network_providers.dart';
import '../theme/app_colors.dart';
import 'device_auth_service.dart';
import 'session_lock_controller.dart';

final class SessionUnlockPage extends ConsumerStatefulWidget {
  const SessionUnlockPage({super.key});

  @override
  ConsumerState<SessionUnlockPage> createState() => _SessionUnlockPageState();
}

final class _SessionUnlockPageState extends ConsumerState<SessionUnlockPage> {
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _usePassword = false;
  bool _obscure = true;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final access = ref.read(sessionLockProvider);
    if (access.checking ||
        access.usuario == null ||
        !(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    final usuario = access.usuario!;
    final clave = _password.text;
    final repository = ref.read(authRepositoryProvider);
    await ref.read(sessionLockProvider.notifier).authenticatePassword(() async {
      try {
        final session = await repository.login(usuario: usuario, clave: clave);
        if (session.usuario.trim().toLowerCase() !=
                usuario.trim().toLowerCase() ||
            UserType.fromApi(session.tipoUsuario) != UserType.inspector) {
          throw const SessionUnlockFailure(
            'Usa la contraseña de la cuenta que tiene la sesión abierta.',
          );
        }
        return true;
      } on AuthException catch (error) {
        throw SessionUnlockFailure(error.message);
      }
    });
    if (mounted) _password.clear();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sessionLockProvider);
    final controller = ref.read(sessionLockProvider.notifier);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.lock_outline_rounded,
                    size: 58,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Desbloquea SafeRisk',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.secondary,
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Verifica tu identidad para continuar.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.neutralDark),
                  ),
                  const SizedBox(height: 28),
                  if (!_usePassword) ...[
                    FilledButton.icon(
                      onPressed: state.checking
                          ? null
                          : () => controller.authenticateDevice(
                              biometricOnly: true,
                            ),
                      icon: const Icon(Icons.fingerprint_rounded),
                      label: const Text('Usar biometría'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: state.checking
                          ? null
                          : () => controller.authenticateDevice(
                              biometricOnly: false,
                            ),
                      icon: const Icon(Icons.phonelink_lock_rounded),
                      label: const Text('Usar bloqueo del teléfono'),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'PIN, patrón o contraseña del dispositivo',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.neutralDark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: state.checking
                          ? null
                          : () => setState(() => _usePassword = true),
                      child: const Text('Usar usuario y contraseña'),
                    ),
                  ] else
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            initialValue: state.usuario,
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'Usuario',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _password,
                            enabled: !state.checking,
                            obscureText: _obscure,
                            enableSuggestions: false,
                            autocorrect: false,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Ingresa tu contraseña.'
                                : null,
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                tooltip: _obscure
                                    ? 'Mostrar contraseña'
                                    : 'Ocultar contraseña',
                                onPressed: state.checking
                                    ? null
                                    : () =>
                                          setState(() => _obscure = !_obscure),
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          FilledButton(
                            onPressed: state.checking ? null : _submit,
                            child: const Text('Desbloquear'),
                          ),
                          TextButton(
                            onPressed: state.checking
                                ? null
                                : () {
                                    _password.clear();
                                    setState(() => _usePassword = false);
                                  },
                            child: const Text('Otras formas de acceso'),
                          ),
                        ],
                      ),
                    ),
                  if (state.checking) ...[
                    const SizedBox(height: 20),
                    const Center(child: CircularProgressIndicator()),
                  ],
                  if (state.message != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      state.message!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
