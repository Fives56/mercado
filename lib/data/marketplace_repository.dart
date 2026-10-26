import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

import 'models.dart';

String resolveImageMimeType(XFile file) =>
    file.mimeType ?? lookupMimeType(file.name) ?? 'image/jpeg';

abstract class MarketplaceRepository {
  bool get isDemo;

  Stream<AppUser?> authStateChanges();

  AppUser? get currentUser;

  Future<AppUser> signIn({required String email, required String password});

  Future<AppUser?> signUp({
    required String fullName,
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<List<Category>> fetchCategories();

  Future<List<Product>> fetchProducts(ProductQuery query);

  Future<Product?> fetchProduct(String id);

  Future<Store?> fetchStore(String id);

  Future<List<Product>> fetchStoreProducts(String storeId);

  Future<Store?> fetchMyStore();

  Future<Store> saveStore(StoreDraft draft);

  Future<List<Product>> fetchMyProducts();

  Future<Product> saveProduct(ProductDraft draft, {String? id});

  Future<void> deleteProduct(String id);

  Future<String?> uploadProductImage(XFile file);
}
