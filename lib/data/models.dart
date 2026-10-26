class AppUser {
  const AppUser({required this.id, required this.email, this.fullName = ''});

  final String id;
  final String email;
  final String fullName;

  String get displayName => fullName.trim().isEmpty ? email : fullName;
}

class Category {
  const Category({required this.id, required this.name, required this.slug});

  final String id;
  final String name;
  final String slug;

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      slug: map['slug'] as String? ?? '',
    );
  }
}

class Store {
  const Store({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.slug,
    this.description = '',
    this.logoUrl,
    this.phone,
    this.city,
  });

  final String id;
  final String ownerId;
  final String name;
  final String slug;
  final String description;
  final String? logoUrl;
  final String? phone;
  final String? city;

  factory Store.fromMap(Map<String, dynamic> map) {
    return Store(
      id: map['id'] as String,
      ownerId: map['owner_id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      slug: map['slug'] as String? ?? '',
      description: map['description'] as String? ?? '',
      logoUrl: map['logo_url'] as String?,
      phone: map['phone'] as String?,
      city: map['city'] as String?,
    );
  }
}

class Product {
  const Product({
    required this.id,
    required this.storeId,
    required this.title,
    required this.price,
    this.description = '',
    this.stock = 0,
    this.imageUrl,
    this.categoryId,
    this.categoryName = '',
    this.storeName = '',
    this.storePhone,
    this.storeOwnerId,
    this.isActive = true,
    required this.createdAt,
  });

  final String id;
  final String storeId;
  final String title;
  final String description;
  final double price;
  final int stock;
  final String? imageUrl;
  final String? categoryId;
  final String categoryName;
  final String storeName;
  final String? storePhone;
  final String? storeOwnerId;
  final bool isActive;
  final DateTime createdAt;

  bool get isAvailable => isActive && stock > 0;

  factory Product.fromMap(Map<String, dynamic> map) {
    final store = _nested(map['stores']);
    final category = _nested(map['categories']);

    return Product(
      id: map['id'] as String,
      storeId: map['store_id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      price: _toDouble(map['price']),
      stock: _toInt(map['stock']),
      imageUrl: map['image_url'] as String?,
      categoryId: map['category_id'] as String?,
      categoryName: category?['name'] as String? ?? '',
      storeName: store?['name'] as String? ?? '',
      storePhone: store?['phone'] as String?,
      storeOwnerId: store?['owner_id'] as String?,
      isActive: map['is_active'] as bool? ?? true,
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Product copyWith({bool? isActive}) {
    return Product(
      id: id,
      storeId: storeId,
      title: title,
      description: description,
      price: price,
      stock: stock,
      imageUrl: imageUrl,
      categoryId: categoryId,
      categoryName: categoryName,
      storeName: storeName,
      storePhone: storePhone,
      storeOwnerId: storeOwnerId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }
}

class ProductDraft {
  const ProductDraft({
    required this.title,
    required this.description,
    required this.price,
    required this.stock,
    required this.isActive,
    this.imageUrl,
    this.categoryId,
  });

  final String title;
  final String description;
  final double price;
  final int stock;
  final bool isActive;
  final String? imageUrl;
  final String? categoryId;

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'price': price,
      'stock': stock,
      'is_active': isActive,
      'image_url': imageUrl,
      'category_id': categoryId,
    };
  }
}

class StoreDraft {
  const StoreDraft({
    required this.name,
    required this.slug,
    this.description = '',
    this.logoUrl,
    this.phone,
    this.city,
  });

  final String name;
  final String slug;
  final String description;
  final String? logoUrl;
  final String? phone;
  final String? city;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'slug': slug,
      'description': description,
      'logo_url': logoUrl,
      'phone': phone,
      'city': city,
    };
  }
}

class ProductQuery {
  const ProductQuery({this.text = '', this.categoryId});

  final String text;
  final String? categoryId;

  @override
  bool operator ==(Object other) {
    return other is ProductQuery &&
        other.text == text &&
        other.categoryId == categoryId;
  }

  @override
  int get hashCode => Object.hash(text, categoryId);
}

Map<String, dynamic>? _nested(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is List && value.isNotEmpty) {
    final first = value.first;
    if (first is Map<String, dynamic>) return first;
  }
  return null;
}

double _toDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _toInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
