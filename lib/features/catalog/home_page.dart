import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';
import '../../widgets/product_card.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(catalogFiltersProvider.notifier).setText(value);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(catalogFiltersProvider.notifier).setText('');
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(catalogFiltersProvider);
    final query = ProductQuery(
      text: filters.text,
      categoryId: filters.categoryId,
    );
    final products = ref.watch(productsProvider(query));
    final categories = ref.watch(categoriesProvider);
    final repository = ref.watch(repositoryProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(productsProvider(query));
        await ref.read(productsProvider(query).future);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Hero(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    onSubmitted: (value) {
                      _debounce?.cancel();
                      ref.read(catalogFiltersProvider.notifier).setText(value);
                    },
                    onClear: _clearSearch,
                    isDemo: repository.isDemo,
                  ),
                  const SizedBox(height: 28),
                  categories.when(
                    data: (items) => _CategoryBar(
                      categories: items,
                      selectedId: filters.categoryId,
                      onSelected: (id) => ref
                          .read(catalogFiltersProvider.notifier)
                          .setCategory(id),
                    ),
                    loading: () => const SizedBox(height: 36),
                    error: (error, stack) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 28),
                  SectionTitle(
                    title: filters.text.isNotEmpty || filters.categoryId != null
                        ? 'Resultados'
                        : 'Recién publicados',
                    subtitle: filters.text.isNotEmpty
                        ? 'Productos que coinciden con "${filters.text}"'
                        : 'Descubre lo que venden otras personas',
                  ),
                  const SizedBox(height: 18),
                  AsyncView<List<Product>>(
                    value: products,
                    loading: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 80),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    builder: (items) {
                      if (items.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 48),
                          child: EmptyState(
                            icon: Icons.search_off_rounded,
                            title: 'No encontramos productos',
                            subtitle:
                                'Prueba con otra palabra o cambia de categoría.',
                            action: OutlinedButton(
                              onPressed: () {
                                _clearSearch();
                                ref
                                    .read(catalogFiltersProvider.notifier)
                                    .setCategory(null);
                              },
                              child: const Text('Limpiar filtros'),
                            ),
                          ),
                        );
                      }
                      return _ProductGrid(products: items);
                    },
                  ),
                  const SizedBox(height: 48),
                  const _Footer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
    required this.isDemo,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;
  final bool isDemo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.ink, Color(0xFF243449)],
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -70,
            top: -90,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: 0.22),
              ),
            ),
          ),
          Positioned(
            right: 90,
            bottom: -110,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isDemo)
                    Container(
                      margin: const EdgeInsets.only(bottom: 18),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                      ),
                      child: const Text(
                        'Modo demo · conecta Supabase para publicar de verdad',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  Text(
                    'Compra a personas,\nvende lo que sabes hacer.',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      height: 1.08,
                      letterSpacing: -1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Un mercado abierto donde cada vendedor tiene su propia '
                    'vitrina. Publica tus productos y llega a más personas.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 52,
                    child: TextField(
                      controller: controller,
                      onChanged: onChanged,
                      onSubmitted: onSubmitted,
                      textInputAction: TextInputAction.search,
                      style: const TextStyle(fontSize: 15),
                      decoration: InputDecoration(
                        hintText: '¿Qué estás buscando?',
                        hintStyle: const TextStyle(color: AppColors.muted),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppColors.muted,
                        ),
                        suffixIcon: ValueListenableBuilder<TextEditingValue>(
                          valueListenable: controller,
                          builder: (context, value, child) {
                            if (value.text.isEmpty) return const SizedBox();
                            return IconButton(
                              onPressed: onClear,
                              icon: const Icon(Icons.close_rounded),
                            );
                          },
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: AppColors.accent,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: () => context.go('/seller'),
                    icon: const Icon(Icons.add_business_rounded, size: 20),
                    label: const Text('Quiero vender'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  final List<Category> categories;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length + 1,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return ChoiceChip(
              label: const Text('Todas'),
              selected: selectedId == null,
              onSelected: (_) => onSelected(null),
              showCheckmark: false,
            );
          }
          final category = categories[index - 1];
          return ChoiceChip(
            label: Text(category.name),
            selected: selectedId == category.id,
            onSelected: (selected) => onSelected(selected ? category.id : null),
            showCheckmark: false,
          );
        },
      ),
    );
  }
}

class _ProductGrid extends StatelessWidget {
  const _ProductGrid({required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 280,
        mainAxisExtent: 350,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemBuilder: (context, index) => ProductCard(product: products[index]),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 20),
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.local_mall_rounded,
                color: Colors.white,
                size: 17,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Mercado',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            Text(
              'Hecho con Flutter y Supabase',
              style: TextStyle(
                color: AppColors.muted.withValues(alpha: 0.9),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
