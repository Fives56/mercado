import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';
import '../../widgets/product_card.dart';

class StorePage extends ConsumerWidget {
  const StorePage({super.key, required this.storeId});

  final String storeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(storeProvider(storeId));
    final products = ref.watch(storeProductsProvider(storeId));
    final user = ref.watch(currentUserProvider);

    return AsyncView(
      value: store,
      builder: (data) {
        if (data == null) {
          return const EmptyState(
            icon: Icons.storefront_outlined,
            title: 'Tienda no encontrada',
            subtitle: 'Puede que ya no esté disponible.',
          );
        }
        final isOwner = user?.id == data.ownerId;

        return SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
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
                      label: const Text('Volver'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.muted,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 34,
                                  backgroundColor: AppColors.ink,
                                  backgroundImage:
                                      (data.logoUrl ?? '').isNotEmpty
                                      ? NetworkImage(data.logoUrl!)
                                      : null,
                                  child: (data.logoUrl ?? '').isEmpty
                                      ? Text(
                                          initials(data.name),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: -0.6,
                                            ),
                                      ),
                                      if ((data.city ?? '').isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.location_on_outlined,
                                              size: 16,
                                              color: AppColors.muted,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              data.city!,
                                              style: const TextStyle(
                                                color: AppColors.muted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (isOwner)
                                  OutlinedButton.icon(
                                    onPressed: () =>
                                        context.go('/seller/store'),
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 18,
                                    ),
                                    label: const Text('Editar tienda'),
                                  ),
                              ],
                            ),
                            if (data.description.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Text(
                                data.description,
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  height: 1.6,
                                ),
                              ),
                            ],
                            if ((data.phone ?? '').isNotEmpty) ...[
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                onPressed: () => _contact(context, data.phone!),
                                icon: const Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 18,
                                ),
                                label: const Text('Contactar vendedor'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    SectionTitle(
                      title: 'Productos de ${data.name}',
                      subtitle: 'Todo lo que este vendedor tiene para ti',
                    ),
                    const SizedBox(height: 18),
                    AsyncView(
                      value: products,
                      builder: (items) {
                        if (items.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: EmptyState(
                              icon: Icons.inventory_2_outlined,
                              title: 'Esta tienda aún no tiene productos',
                              subtitle: 'Vuelve pronto para ver novedades.',
                            ),
                          );
                        }
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: items.length,
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 280,
                                mainAxisExtent: 350,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                          itemBuilder: (context, index) =>
                              ProductCard(product: items[index]),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _contact(BuildContext context, String phone) async {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este vendedor no tiene teléfono.')),
      );
      return;
    }
    final uri = Uri.parse('https://wa.me/$digits');
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir WhatsApp.')),
      );
    }
  }
}
