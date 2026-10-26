import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(repositoryProvider)
          .signIn(email: _email.text, password: _password.text);
      if (mounted) context.go('/seller');
    } catch (error) {
      setState(() => _error = _friendly(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendly(Object error) {
    final text = error.toString();
    if (text.contains('Invalid login credentials')) {
      return 'Correo o contraseña incorrectos.';
    }
    if (text.contains('Email not confirmed')) {
      return 'Confirma tu correo antes de ingresar.';
    }
    return text.replaceFirst('Exception: ', '');
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isDemo = ref.watch(repositoryProvider).isDemo;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.storefront_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Bienvenido de vuelta',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.6,
                          ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Ingresa para administrar tu tienda y tus productos.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: 24),
                    if (user != null) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Ya iniciaste sesión como ${user.displayName}.',
                          style: const TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => context.go('/seller'),
                        child: const Text('Ir a mi panel'),
                      ),
                    ] else ...[
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(
                          labelText: 'Correo electrónico',
                          prefixIcon: Icon(Icons.mail_outline_rounded),
                        ),
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.isEmpty || !text.contains('@')) {
                            return 'Escribe un correo válido.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _password,
                        obscureText: _obscure,
                        autofillHints: const [AutofillHints.password],
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if ((value ?? '').length < 6) {
                            return 'Mínimo 6 caracteres.';
                          }
                          return null;
                        },
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 14),
                        InlineAlert(message: _error!),
                      ],
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: _loading ? null : _submit,
                        child: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Ingresar'),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text(
                            '¿Aún no tienes cuenta?',
                            style: TextStyle(color: AppColors.muted),
                          ),
                          TextButton(
                            onPressed: () => context.go('/register'),
                            child: const Text('Crear una'),
                          ),
                        ],
                      ),
                      if (isDemo)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.canvas,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Modo demo: escribe cualquier correo y contraseña '
                            'de 6+ caracteres.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
