/// Represents a single product row in the `products` table.
///
/// Kept as a plain immutable data class with `toMap` / `fromMap`
/// helpers so the database layer never has to know about Dart
/// objects directly and the UI never has to know about SQL.
class Product {
  final int? id;
  final String barcode;
  final String name;
  final double price;
  final String createdAt;

  const Product({
    this.id,
    required this.barcode,
    required this.name,
    required this.price,
    required this.createdAt,
  });

  /// Convert this object into a Map for sqflite insert/update.
  Map<String, dynamic> toMap() {
    return {
      // Only include id if it's set, so SQLite can autoincrement on insert.
      if (id != null) 'id': id,
      'barcode': barcode,
      'name': name,
      'price': price,
      'created_at': createdAt,
    };
  }

  /// Build a Product from a raw SQLite row.
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int?,
      barcode: map['barcode'] as String,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      createdAt: map['created_at'] as String,
    );
  }

  Product copyWith({
    int? id,
    String? barcode,
    String? name,
    double? price,
    String? createdAt,
  }) {
    return Product(
      id: id ?? this.id,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      price: price ?? this.price,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}