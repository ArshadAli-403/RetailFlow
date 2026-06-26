import 'package:sqflite/sqflite.dart';
import '../models/product_model.dart';
import 'database_helper.dart';

/// Thin data-access layer over the `products` table.
///
/// All exceptions are allowed to propagate to the caller (the
/// ProductProvider) which is responsible for catching them and
/// turning them into user-facing messages. This keeps the DAO
/// focused purely on SQL.
class ProductDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> insertProduct(Product product) async {
    final db = await _dbHelper.database;
    return db.insert(
      'products',
      product.toMap(),
      // Using abort (the default) lets the UNIQUE constraint on
      // barcode raise a DatabaseException we can catch upstream
      // instead of silently overwriting an existing product.
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<int> updateProduct(Product product) async {
    final db = await _dbHelper.database;
    return db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await _dbHelper.database;
    return db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Product>> getAllProducts() async {
    final db = await _dbHelper.database;
    final result = await db.query('products', orderBy: 'name ASC');
    return result.map((row) => Product.fromMap(row)).toList();
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'products',
      where: 'barcode = ?',
      whereArgs: [barcode],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return Product.fromMap(result.first);
  }

  Future<Product?> getProductById(int id) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return Product.fromMap(result.first);
  }

  /// Checks if a barcode is already used by a DIFFERENT product than
  /// [excludeId]. Useful when editing a product so it doesn't flag
  /// itself as a duplicate.
  Future<bool> barcodeExists(String barcode, {int? excludeId}) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'products',
      where: excludeId != null ? 'barcode = ? AND id != ?' : 'barcode = ?',
      whereArgs: excludeId != null ? [barcode, excludeId] : [barcode],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  Future<List<Product>> searchProducts(String query) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'products',
      where: 'name LIKE ? OR barcode LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'name ASC',
    );
    return result.map((row) => Product.fromMap(row)).toList();
  }
}