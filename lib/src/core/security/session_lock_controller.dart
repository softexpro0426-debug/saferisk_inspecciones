import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'device_auth_service.dart';
import '../legal/terms_acceptance_store.dart';

enum SessionAccess { signedOut, locked, termsRequired, unlocked }

final class SessionLockState {
  const SessionLockState({
    this.access = SessionAccess.signedOut,
    this.usuario,
    this.checking = false,
    this.message,
  });
  final SessionAccess access;
  final String? usuario;
  final bool checking;
  final String? message;
  bool get isUnlocked => access == SessionAccess.unlocked;
  bool get hasSession => usuario != null;
}

final sessionLockProvider =
    NotifierProvider<SessionLockController, SessionLockState>(
      SessionLockController.new,
    );

/// Unlock grants are memory-only and belong to one session generation.
final class SessionLockController extends Notifier<SessionLockState> {
  bool get isUnlocked => state.isUnlocked;
  int _generation = 0;
  bool _background = false;
  bool _devicePrompt = false;

  @override
  SessionLockState build() => const SessionLockState();

  void restore(String usuario) {
    _generation++;
    state = SessionLockState(access: SessionAccess.locked, usuario: usuario);
  }

  Future<void> signedIn(String usuario) async {
    final generation = ++_generation;
    state = SessionLockState(
      access: _background ? SessionAccess.locked : SessionAccess.termsRequired,
      usuario: usuario,
      checking: true,
    );
    await _resolveTerms(usuario, generation);
  }

  void signedOut() {
    _generation++;
    state = const SessionLockState();
  }

  void backgrounded() {
    _background = true;
    if (!_devicePrompt) _generation++;
    if (state.hasSession) {
      state = SessionLockState(
        access: SessionAccess.locked,
        usuario: state.usuario,
        checking: state.checking,
      );
    }
  }

  void resumed() => _background = false;

  Future<void> authenticateDevice({required bool biometricOnly}) => _attempt(
    () => ref
        .read(deviceAuthServiceProvider)
        .authenticate(biometricOnly: biometricOnly),
    devicePrompt: true,
  );

  Future<void> authenticatePassword(Future<bool> Function() verify) =>
      _attempt(verify);

  Future<void> _attempt(
    Future<bool> Function() verify, {
    bool devicePrompt = false,
  }) async {
    if (state.access != SessionAccess.locked || state.checking || _background) {
      return;
    }
    final generation = _generation;
    final usuario = state.usuario;
    _devicePrompt = devicePrompt;
    state = SessionLockState(
      access: SessionAccess.locked,
      usuario: usuario,
      checking: true,
    );
    var success = false;
    String? message;
    try {
      success = await verify();
      if (!success) {
        message = 'No se verificó tu identidad. Puedes volver a intentarlo.';
      }
    } on SessionUnlockFailure catch (error) {
      message = error.message;
    } catch (_) {
      message = 'No pudimos desbloquear la sesión. Vuelve a intentarlo.';
    } finally {
      _devicePrompt = false;
    }
    if (!ref.mounted || state.usuario != usuario) return;
    // An authentication result from before a session change cannot reopen it.
    final allowed = success && generation == _generation && !_background;
    if (allowed && usuario != null) {
      await _resolveTerms(usuario, generation);
      return;
    }
    state = SessionLockState(
      access: SessionAccess.locked,
      usuario: usuario,
      message: message,
    );
  }

  Future<void> _resolveTerms(String usuario, int generation) async {
    var accepted = false;
    String? message;
    try {
      accepted = await ref
          .read(termsAcceptanceStoreProvider)
          .hasAccepted(usuario);
    } catch (_) {
      message = 'No pudimos comprobar la aceptación. Vuelve a intentarlo.';
    }
    if (!ref.mounted || state.usuario != usuario) return;
    if (_generation != generation || _background) {
      state = SessionLockState(access: SessionAccess.locked, usuario: usuario);
      return;
    }
    state = SessionLockState(
      access: accepted ? SessionAccess.unlocked : SessionAccess.termsRequired,
      usuario: usuario,
      message: message,
    );
  }

  Future<void> acceptTerms() async {
    if (state.access != SessionAccess.termsRequired ||
        state.checking ||
        _background) {
      return;
    }
    final usuario = state.usuario;
    if (usuario == null) return;
    final generation = _generation;
    state = SessionLockState(
      access: SessionAccess.termsRequired,
      usuario: usuario,
      checking: true,
    );
    String? message;
    try {
      await ref.read(termsAcceptanceStoreProvider).accept(usuario);
    } catch (_) {
      message = 'No pudimos guardar tu aceptación. Vuelve a intentarlo.';
    }
    if (!ref.mounted || state.usuario != usuario) return;
    final sameSession = generation == _generation && !_background;
    state = SessionLockState(
      access: !sameSession
          ? SessionAccess.locked
          : message == null
          ? SessionAccess.unlocked
          : SessionAccess.termsRequired,
      usuario: usuario,
      message: message,
    );
  }
}
