import 'dart:typed_data';

import 'package:file_selector/file_selector.dart' as fs;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';

class ProductFormPage extends ConsumerStatefulWidget {
  const ProductFormPage({super.key, this.productId});

  final String? productId;

  @override
  ConsumerState<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends ConsumerState<ProductFormPage> {
  static const _imageTypeGroup = fs.XTypeGroup(
    label: 'Imágenes',
    extensions: ['jpg', 'jpeg', 'png', 'webp', 'gif'],
    mimeTypes: ['image/jpeg', 'image/png', 'image/webp', 'image/gif'],
    uniformTypeIdentifiers: ['public.image'],
  );

  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _stock = TextEditingController();
  final _imageUrl = TextEditingController();

  String? _categoryId;
  bool _isActive = true;
  bool _saving = false;
  String? _error;
  String? _hydratedId;
  String? _existingDataImage;

  XFile? _selectedFile;
  Uint8List? _previewBytes;

  bool get _editing => widget.productId != null;

  bool get _isDesktop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS);

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _price.dispose();
    _stock.dispose();
    _imageUrl.dispose();
    super.dispose();
  }

  void _hydrate(Product product) {
    if (_hydratedId == product.id) return;
    _hydratedId = product.id;
    _title.text = product.title;
    _description.text = product.description;
    _price.text = product.price.toStringAsFixed(2);
    _stock.text = '${product.stock}';
    _categoryId = product.categoryId;
    _isActive = product.isActive;
    final image = product.imageUrl ?? '';
    if (image.startsWith('data:')) {
      _existingDataImage = image;
    } else {
      _imageUrl.text = image;
    }
  }

  Future<void> _pickImage() async {
    final XFile? picked;
    if (_isDesktop) {
      picked = await fs.openFile(acceptedTypeGroups: const [_imageTypeGroup]);
    } else {
      picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 88,
      );
    }
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() {
      _selectedFile = picked;
      _previewBytes = bytes;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final repository = ref.read(repositoryProvider);
      var image = _imageUrl.text.trim();
      if (image.isEmpty && _existingDataImage != null) {
        image = _existingDataImage!;
      }
      if (_selectedFile != null) {
        final uploaded = await repository.uploadProductImage(_selectedFile!);
        if (uploaded != null && uploaded.isNotEmpty) image = uploaded;
      }

      final price = double.tryParse(_price.text.replaceAll(',', '.')) ?? 0;
      final draft = ProductDraft(
        title: _title.text.trim(),
        description: _description.text.trim(),
        price: price,
        stock: int.tryParse(_stock.text.trim()) ?? 0,
        isActive: _isActive,
        imageUrl: image.isEmpty ? null : image,
        categoryId: _categoryId,
      );

      await repository.saveProduct(draft, id: widget.productId);
      refreshCatalog(ref);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _editing ? 'Producto actualizado.' : 'Producto publicado.',
          ),
        ),
      );
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
          subtitle: 'Ingresa para publicar productos en tu tienda.',
          action: FilledButton(
            onPressed: () => context.go('/login'),
            child: const Text('Ingresar'),
          ),
        ),
      );
    }

    if (_editing) {
      final product = ref.watch(productProvider(widget.productId!));
      return AsyncView<Product?>(
        value: product,
        builder: (item) {
          if (item == null) {
            return EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'Producto no encontrado',
              subtitle: 'No existe o no tienes permiso para editarlo.',
              action: OutlinedButton(
                onPressed: () => context.go('/seller'),
                child: const Text('Volver al panel'),
              ),
            );
          }
          _hydrate(item);
          return _buildForm(context);
        },
      );
    }

    return _buildForm(context);
  }

  Widget _buildForm(BuildContext context) {
    final categories = ref.watch(categoriesProvider);

    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
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
                    _editing ? 'Editar producto' : 'Nuevo producto',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _editing
                        ? 'Actualiza la información que verán los compradores.'
                        : 'Completa la información para publicarlo en el catálogo.',
                    style: const TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 22),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _FieldLabel('Información básica'),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _title,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              labelText: 'Título del producto',
                              hintText: 'Ej. Audífonos inalámbricos Pro',
                            ),
                            validator: (value) {
                              if ((value ?? '').trim().length < 4) {
                                return 'Escribe un título descriptivo.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _description,
                            maxLines: 5,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              labelText: 'Descripción',
                              hintText:
                                  'Materiales, medidas, colores, condición...',
                              alignLabelWithHint: true,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _price,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: const InputDecoration(
                                    labelText: 'Precio',
                                    prefixText: r'$ ',
                                  ),
                                  validator: (value) {
                                    final parsed = double.tryParse(
                                      (value ?? '').replaceAll(',', '.'),
                                    );
                                    if (parsed == null || parsed <= 0) {
                                      return 'Precio inválido.';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _stock,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Stock disponible',
                                  ),
                                  validator: (value) {
                                    final parsed = int.tryParse(
                                      (value ?? '').trim(),
                                    );
                                    if (parsed == null || parsed < 0) {
                                      return 'Cantidad inválida.';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          categories.when(
                            data: (items) {
                              final validId =
                                  items.any((item) => item.id == _categoryId)
                                  ? _categoryId
                                  : null;
                              return DropdownButtonFormField<String?>(
                                initialValue: validId,
                                decoration: const InputDecoration(
                                  labelText: 'Categoría',
                                ),
                                items: [
                                  const DropdownMenuItem<String?>(
                                    value: null,
                                    child: Text('Sin categoría'),
                                  ),
                                  for (final category in items)
                                    DropdownMenuItem<String?>(
                                      value: category.id,
                                      child: Text(category.name),
                                    ),
                                ],
                                onChanged: (value) =>
                                    setState(() => _categoryId = value),
                              );
                            },
                            loading: () => const LinearProgressIndicator(),
                            error: (error, stack) => const Text(
                              'No se pudieron cargar las categorías.',
                              style: TextStyle(color: AppColors.muted),
                            ),
                          ),
                          const SizedBox(height: 18),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            value: _isActive,
                            onChanged: (value) =>
                                setState(() => _isActive = value),
                            title: const Text(
                              'Publicar en el catálogo',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: const Text(
                              'Si lo desactivas, solo tú podrás verlo.',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _FieldLabel('Imagen del producto'),
                          const SizedBox(height: 6),
                          const Text(
                            'Sube una foto desde tu dispositivo o pega un '
                            'enlace público.',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 16),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final preview = AspectRatio(
                                aspectRatio: 4 / 3,
                                child: _previewBytes != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: Image.memory(
                                          _previewBytes!,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : ProductImage(
                                        url: _imageUrl.text.trim().isNotEmpty
                                            ? _imageUrl.text.trim()
                                            : _existingDataImage,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                              );
                              final controls = Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: _saving ? null : _pickImage,
                                    icon: const Icon(
                                      Icons.upload_rounded,
                                      size: 18,
                                    ),
                                    label: Text(
                                      _previewBytes == null
                                          ? 'Elegir imagen'
                                          : 'Cambiar imagen',
                                    ),
                                  ),
                                  if (_previewBytes != null) ...[
                                    const SizedBox(height: 8),
                                    TextButton(
                                      onPressed: () => setState(() {
                                        _selectedFile = null;
                                        _previewBytes = null;
                                      }),
                                      child: const Text('Quitar selección'),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _imageUrl,
                                    decoration: const InputDecoration(
                                      labelText: 'o URL de la imagen',
                                      hintText: 'https://...',
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ],
                              );
                              if (constraints.maxWidth < 560) {
                                return Column(
                                  children: [
                                    preview,
                                    const SizedBox(height: 16),
                                    controls,
                                  ],
                                );
                              }
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(width: 240, child: preview),
                                  const SizedBox(width: 20),
                                  Expanded(child: controls),
                                ],
                              );
                            },
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
                                  _editing
                                      ? 'Guardar cambios'
                                      : 'Publicar producto',
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

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
    );
  }
}
