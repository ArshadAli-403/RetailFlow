import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../database/product_dao.dart';
import '../models/product_model.dart';

/// Holds the in-memory list of products and mediates every product
/// CRUD operation between the UI and [ProductDao].
///
/// Screens never talk to the database directly — they call methods
/// on this provider and listen via [ChangeNotifier] for updates.
class ProductProvider extends ChangeNotifier {
  final ProductDao _productDao = ProductDao();

  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  List<Product> get products =>
      _searchQuery.isEmpty ? _products : _filteredProducts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadProducts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _products = await _productDao.getAllProducts();
      if (_searchQuery.isNotEmpty) {
        _applySearchFilter();
      }
    } catch (e) {
      _errorMessage = 'Failed to load products: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void search(String query) {
    _searchQuery = query.trim();
    _applySearchFilter();
    notifyListeners();
  }

  void _applySearchFilter() {
    if (_searchQuery.isEmpty) {
      _filteredProducts = [];
      return;
    }
    final lowerQuery = _searchQuery.toLowerCase();
    _filteredProducts = _products
        .where((p) =>
            p.name.toLowerCase().contains(lowerQuery) ||
            p.barcode.toLowerCase().contains(lowerQuery))
        .toList();
  }

  /// Returns null on success, or a human-readable error string on failure.
  /// Returning a string (rather than throwing) keeps the calling screen's
  /// code simple: `final error = await provider.addProduct(...); if (error != null) ...`
  Future<String?> addProduct({
    required String barcode,
    required String name,
    required double price,
  }) async {
    try {
      final exists = await _productDao.barcodeExists(barcode);
      if (exists) {
        return 'A product with this barcode already exists.';
      }

      final product = Product(
        barcode: barcode,
        name: name,
        price: price,
        createdAt: DateTime.now().toIso8601String(),
      );

      await _productDao.insertProduct(product);
      await loadProducts();
      return null;
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        return 'A product with this barcode already exists.';
      }
      return 'Database error: ${e.toString()}';
    } catch (e) {
      return 'Failed to save product: ${e.toString()}';
    }
  }

  Future<String?> updateProduct({
    required int id,
    required String barcode,
    required String name,
    required double price,
    required String createdAt,
  }) async {
    try {
      final exists = await _productDao.barcodeExists(barcode, excludeId: id);
      if (exists) {
        return 'Another product already uses this barcode.';
      }

      final product = Product(
        id: id,
        barcode: barcode,
        name: name,
        price: price,
        createdAt: createdAt,
      );

      await _productDao.updateProduct(product);
      await loadProducts();
      return null;
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        return 'Another product already uses this barcode.';
      }
      return 'Database error: ${e.toString()}';
    } catch (e) {
      return 'Failed to update product: ${e.toString()}';
    }
  }

  Future<String?> deleteProduct(int id) async {
    try {
      await _productDao.deleteProduct(id);
      await loadProducts();
      return null;
    } catch (e) {
      return 'Failed to delete product: ${e.toString()}';
    }
  }

  Future<Product?> findByBarcode(String barcode) async {
    try {
      return await _productDao.getProductByBarcode(barcode);
    } catch (e) {
      _errorMessage = 'Lookup failed: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }
}