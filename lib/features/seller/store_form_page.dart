import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';

class StoreFormPage extends ConsumerStatefulWidget {
  const StoreFormPage({super.key});

  @override
  ConsumerState<StoreFormPage> createState() => _StoreFormPageState();
}

class _StoreFormPageState extends ConsumerState<StoreFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _slug = TextEditingController();
  final _description = TextEditingController();
  final _phone = TextEditingController();
  final _city = TextEditingController();
  final _logoUrl = TextEditingController();

  bool _saving = false;
  bool _slugTouched = false;
  bool _hydrated = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _slug.dispose();
    _description.dispose();
    _phone.dispose();
    _city.dispose();
    _logoUrl.dispose();
    super.dispose();
  }

  void _hydrate(Store store) {
    if (_hydrated) return;
    _hydrated = true;
    _name.text = store.name;
    _slug.text = store.slug;
    _description.text = store.description;
    _phone.text = store.phone ?? '';
    _city.text = store.city ?? '';
    _logoUrl.text = store.logoUrl ?? '';
    _slugTouched = true;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final slug = slugify(_slug.text.trim().isEmpty ? _name.text : _slug.text);
      final draft = StoreDraft(
        name: _name.text.trim(),
        slug: slug,
        description: _description.text.trim(),
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        city: _city.text.trim().isEmpty ? null : _city.text.trim(),
        logoUrl: _logoUrl.text.trim().isEmpty ? null : _logoUrl.text.trim(),
      );
      await ref.read(repositoryProvider).saveStore(draft);
      refreshCatalog(ref);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tienda guardada.')));
      context.go('/seller');
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return Center(
        child: EmptyState(
          icon: Icons.lock_outline_rounded,
          title: 'Necesitas iniciar sesión',
          subtitle: 'Ingresa para crear o editar tu tienda.',
          action: FilledButton(
            onPressed: () => context.go('/login'),
            child: const Text('Ingresar'),
          ),
        ),
      );
    }

    final store = ref.watch(myStoreProvider);

    return AsyncView<Store?>(
      value: store,
      builder: (data) {
        if (data != null) _hydrate(data);
        return _buildForm(context, editing: data != null);
      },
    );
  }

  Widget _buildForm(BuildContext context, {required bool editing}) {
    final base = slugify(_name.text);
    final publicPath = '/store/${_slug.text.isEmpty ? base : _slug.text}';

    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 48),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton.icon(
                    onPressed: () => context.go('/seller'),
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('Volver al panel'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.muted,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    editing ? 'Editar mi tienda' : 'Abrir mi tienda',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Así te verán los compradores en el catálogo y en tu '
                    'página pública.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 22),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _name,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Nombre de la tienda',
                              hintText: 'Ej. Casa Bonita',
                            ),
                            onChanged: (value) {
                              if (!_slugTouched) {
                                _slug.text = slugify(value);
                                setState(() {});
                              }
                            },
                            validator: (value) {
                              if ((value ?? '').trim().length < 3) {
                                return 'Escribe un nombre de al menos 3 letras.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _slug,
                            decoration: InputDecoration(
                              labelText: 'Enlace de la tienda',
                              prefixText: '/store/',
                              helperText:
                                  'Solo letras minúsculas, números y guiones.',
                            ),
                            onChanged: (value) {
                              _slugTouched = true;
                              setState(() {});
                            },
                            validator: (value) {
                              final slug = slugify(
                                (value ?? '').trim().isEmpty
                                    ? _name.text
                                    : value!,
                              );
                              if (slug.length < 3) {
                                return 'El enlace es demasiado corto.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _description,
                            maxLines: 4,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              labelText: 'Descripción',
                              hintText:
                                  'Cuenta qué vendes y qué hace especial a tu '
                                  'tienda.',
                              alignLabelWithHint: true,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _phone,
                                  keyboardType: TextInputType.phone,
                                  decoration: const InputDecoration(
                                    labelText: 'WhatsApp / teléfono',
                                    hintText: '+52 555 000 0000',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _city,
                                  textCapitalization: TextCapitalization.words,
                                  decoration: const InputDecoration(
                                    labelText: 'Ciudad',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _logoUrl,
                            decoration: const InputDecoration(
                              labelText: 'URL del logo (opcional)',
                              hintText: 'https://...',
                            ),
                          ),
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.canvas,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.link_rounded,
                                  size: 18,
                                  color: AppColors.muted,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Tu página: $publicPath',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    InlineAlert(message: _error!),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _saving
                              ? null
                              : () => context.go('/seller'),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: _saving ? null : _save,
                          child: _saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  editing ? 'Guardar cambios' : 'Crear tienda',
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
