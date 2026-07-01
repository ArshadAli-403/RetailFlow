import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../database/bill_dao.dart';
import '../database/product_dao.dart';
import '../models/bill_item_model.dart';
import '../models/bill_model.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';

/// Represents an item configuration for dynamic extra charges.
class ExtraChargeItem {
  final String title;
  final double amount;

  const ExtraChargeItem({required this.title, required this.amount});
}

/// Owns the active cart for the Billing screen: adding scanned
/// products, adjusting quantities, tracking extra charges and the
/// customer name, and finally persisting everything as a [Bill] +
/// [BillItem] rows when the cashier checks out.
class BillingProvider extends ChangeNotifier {
  final ProductDao _productDao = ProductDao();
  final BillDao _billDao = BillDao();

  final List<CartItem> _cartItems = [];
  String _customerName = '';
  
  // Kept single _extraCharges for backward compatibility
  double _extraCharges = 0.0; 
  final List<ExtraChargeItem> _additionalChargesList = []; // New tracker for multiple extra charges
  
  String _productDescription = '';
  double _paidAmount = 0.0;
  bool _isProcessing = false;
  String? _errorMessage;

  List<CartItem> get cartItems => List.unmodifiable(_cartItems);
  String get customerName => _customerName;
  double get extraCharges => _extraCharges;
  List<ExtraChargeItem> get additionalChargesList => List.unmodifiable(_additionalChargesList);
  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;
  bool get isCartEmpty => _cartItems.isEmpty;

  double get subtotal =>
      _cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);

  // Grand total aggregates the subtotal and all multi-charges
  double get grandTotal => subtotal + totalExtraCharges;

  // Calculates sum of all dynamic additional charges
  double get totalExtraCharges => 
      _additionalChargesList.fold(0.0, (sum, item) => sum + item.amount);

  double get totalItemCount =>
      _cartItems.fold(0.0, (sum, item) => sum + item.quantity);
  String get productDescription => _productDescription;
  double get paidAmount => _paidAmount;
  
  double get returnAmount =>
    (_paidAmount - grandTotal) < 0
        ? 0
        : (_paidAmount - grandTotal);

  void setCustomerName(String name) {
    _customerName = name;
    notifyListeners();
  }

  /// Kept for single legacy fallback support
  void setExtraCharges(double amount) {
    _extraCharges = amount < 0 ? 0 : amount;
    notifyListeners();
  }

  /// Adds a new dynamic additional charge line item
  void addAdditionalCharge(String title, double amount) {
    if (amount > 0 && title.trim().isNotEmpty) {
      _additionalChargesList.add(ExtraChargeItem(title: title.trim(), amount: amount));
      _extraCharges = totalExtraCharges; // Synced with legacy fallback
      notifyListeners();
    }
  }

  /// Removes an additional charge from the list
  void removeAdditionalCharge(int index) {
    if (index >= 0 && index < _additionalChargesList.length) {
      _additionalChargesList.removeAt(index);
      _extraCharges = totalExtraCharges; // Synced with legacy fallback
      notifyListeners();
    }
  }

  void setProductDescription(String description) {
    _productDescription = description;
    notifyListeners();
  }

  void setPaidAmount(double amount) {
    _paidAmount = amount < 0 ? 0 : amount;
    notifyListeners();
  }

  /// Looks up [barcode] in the products table.
  Future<ScanResult> handleScannedBarcode(String barcode) async {
    try {
      final product = await _productDao.getProductByBarcode(barcode);
      if (product == null) {
        return ScanResult.notFound;
      }
      addProductToCart(product);
      return ScanResult.added;
    } catch (e) {
      _errorMessage = 'Lookup failed: ${e.toString()}';
      notifyListeners();
      return ScanResult.error;
    }
  }

  void addProductToCart(Product product) {
    // Regular items matched via database unique ID and exclude manual tags
    final index = _cartItems.indexWhere((c) => c.product.id == product.id && c.product.barcode != 'MANUAL');
    if (index >= 0) {
      _cartItems[index].increment();
    } else {
      _cartItems.add(CartItem(product: product));
    }
    notifyListeners();
  }

  /// Injects a completely custom manual item line seamlessly
  void addManualProductToCart({
    required String name,
    required double price,
    required double quantity,
    required String unit,
  }) {
    if (name.trim().isEmpty || price <= 0 || quantity <= 0) return;

    // Generated virtual unique isolation id for manual entries
    final int temporaryManualId = -1 * DateTime.now().millisecondsSinceEpoch;

    final manualProduct = Product(
      id: temporaryManualId,
      barcode: 'MANUAL_$unit',
      name: name.trim(),
      price: price,
      createdAt: DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
    );

    final item = CartItem(product: manualProduct, quantity: quantity);
    _cartItems.add(item);
    notifyListeners();
  }

  void incrementQuantity(int productId) {
    final index = _cartItems.indexWhere((c) => c.product.id == productId);
    if (index >= 0) {
      _cartItems[index].increment();
      notifyListeners();
    }
  }

  void decrementQuantity(int productId) {
    final index = _cartItems.indexWhere((c) => c.product.id == productId);
    if (index >= 0) {
      final shouldRemove = _cartItems[index].decrement();
      if (shouldRemove) {
        _cartItems.removeAt(index);
      }
      notifyListeners();
    }
  }

  void removeItem(int productId) {
    _cartItems.removeWhere((c) => c.product.id == productId);
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    _customerName = '';
    _extraCharges = 0.0;
    _additionalChargesList.clear();
    _productDescription = '';
    _paidAmount = 0.0;
    notifyListeners();
  }

  /// Persists the cart as a Bill + BillItems.
  Future<int?> checkout() async {
    if (_cartItems.isEmpty) {
      _errorMessage = 'Cart is empty.';
      notifyListeners();
      return null;
    }

    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final bill = Bill(
        customerName: _customerName.trim().isEmpty
            ? 'Walk-in Customer'
            : _customerName.trim(),
        date: DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
        subtotal: subtotal,
        extraCharges: totalExtraCharges,
        grandTotal: grandTotal,
        productDescription: _productDescription,
        paidAmount: _paidAmount,
        returnAmount: returnAmount,
      );

      final items = _cartItems.map((c) {
        // Check karein ke kya barcode 'MANUAL' se start ho raha hai
        final bool isItemManual = c.product.barcode.startsWith('MANUAL');
        
        // ✅ FIXED: Scanned products ke liye dynamic units hamesha blank ('') rakhein
        String extractedUnit = ''; 
        
        if (isItemManual) {
          // Only extract and apply formatting if the product was explicitly added via Manual panel
          if (c.product.barcode.contains('_')) {
            extractedUnit = c.product.barcode.split('_').last; // E.g. 'kg', 'grams'
          } else {
            extractedUnit = 'pcs'; // Manual safe fallback
          }
        }

        return BillItem(
          billId: 0, 
          productId: isItemManual ? null : c.product.id, 
          productName: c.product.name,
          quantity: c.quantity,
          unitPrice: c.product.price,
          totalPrice: c.totalPrice,
          unit: extractedUnit, 
        );
      }).toList();

      // FIXED: Used named parameters to avoid "Too many positional arguments" crash
      final billId = await _billDao.createBillWithItems(bill: bill, items: items);
      
      _isProcessing = false;
      notifyListeners();
      return billId;
    } catch (e) {
      _errorMessage = 'Checkout failed: ${e.toString()}';
      _isProcessing = false;
      notifyListeners();
      return null;
    }
  }
}

enum ScanResult { added, notFound, error }