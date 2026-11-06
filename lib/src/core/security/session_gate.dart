import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_colors.dart';
import 'session_lock_controller.dart';
import 'session_unlock_page.dart';
import '../legal/terms_acceptance_page.dart';

/// Wraps the root router so pushed details and dialogs cannot cover the lock.
final class SessionGate extends ConsumerStatefulWidget {
  const SessionGate({required this.child, super.key});
  final Widget child;

  @override
  ConsumerState<SessionGate> createState() => _SessionGateState();
}

final class _SessionGateState extends ConsumerState<SessionGate>
    with WidgetsBindingObserver {
  bool _obscured = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if (lifecycle != null && lifecycle != AppLifecycleState.resumed) {
      _obscured = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _obscured) {
          ref.read(sessionLockProvider.notifier).backgrounded();
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = ref.read(sessionLockProvider.notifier);
    if (state == AppLifecycleState.resumed) {
      controller.resumed();
      setState(() => _obscured = false);
    } else {
      FocusManager.instance.primaryFocus?.unfocus();
      if (state != AppLifecycleState.inactive) controller.backgrounded();
      setState(() => _obscured = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(sessionLockProvider);
    final blocked =
        access.access == SessionAccess.locked ||
        access.access == SessionAccess.termsRequired ||
        (_obscured && access.hasSession);
    return Stack(
      fit: StackFit.expand,
      children: [
        ExcludeSemantics(
          excluding: blocked,
          child: FocusScope(
            canRequestFocus: !blocked,
            child: Offstage(
              offstage: blocked,
              child: TickerMode(enabled: !blocked, child: widget.child),
            ),
          ),
        ),
        if (blocked)
          Positioned.fill(
            child: _obscured
                ? const Scaffold(
                    backgroundColor: AppColors.background,
                    body: Center(
                      child: Icon(
                        Icons.lock_outline_rounded,
                        size: 58,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : access.access == SessionAccess.termsRequired
                ? TermsAcceptancePage(key: ValueKey(access.usuario))
                : const SessionUnlockPage(),
          ),
      ],
    );
  }
}
