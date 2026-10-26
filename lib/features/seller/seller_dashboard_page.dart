import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';

class SellerDashboardPage extends ConsumerWidget {
  const SellerDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.storefront_rounded,
                      size: 44,
                      color: AppColors.accent,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Vende en Mercado',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Crea tu cuenta, abre tu tienda y publica tus productos '
                      'para que más personas los encuentren.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted, height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => context.go('/login'),
                        child: const Text('Ingresar'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => context.go('/register'),
                        child: const Text('Crear cuenta gratis'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final store = ref.watch(myStoreProvider);
    return AsyncView<Store?>(
      value: store,
      builder: (data) {
        if (data == null) return _OpenStoreGate(name: user.displayName);
        return _Dashboard(store: data);
      },
    );
  }
}

class _OpenStoreGate extends StatelessWidget {
  const _OpenStoreGate({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hola, $name',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Aún no tienes una tienda. Elige un nombre, agrega una '
                    'descripción y empieza a publicar tus productos.',
                    style: TextStyle(color: AppColors.muted, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  const _Benefit(
                    icon: Icons.bolt_rounded,
                    text: 'Publica productos en minutos, sin costo.',
                  ),
                  const _Benefit(
                    icon: Icons.public_rounded,
                    text: 'Tu tienda tendrá una página propia para compartir.',
                  ),
                  const _Benefit(
                    icon: Icons.chat_bubble_outline_rounded,
                    text: 'Los compradores te contactan directo por WhatsApp.',
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => context.go('/seller/store'),
                      child: const Text('Abrir mi tienda'),
                    ),
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

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.accentDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppColors.inkSoft, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dashboard extends ConsumerWidget {
  const _Dashboard({required this.store});

  final Store store;

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Product product,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar producto?'),
        content: Text(
          '"${product.title}" se quitará del catálogo de forma permanente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(repositoryProvider).deleteProduct(product.id);
      refreshCatalog(ref);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Producto eliminado.')));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('No se pudo eliminar: $error')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(myProductsProvider);

    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StoreHeader(store: store),
                const SizedBox(height: 20),
                products.when(
                  data: (items) => _Stats(products: items),
                  loading: () => const SizedBox(height: 108),
                  error: (error, stack) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 26),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Mis productos',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () => context.go('/seller/products/new'),
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: const Text('Nuevo producto'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AsyncView<List<Product>>(
                  value: products,
                  builder: (items) {
                    if (items.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: EmptyState(
                          icon: Icons.inventory_2_outlined,
                          title: 'Aún no publicas productos',
                          subtitle:
                              'Crea tu primer producto y empieza a vender.',
                          action: FilledButton.icon(
                            onPressed: () => context.go('/seller/products/new'),
                            icon: const Icon(Icons.add_rounded, size: 20),
                            label: const Text('Publicar producto'),
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: [
                        for (final product in items) ...[
                          _ProductRow(
                            product: product,
                            onEdit: () => context.go(
                              '/seller/products/${product.id}/edit',
                            ),
                            onDelete: () => _delete(context, ref, product),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StoreHeader extends StatelessWidget {
  const _StoreHeader({required this.store});

  final Store store;

  @override
  Widget build(BuildContext context) {
    final identity = Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: AppColors.accent,
          child: Text(
            initials(store.name),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mi tienda',
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
              Text(
                store.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Página pública · /store/${store.slug}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
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
          onPressed: () => context.go('/store/${store.id}'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white24),
          ),
          child: const Text('Ver tienda'),
        ),
        FilledButton(
          onPressed: () => context.go('/seller/store'),
          child: const Text('Editar'),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.ink, Color(0xFF26364D)],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 640) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [identity, const SizedBox(height: 16), actions],
            );
          }
          return Row(
            children: [
              Expanded(child: identity),
              const SizedBox(width: 12),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    final active = products.where((product) => product.isActive).length;
    final units = products.fold<int>(0, (sum, item) => sum + item.stock);
    final value = products.fold<double>(
      0,
      (sum, item) => sum + item.price * item.stock,
    );

    final tiles = [
      _StatTile(
        label: 'Productos',
        value: '${products.length}',
        icon: Icons.inventory_2_outlined,
      ),
      _StatTile(
        label: 'Activos',
        value: '$active',
        icon: Icons.visibility_outlined,
      ),
      _StatTile(
        label: 'Unidades en stock',
        value: '$units',
        icon: Icons.layers_outlined,
      ),
      _StatTile(
        label: 'Valor del inventario',
        value: formatPrice(value),
        icon: Icons.savings_outlined,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 520
            ? 2
            : 1;
        final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final tile in tiles) SizedBox(width: width, child: tile),
          ],
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: AppColors.inkSoft),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: ProductImage(
                url: product.imageUrl,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        formatPrice(product.price),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '· ${product.stock} en stock',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                      _StatusChip(product: product),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Editar',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 20),
            ),
            IconButton(
              tooltip: 'Eliminar',
              onPressed: onDelete,
              icon: const Icon(
                Icons.delete_outline_rounded,
                size: 20,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final (label, color, background) = !product.isActive
        ? ('Oculto', const Color(0xFF475569), AppColors.canvas)
        : product.stock == 0
        ? ('Agotado', AppColors.warning, AppColors.warningSoft)
        : ('Publicado', AppColors.success, AppColors.successSoft);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
