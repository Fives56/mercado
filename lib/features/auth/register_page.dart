import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
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
      final user = await ref
          .read(repositoryProvider)
          .signUp(
            fullName: _name.text,
            email: _email.text,
            password: _password.text,
          );
      if (!mounted) return;
      if (user == null) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Revisa tu correo'),
            content: const Text(
              'Te enviamos un enlace de confirmación. Ábrelo y luego inicia '
              'sesión para crear tu tienda.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Entendido'),
              ),
            ],
          ),
        );
        if (mounted) context.go('/login');
      } else {
        context.go('/seller');
      }
    } catch (error) {
      setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.person_add_alt_1_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Crea tu cuenta',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.6,
                          ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tu cuenta te permite abrir una tienda y publicar '
                      'productos gratis.',
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
                        controller: _name,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Nombre completo',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        validator: (value) {
                          if ((value ?? '').trim().length < 2) {
                            return 'Escribe tu nombre.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
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
                        autofillHints: const [AutofillHints.newPassword],
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          helperText: 'Mínimo 6 caracteres',
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
                            : const Text('Crear cuenta'),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text(
                            '¿Ya tienes cuenta?',
                            style: TextStyle(color: AppColors.muted),
                          ),
                          TextButton(
                            onPressed: () => context.go('/login'),
                            child: const Text('Ingresar'),
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
                            'Modo demo: la cuenta se crea solo en memoria.',
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
