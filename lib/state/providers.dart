import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config.dart';
import '../data/demo_marketplace_repository.dart';
import '../data/marketplace_repository.dart';
import '../data/models.dart';
import '../data/supabase_marketplace_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final repositoryProvider = Provider<MarketplaceRepository>((ref) {
  if (AppConfig.hasSupabase) {
    return SupabaseMarketplaceRepository(Supabase.instance.client);
  }
  return DemoMarketplaceRepository();
});

final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(repositoryProvider).authStateChanges();
});

final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authStateProvider).value;
});

final categoriesProvider = FutureProvider<List<Category>>((ref) {
  return ref.watch(repositoryProvider).fetchCategories();
});

final productsProvider = FutureProvider.family<List<Product>, ProductQuery>((
  ref,
  query,
) {
  return ref.watch(repositoryProvider).fetchProducts(query);
});

final productProvider = FutureProvider.family<Product?, String>((ref, id) {
  return ref.watch(repositoryProvider).fetchProduct(id);
});

final storeProvider = FutureProvider.family<Store?, String>((ref, id) {
  return ref.watch(repositoryProvider).fetchStore(id);
});

final storeProductsProvider = FutureProvider.family<List<Product>, String>((
  ref,
  storeId,
) {
  return ref.watch(repositoryProvider).fetchStoreProducts(storeId);
});

final myStoreProvider = FutureProvider<Store?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return null;
  return ref.watch(repositoryProvider).fetchMyStore();
});

final myProductsProvider = FutureProvider<List<Product>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return const [];
  return ref.watch(repositoryProvider).fetchMyProducts();
});

class CatalogFilters {
  const CatalogFilters({this.text = '', this.categoryId});

  final String text;
  final String? categoryId;
}

class CatalogFiltersNotifier extends Notifier<CatalogFilters> {
  @override
  CatalogFilters build() => const CatalogFilters();

  void setText(String text) {
    state = CatalogFilters(text: text, categoryId: state.categoryId);
  }

  void setCategory(String? categoryId) {
    state = CatalogFilters(text: state.text, categoryId: categoryId);
  }

  void clear() {
    state = const CatalogFilters();
  }
}

final catalogFiltersProvider =
    NotifierProvider<CatalogFiltersNotifier, CatalogFilters>(
      CatalogFiltersNotifier.new,
    );

void refreshCatalog(WidgetRef ref) {
  ref.invalidate(categoriesProvider);
  ref.invalidate(productsProvider);
  ref.invalidate(productProvider);
  ref.invalidate(storeProvider);
  ref.invalidate(storeProductsProvider);
  ref.invalidate(myProductsProvider);
  ref.invalidate(myStoreProvider);
}
