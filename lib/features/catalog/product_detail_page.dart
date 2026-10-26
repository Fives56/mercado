import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';

class ProductDetailPage extends ConsumerWidget {
  const ProductDetailPage({super.key, required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final product = ref.watch(productProvider(productId));

    return AsyncView<Product?>(
      value: product,
      builder: (item) {
        if (item == null) {
          return const EmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'Producto no encontrado',
            subtitle: 'Puede que ya no esté disponible.',
          );
        }
        return _ProductDetail(product: item);
      },
    );
  }
}

class _ProductDetail extends ConsumerWidget {
  const _ProductDetail({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 940;
    final user = ref.watch(currentUserProvider);
    final isOwner = user != null && user.id == product.storeOwnerId;

    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextButton.icon(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/');
                    }
                  },
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('Volver al catálogo'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.muted,
                    padding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 460,
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: ProductImage(
                                    url: product.imageUrl,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 32),
                              Expanded(
                                child: _Info(
                                  product: product,
                                  isOwner: isOwner,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AspectRatio(
                                aspectRatio: 1.15,
                                child: ProductImage(
                                  url: product.imageUrl,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              const SizedBox(height: 22),
                              _Info(product: product, isOwner: isOwner),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                _SellerCard(product: product),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.product, required this.isOwner});

  final Product product;
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    final available = product.isActive && product.stock > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (product.categoryName.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.line),
                ),
                child: Text(
                  product.categoryName,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                  ),
                ),
              ),
            const Spacer(),
            if (isOwner)
              TextButton.icon(
                onPressed: () =>
                    context.go('/seller/products/${product.id}/edit'),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Editar'),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          product.title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          formatPrice(product.price),
          style: const TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.2,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              available
                  ? Icons.check_circle_rounded
                  : Icons.remove_circle_outline_rounded,
              size: 16,
              color: available ? AppColors.success : AppColors.muted,
            ),
            const SizedBox(width: 6),
            Text(
              available
                  ? 'Disponible · ${product.stock} en stock'
                  : 'No disponible por ahora',
              style: TextStyle(
                color: available ? AppColors.success : AppColors.muted,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        const Divider(),
        const SizedBox(height: 20),
        const Text(
          'Descripción',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        const SizedBox(height: 8),
        Text(
          product.description.isEmpty
              ? 'El vendedor no agregó una descripción.'
              : product.description,
          style: const TextStyle(
            color: AppColors.muted,
            height: 1.6,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 26),
        if (isOwner)
          const InlineAlert(
            tone: AlertTone.info,
            message:
                'Estás viendo tu propio producto. Puedes editarlo desde '
                'aquí o desde tu panel.',
          ),
      ],
    );
  }
}

class _SellerCard extends StatelessWidget {
  const _SellerCard({required this.product});

  final Product product;

  Future<void> _contact(BuildContext context) async {
    final raw = product.storePhone ?? '';
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    final message = Uri.encodeComponent(
      'Hola, me interesa "${product.title}" que vi en Mercado.',
    );
    final uri = digits.isEmpty
        ? null
        : Uri.parse('https://wa.me/$digits?text=$message');
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este vendedor no tiene teléfono.')),
      );
      return;
    }
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir WhatsApp.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 620;
    final identity = Row(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: AppColors.ink,
          child: Text(
            initials(
              product.storeName.isEmpty ? 'Vendedor' : product.storeName,
            ),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Vendido por',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              Text(
                product.storeName.isEmpty ? 'Vendedor' : product.storeName,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final actions = Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        OutlinedButton(
          onPressed: () => context.go('/store/${product.storeId}'),
          child: const Text('Ver tienda'),
        ),
        FilledButton.icon(
          onPressed: () => _contact(context),
          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
          label: const Text('Contactar'),
        ),
      ],
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: narrow
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [identity, const SizedBox(height: 16), actions],
              )
            : Row(
                children: [
                  Expanded(child: identity),
                  const SizedBox(width: 12),
                  actions,
                ],
              ),
      ),
    );
  }
}
