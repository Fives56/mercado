import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'marketplace_repository.dart';
import 'models.dart';

class SupabaseMarketplaceRepository implements MarketplaceRepository {
  SupabaseMarketplaceRepository(this._client);

  final sb.SupabaseClient _client;

  static const _productSelect =
      '*, stores(id,name,phone,owner_id), '
      'categories(id,name)';

  @override
  bool get isDemo => false;

  @override
  AppUser? get currentUser => _mapUser(_client.auth.currentUser);

  @override
  Stream<AppUser?> authStateChanges() async* {
    yield currentUser;
    yield* _client.auth.onAuthStateChange.map(
      (event) => _mapUser(event.session?.user),
    );
  }

  AppUser? _mapUser(sb.User? user) {
    if (user == null) return null;
    return AppUser(
      id: user.id,
      email: user.email ?? '',
      fullName: user.userMetadata?['full_name'] as String? ?? '',
    );
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    final user = _mapUser(response.user);
    if (user == null) throw Exception('No se pudo iniciar sesión.');
    return user;
  }

  @override
  Future<AppUser?> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'full_name': fullName.trim()},
    );
    if (response.session == null) return null;
    return _mapUser(response.user);
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  @override
  Future<List<Category>> fetchCategories() async {
    final data = await _client
        .from('categories')
        .select('id,name,slug')
        .order('name');
    return data.map(Category.fromMap).toList();
  }

  @override
  Future<List<Product>> fetchProducts(ProductQuery query) async {
    var request = _client
        .from('products')
        .select(_productSelect)
        .eq('is_active', true);

    if (query.categoryId != null) {
      request = request.eq('category_id', query.categoryId!);
    }

    final text = _sanitize(query.text.trim());
    if (text.isNotEmpty) {
      final stores = await _client
          .from('stores')
          .select('id')
          .ilike('name', '%$text%');
      final ids = stores.map((store) => store['id']).toList();
      final clauses = [
        'title.ilike.%$text%',
        'description.ilike.%$text%',
        if (ids.isNotEmpty) 'store_id.in.(${ids.join(',')})',
      ];
      request = request.or(clauses.join(','));
    }

    final data = await request.order('created_at', ascending: false);
    return (data as List).map((row) {
      return Product.fromMap(Map<String, dynamic>.from(row as Map));
    }).toList();
  }

  String _sanitize(String value) {
    return value.replaceAll(RegExp(r'[,()%]'), ' ').trim();
  }

  @override
  Future<Product?> fetchProduct(String id) async {
    final data = await _client
        .from('products')
        .select(_productSelect)
        .eq('id', id)
        .maybeSingle();
    if (data == null) return null;
    return Product.fromMap(data);
  }

  @override
  Future<Store?> fetchStore(String id) async {
    final data = await _client
        .from('stores')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (data == null) return null;
    return Store.fromMap(data);
  }

  @override
  Future<List<Product>> fetchStoreProducts(String storeId) async {
    final data = await _client
        .from('products')
        .select(_productSelect)
        .eq('store_id', storeId)
        .eq('is_active', true)
        .order('created_at', ascending: false);
    return data.map(Product.fromMap).toList();
  }

  @override
  Future<Store?> fetchMyStore() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    final data = await _client
        .from('stores')
        .select()
        .eq('owner_id', user.id)
        .maybeSingle();
    if (data == null) return null;
    return Store.fromMap(data);
  }

  @override
  Future<Store> saveStore(StoreDraft draft) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Inicia sesión para continuar.');

    final data = await _client
        .from('stores')
        .upsert({...draft.toMap(), 'owner_id': user.id}, onConflict: 'owner_id')
        .select()
        .single();
    return Store.fromMap(data);
  }

  @override
  Future<List<Product>> fetchMyProducts() async {
    final store = await fetchMyStore();
    if (store == null) return [];
    final data = await _client
        .from('products')
        .select(_productSelect)
        .eq('store_id', store.id)
        .order('created_at', ascending: false);
    return data.map(Product.fromMap).toList();
  }

  @override
  Future<Product> saveProduct(ProductDraft draft, {String? id}) async {
    final store = await fetchMyStore();
    if (store == null) throw Exception('Primero crea tu tienda.');

    final values = {...draft.toMap(), 'store_id': store.id};

    late final Map<String, dynamic> data;
    if (id == null) {
      data = await _client
          .from('products')
          .insert(values)
          .select(_productSelect)
          .single();
    } else {
      data = await _client
          .from('products')
          .update(values)
          .eq('id', id)
          .select(_productSelect)
          .single();
    }
    return Product.fromMap(data);
  }

  @override
  Future<void> deleteProduct(String id) async {
    await _client.from('products').delete().eq('id', id);
  }

  @override
  Future<String?> uploadProductImage(XFile file) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Inicia sesión para continuar.');

    final bytes = await file.readAsBytes();
    final extension = _safeName(file.name);
    final path =
        '${user.id}/${DateTime.now().millisecondsSinceEpoch}_$extension';

    await _client.storage
        .from('product-images')
        .uploadBinary(
          path,
          bytes,
          fileOptions: sb.FileOptions(
            contentType: resolveImageMimeType(file),
            cacheControl: '3600',
          ),
        );
    return _client.storage.from('product-images').getPublicUrl(path);
  }

  String _safeName(String name) {
    return name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  }
}
