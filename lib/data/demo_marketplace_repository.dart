import 'dart:async';
import 'dart:convert';

import 'package:image_picker/image_picker.dart';

import 'marketplace_repository.dart';
import 'models.dart';

/// Repositorio en memoria para desarrollar la UI sin configurar Supabase.
class DemoMarketplaceRepository implements MarketplaceRepository {
  DemoMarketplaceRepository() {
    _seed();
  }

  final _authController = StreamController<AppUser?>.broadcast();
  final List<Product> _products = [];

  AppUser? _user;
  Store? _myStore;
  int _idCounter = 100;

  static const _categories = [
    Category(id: 'cat-tech', name: 'Tecnología', slug: 'tecnologia'),
    Category(id: 'cat-moda', name: 'Moda', slug: 'moda'),
    Category(id: 'cat-hogar', name: 'Hogar', slug: 'hogar'),
    Category(id: 'cat-belleza', name: 'Belleza', slug: 'belleza'),
    Category(id: 'cat-deportes', name: 'Deportes', slug: 'deportes'),
    Category(id: 'cat-libros', name: 'Libros', slug: 'libros'),
  ];

  static const _stores = [
    Store(
      id: 'store-tech',
      ownerId: 'vendor-tech',
      name: 'NovaTech',
      slug: 'novatech',
      description: 'Tecnología y accesorios para tu día a día.',
      phone: '+1 555 0100',
      city: 'Ciudad de México',
    ),
    Store(
      id: 'store-home',
      ownerId: 'vendor-home',
      name: 'Casa Bonita',
      slug: 'casa-bonita',
      description: 'Detalles que hacen de tu casa un hogar.',
      phone: '+1 555 0200',
      city: 'Bogotá',
    ),
    Store(
      id: 'store-fit',
      ownerId: 'vendor-fit',
      name: 'Mueve Fit',
      slug: 'mueve-fit',
      description: 'Equipo y ropa para entrenar sin excusas.',
      phone: '+1 555 0300',
      city: 'Buenos Aires',
    ),
  ];

  @override
  bool get isDemo => true;

  @override
  AppUser? get currentUser => _user;

  @override
  Stream<AppUser?> authStateChanges() async* {
    yield _user;
    yield* _authController.stream;
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    if (email.trim().isEmpty || password.isEmpty) {
      throw Exception('Escribe tu correo y contraseña.');
    }
    final user = AppUser(
      id: 'demo-user',
      email: email.trim(),
      fullName: 'Vendedor Demo',
    );
    _setUser(user);
    return user;
  }

