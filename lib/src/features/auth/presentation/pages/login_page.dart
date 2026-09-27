import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../controllers/login_controller.dart';
import '../controllers/login_state.dart';
import '../widgets/saferisk_login_header.dart';

import '../../domain/entities/user_type.dart';
import '../widgets/broker_access_dialog.dart';

final class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

final class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _userController;
  late final TextEditingController _passwordController;

  late final FocusNode _userFocusNode;
  late final FocusNode _passwordFocusNode;

  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();

    _userController = TextEditingController();
    _passwordController = TextEditingController();

    _userFocusNode = FocusNode();
    _passwordFocusNode = FocusNode();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0, 1, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Curves.easeOutCubic,
          ),
        );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _userController.dispose();
    _passwordController.dispose();

    _userFocusNode.dispose();
    _passwordFocusNode.dispose();

    _entranceController.dispose();

    super.dispose();
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      HapticFeedback.mediumImpact();
      return;
    }

    HapticFeedback.selectionClick();

    await ref
        .read(loginControllerProvider.notifier)
        .login(usuario: _userController.text, clave: _passwordController.text);
  }

  Future<void> _handleLoginSuccess(String tipoUsuario) async {
    final userType = UserType.fromApi(tipoUsuario);

    switch (userType) {
      case UserType.inspector:
        HapticFeedback.lightImpact();

        if (!mounted) {
          return;
        }

        context.go('/home');
        return;

      case UserType.broker:
        HapticFeedback.mediumImpact();

        if (!mounted) {
          return;
        }

        await showBrokerAccessDialog(context: context, ref: ref);

        return;

      case UserType.unknown:
        HapticFeedback.mediumImpact();

        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.block_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tu perfil no está habilitado para utilizar '
                      'SafeRisk Inspecciones.',
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.secondary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );

        return;
    }
  }

  void _showLoginFailure(String message) {
    if (!mounted) {
      return;
    }

    HapticFeedback.mediumImpact();

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: AppColors.secondary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<LoginState>(loginControllerProvider, (previous, next) {
      switch (next) {
        case LoginSuccess(:final session):
          _handleLoginSuccess(session.tipoUsuario);

        case LoginFailure(:final message):
          _showLoginFailure(message);

        case LoginIdle():
        case LoginSubmitting():
          break;
      }
    });

    final loginState = ref.watch(loginControllerProvider);
    final isSubmitting = loginState is LoginSubmitting;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.background,
              AppColors.secondary.withValues(alpha: 0.06),
              AppColors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();
            },
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: AutofillGroup(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SafeRiskLoginHeader(),
                              const SizedBox(height: 40),
                              _LoginCard(
                                userController: _userController,
                                passwordController: _passwordController,
                                userFocusNode: _userFocusNode,
                                passwordFocusNode: _passwordFocusNode,
                                isSubmitting: isSubmitting,
                                obscurePassword: _obscurePassword,
                                onToggleVisibility: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                onFieldChanged: () {
                                  ref
                                      .read(loginControllerProvider.notifier)
                                      .clearError();
                                },
                                onSubmit: _submit,
                              ),
                              const SizedBox(height: 28),
                              const _Footer(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.userController,
    required this.passwordController,
    required this.userFocusNode,
    required this.passwordFocusNode,
    required this.isSubmitting,
    required this.obscurePassword,
    required this.onToggleVisibility,
    required this.onFieldChanged,
    required this.onSubmit,
  });

  final TextEditingController userController;
  final TextEditingController passwordController;
  final FocusNode userFocusNode;
  final FocusNode passwordFocusNode;
  final bool isSubmitting;
  final bool obscurePassword;
  final VoidCallback onToggleVisibility;
  final VoidCallback onFieldChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.08),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _WelcomeSection(),
          const SizedBox(height: 28),
          _UserField(
            controller: userController,
            focusNode: userFocusNode,
            enabled: !isSubmitting,
            onSubmitted: (_) {
              passwordFocusNode.requestFocus();
            },
            onChanged: (_) => onFieldChanged(),
          ),
          const SizedBox(height: 14),
          _PasswordField(
            controller: passwordController,
            focusNode: passwordFocusNode,
            enabled: !isSubmitting,
            obscurePassword: obscurePassword,
            onToggleVisibility: onToggleVisibility,
            onSubmitted: (_) {
              if (!isSubmitting) {
                onSubmit();
              }
            },
            onChanged: (_) => onFieldChanged(),
          ),
          const SizedBox(height: 18),
          _SubmitButton(
            isSubmitting: isSubmitting,
            onPressed: isSubmitting ? null : onSubmit,
          ),
        ],
      ),
    );
  }
}

final class _WelcomeSection extends StatelessWidget {
  const _WelcomeSection();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bienvenido',
          style: TextStyle(
            color: AppColors.secondary,
            fontSize: 26,
            height: 1.1,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Ingresa tus credenciales para continuar con tus inspecciones.',
          style: TextStyle(
            color: AppColors.neutralDark,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

final class _UserField extends StatelessWidget {
  const _UserField({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.onSubmitted,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final ValueChanged<String> onSubmitted;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      autofillHints: const [AutofillHints.username],
      textInputAction: TextInputAction.next,
      keyboardType: TextInputType.text,
      autocorrect: false,
      enableSuggestions: false,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: 'Usuario',
        hintText: 'Ingresa tu usuario',
        filled: true,
        fillColor: AppColors.background,
        prefixIcon: const Icon(Icons.person_outline_rounded),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.secondary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
        ),
      ),
      validator: (value) {
        final text = value?.trim() ?? '';

        if (text.isEmpty) {
          return 'Ingresa tu usuario';
        }

        return null;
      },
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
    );
  }
}

final class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.obscurePassword,
    required this.onToggleVisibility,
    required this.onSubmitted,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final bool obscurePassword;
  final VoidCallback onToggleVisibility;
  final ValueChanged<String> onSubmitted;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      obscureText: obscurePassword,
      autofillHints: const [AutofillHints.password],
      textInputAction: TextInputAction.done,
      autocorrect: false,
      enableSuggestions: false,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: 'Contraseña',
        hintText: 'Ingresa tu contraseña',
        filled: true,
        fillColor: AppColors.background,
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          tooltip: obscurePassword
              ? 'Mostrar contraseña'
              : 'Ocultar contraseña',
          onPressed: onToggleVisibility,
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: Icon(
              obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              key: ValueKey(obscurePassword),
            ),
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.secondary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Ingresa tu contraseña';
        }

        return null;
      },
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
    );
  }
}

final class _SubmitButton extends StatelessWidget {
  const _SubmitButton({required this.isSubmitting, required this.onPressed});

  final bool isSubmitting;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: FilledButton(
        style:
            FilledButton.styleFrom(
              backgroundColor: AppColors.secondary,
              disabledBackgroundColor: AppColors.secondary.withValues(
                alpha: 0.6,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ).copyWith(
              overlayColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.pressed)
                    ? Colors.white.withValues(alpha: 0.12)
                    : null,
              ),
            ),
        onPressed: onPressed,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: animation, child: child),
          ),
          child: isSubmitting
              ? const SizedBox(
                  key: ValueKey('loading'),
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Ingresar',
                  key: ValueKey('text'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
        ),
      ),
    );
  }
}

final class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Text(
      'SafeRisk Inspecciones',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: AppColors.neutralDark.withValues(alpha: 0.5),
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
      ),
    );
  }
}