  @override
  Future<AppUser?> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    if (fullName.trim().isEmpty || email.trim().isEmpty || password.isEmpty) {
      throw Exception('Completa todos los campos.');
    }
    final user = AppUser(
      id: 'demo-user',
      email: email.trim(),
      fullName: fullName.trim(),
    );
    _setUser(user);
    return user;
  }

  @override
  Future<void> signOut() async => _setUser(null);

  void _setUser(AppUser? user) {
    _user = user;
    _authController.add(user);
  }

  @override
  Future<List<Category>> fetchCategories() async => _categories;

  @override
  Future<List<Product>> fetchProducts(ProductQuery query) async {
    final text = query.text.trim().toLowerCase();
    final result = _products.where((product) {
      if (!product.isActive) return false;
      if (query.categoryId != null && product.categoryId != query.categoryId) {
        return false;
      }
      if (text.isEmpty) return true;
      return product.title.toLowerCase().contains(text) ||
          product.description.toLowerCase().contains(text) ||
          product.storeName.toLowerCase().contains(text);
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  @override
  Future<Product?> fetchProduct(String id) async {
    for (final product in _products) {
      if (product.id == id) return product;
    }
    return null;
  }

  @override
  Future<Store?> fetchStore(String id) async {
    for (final store in _stores) {
      if (store.id == id) return store;
    }
    if (_myStore?.id == id) return _myStore;
    return null;
  }

  @override
  Future<List<Product>> fetchStoreProducts(String storeId) async {
    return _products
        .where((product) => product.storeId == storeId && product.isActive)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<Store?> fetchMyStore() async => _myStore;

  @override
  Future<Store> saveStore(StoreDraft draft) async {
    _requireUser();
    final store = Store(
      id: _myStore?.id ?? 'my-store',
      ownerId: _user!.id,
      name: draft.name,
      slug: draft.slug,
      description: draft.description,
      logoUrl: draft.logoUrl,
      phone: draft.phone,
      city: draft.city,
    );
    _myStore = store;
    for (var i = 0; i < _products.length; i++) {
      if (_products[i].storeId == store.id) {
        _products[i] = _productWithStore(_products[i], store);
      }
    }
    return store;
  }

  @override
  Future<List<Product>> fetchMyProducts() async {
    if (_myStore == null) return [];
    return _products
        .where((product) => product.storeId == _myStore!.id)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<Product> saveProduct(ProductDraft draft, {String? id}) async {
    _requireUser();
    final store = _myStore;
    if (store == null) {
      throw Exception('Primero crea tu tienda.');
    }

    Product? existing;
    if (id != null) {
      for (final product in _products) {
        if (product.id == id) {
          existing = product;
          break;
        }
      }
    }
    if (existing != null && existing.storeId != store.id) {
      throw Exception('No puedes editar este producto.');
    }

    final product = Product(
      id: existing?.id ?? 'p-${_idCounter++}',
      storeId: store.id,
      title: draft.title,
      description: draft.description,
      price: draft.price,
      stock: draft.stock,
      imageUrl: draft.imageUrl,
      categoryId: draft.categoryId,
      categoryName: _categoryName(draft.categoryId),
      storeName: store.name,
      storePhone: store.phone,
      storeOwnerId: store.ownerId,
      isActive: draft.isActive,
      createdAt: existing?.createdAt ?? DateTime.now(),
    );

    _products.removeWhere((item) => item.id == product.id);
    _products.add(product);
    return product;
  }

  @override
  Future<void> deleteProduct(String id) async {
    _requireUser();
    _products.removeWhere(
      (product) => product.id == id && product.storeId == _myStore?.id,
    );
  }

  @override
  Future<String?> uploadProductImage(XFile file) async {
    final bytes = await file.readAsBytes();
    final mime = resolveImageMimeType(file);
    return 'data:$mime;base64,${base64Encode(bytes)}';
  }

  void _requireUser() {
    if (_user == null) {
      throw Exception('Inicia sesión para continuar.');
    }
  }

  String _categoryName(String? categoryId) {
    for (final category in _categories) {
      if (category.id == categoryId) return category.name;
    }
    return '';
  }

  Product _productWithStore(Product product, Store store) {
    return Product(
      id: product.id,
      storeId: product.storeId,
      title: product.title,
      description: product.description,
      price: product.price,
      stock: product.stock,
      imageUrl: product.imageUrl,
      categoryId: product.categoryId,
      categoryName: product.categoryName,
      storeName: store.name,
      storePhone: store.phone,
      storeOwnerId: store.ownerId,
      isActive: product.isActive,
      createdAt: product.createdAt,
    );
  }

  void _seed() {
    final now = DateTime.now();
    void add({
      required String id,
      required Store store,
      required String title,
      required String description,
      required double price,
      required int stock,
      required String image,
      required String categoryId,
      required int daysAgo,
    }) {
      _products.add(
        Product(
          id: id,
          storeId: store.id,
          title: title,
          description: description,
          price: price,
          stock: stock,
          imageUrl: image,
          categoryId: categoryId,
          categoryName: _categoryName(categoryId),
          storeName: store.name,
          storePhone: store.phone,
          storeOwnerId: store.ownerId,
          createdAt: now.subtract(Duration(days: daysAgo)),
        ),
      );
    }

    add(
      id: 'p-1',
      store: _stores[0],
      title: 'Audífonos inalámbricos Pro',
      description:
          'Cancelación de ruido activa, 30 horas de batería y estuche de carga rápida. Ideales para trabajo y viajes.',
      price: 89.99,
      stock: 14,
      image: 'https://picsum.photos/seed/headphones/900/900',
      categoryId: 'cat-tech',
      daysAgo: 1,
    );
    add(
      id: 'p-2',
      store: _stores[0],
      title: 'Teclado mecánico compacto',
      description:
          'Switches táctiles, retroiluminación RGB y conexión USB-C. Formato 75% para escritorios pequeños.',
      price: 64.50,
      stock: 8,
      image: 'https://picsum.photos/seed/keyboard/900/900',
      categoryId: 'cat-tech',
      daysAgo: 2,
    );
    add(
      id: 'p-3',
      store: _stores[1],
      title: 'Juego de tazas de cerámica',
      description:
          'Set de 4 tazas artesanales, aptas para microondas y lavavajillas. Acabado mate en tonos tierra.',
      price: 32.00,
      stock: 20,
      image: 'https://picsum.photos/seed/mugs/900/900',
      categoryId: 'cat-hogar',
      daysAgo: 3,
    );
    add(
      id: 'p-4',
      store: _stores[1],
      title: 'Lámpara de mesa nórdica',
      description:
          'Luz cálida regulable, base de madera y pantalla de lino. Perfecta para rincones de lectura.',
      price: 48.90,
      stock: 6,
      image: 'https://picsum.photos/seed/lamp/900/900',
      categoryId: 'cat-hogar',
      daysAgo: 4,
    );
    add(
      id: 'p-5',
      store: _stores[2],
      title: 'Mat de yoga antideslizante',
      description:
          '6 mm de grosor, superficie antideslizante y correa de transporte incluida. Material libre de látex.',
      price: 39.90,
      stock: 18,
      image: 'https://picsum.photos/seed/yoga/900/900',
      categoryId: 'cat-deportes',
      daysAgo: 5,
    );
    add(
      id: 'p-6',
      store: _stores[2],
      title: 'Mancuernas ajustables 2x10 kg',
      description:
          'Par de mancuernas con discos intercambiables y base de almacenamiento. Ahorra espacio en casa.',
      price: 120.00,
      stock: 4,
      image: 'https://picsum.photos/seed/dumbbells/900/900',
      categoryId: 'cat-deportes',
      daysAgo: 6,
    );
    add(
      id: 'p-7',
      store: _stores[0],
      title: 'Reloj inteligente Serie 5',
      description:
          'Monitor de actividad, oxígeno en sangre y notificaciones. Resistente al agua hasta 50 m.',
      price: 149.00,
      stock: 10,
      image: 'https://picsum.photos/seed/watch/900/900',
      categoryId: 'cat-tech',
      daysAgo: 7,
    );
    add(
      id: 'p-8',
      store: _stores[1],
      title: 'Mochila de lona urbana',
      description:
          'Compartimento acolchado para laptop de 15", bolsillos laterales y costuras reforzadas.',
      price: 42.00,
      stock: 12,
      image: 'https://picsum.photos/seed/backpack/900/900',
      categoryId: 'cat-moda',
      daysAgo: 8,
    );
  }
}
